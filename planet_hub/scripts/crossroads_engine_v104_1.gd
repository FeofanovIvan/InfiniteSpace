extends RefCounted
## v120: content-only dialogue adapter for the EXISTING TranslatorTablet.
## No screen, button, keyboard, speaker, animation or scene implementation here.
const MATCHER = preload("res://planet_hub/scripts/dialogue_input_matcher.gd")
const LANGUAGES: Array[String] = ["ru", "en", "fr", "de", "es", "pt_BR"]
const DATA_BASE: String = "res://planet_hub/data/crossroads_v120_"
const SAVE_PATH: String = "user://mika_crossroads_v120_progress.json"
const MAX_VISITS: int = 99

const ACTION_TEXT: Dictionary = {
	"ru": {"why":"Почему?", "how":"Как это работает?", "more":"Расскажи ещё!", "repeat":"Повтори, пожалуйста", "invest":"Подумаем вместе", "skip":"Вернуться к вопросам", "next":"Следующее открытие: %s", "finish":"Завершить маршрут", "related":"Дальше: %s", "topic":"Другой вопрос", "resume":"Продолжить маршрут", "route_prefix":"Маршрут: ", "unclear":"Я не уверена, что правильно поняла вопрос. Выбери вариант или назови тему.", "no_more":"Мы уже рассмотрели все три ответа этой темы. Можешь выбрать другую тему.", "route_done":"Мы завершили маршрут «%s»! Можно выбрать новый или другую тему."},
	"en": {"why":"Why?", "how":"How does it work?", "more":"Tell me more!", "repeat":"Repeat, please", "invest":"Let's think together", "skip":"Back to questions", "next":"Next discovery: %s", "finish":"Finish this route", "related":"Next: %s", "topic":"Another question", "resume":"Resume the route", "route_prefix":"Route: ", "unclear":"I'm not sure I understood. Choose a question or name a topic.", "no_more":"We've looked at all three answers. You can choose another topic.", "route_done":"We finished the route “%s”! Choose a new one or another topic."},
	"fr": {"why":"Pourquoi ?", "how":"Comment ça marche ?", "more":"Raconte encore !", "repeat":"Répète, s'il te plaît", "invest":"Réfléchissons ensemble", "skip":"Retour aux questions", "next":"Prochaine découverte : %s", "finish":"Terminer ce parcours", "related":"Ensuite : %s", "topic":"Autre question", "resume":"Reprendre le parcours", "route_prefix":"Parcours : ", "unclear":"Je ne suis pas sûre d'avoir compris. Choisis une question ou nomme un sujet.", "no_more":"Nous avons vu les trois réponses. Choisis un autre sujet.", "route_done":"Nous avons terminé le parcours « %s » ! Choisis-en un autre."},
	"de": {"why":"Warum?", "how":"Wie funktioniert das?", "more":"Erzähl mir mehr!", "repeat":"Bitte wiederhole das", "invest":"Lass uns nachdenken", "skip":"Zurück zu den Fragen", "next":"Nächste Entdeckung: %s", "finish":"Reise abschließen", "related":"Weiter: %s", "topic":"Eine andere Frage", "resume":"Reise fortsetzen", "route_prefix":"Reise: ", "unclear":"Ich bin nicht sicher, ob ich die Frage verstanden habe. Wähle eine Frage oder ein Thema.", "no_more":"Wir haben alle drei Antworten betrachtet. Wähle ein anderes Thema.", "route_done":"Wir haben die Reise „%s“ beendet! Wähle eine neue Reise."},
	"es": {"why":"¿Por qué?", "how":"¿Cómo funciona?", "more":"¡Cuéntame más!", "repeat":"Repite, por favor", "invest":"Pensemos juntos", "skip":"Volver a las preguntas", "next":"Siguiente descubrimiento: %s", "finish":"Terminar la ruta", "related":"Después: %s", "topic":"Otra pregunta", "resume":"Continuar la ruta", "route_prefix":"Ruta: ", "unclear":"No estoy segura de haber entendido. Elige una pregunta o di un tema.", "no_more":"Ya vimos las tres respuestas. Puedes elegir otro tema.", "route_done":"¡Terminamos la ruta «%s»! Elige otra ruta u otro tema."},
	"pt_BR": {"why":"Por quê?", "how":"Como funciona?", "more":"Conte mais!", "repeat":"Repita, por favor", "invest":"Vamos pensar juntos", "skip":"Voltar às perguntas", "next":"Próxima descoberta: %s", "finish":"Concluir o percurso", "related":"Depois: %s", "topic":"Outra pergunta", "resume":"Retomar o percurso", "route_prefix":"Percurso: ", "unclear":"Não tenho certeza se entendi. Escolha uma pergunta ou diga um tema.", "no_more":"Já vimos as três respostas. Você pode escolher outro tema.", "route_done":"Concluímos o percurso “%s”! Escolha outro ou mude de tema."}
}

var _library: Dictionary = {}
var _living: Dictionary = {}
var _deep: Dictionary = {}
var _investigations: Dictionary = {}
var _knowledge: Dictionary = {}
var _learning: Dictionary = {}
var _routes: Dictionary = {}
var _topic: Dictionary = {}
var _topic_id: String = ""
var _locale: String = "en"
var _mode: String = "questions" # questions, followups, prediction
var _last_answer: String = ""
var _last_question_index: int = -1
var _link_cursor: int = 0
var _asked_indices: Array[int] = []
var _route_id: String = ""
var _route_index: int = 0
var _route_enabled: bool = false
var _progress: Dictionary = {}
var _depth: String = "starter"
var _progress_persistence_enabled: bool = true

func disable_progress_io_for_tests() -> void:
	# Existing game data must not be read or overwritten by smoke tests.
	_progress_persistence_enabled = false
	_progress = {"schema": 1, "routes": {}, "visits": {}}

func _load_json(filename: String) -> Dictionary:
	var path: String = DATA_BASE + filename + ".json"
	if not FileAccess.file_exists(path):
		push_warning("Crossroads v120 content missing: " + path)
		return {}
	var value: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	return value if value is Dictionary else {}

func configure(encyclopedia: Dictionary) -> void:
	_library = encyclopedia
	_living = _load_json("living_dialogue")
	_deep = _load_json("deep_dialogue")
	_investigations = _load_json("investigations")
	_knowledge = _load_json("knowledge_links")
	_learning = _load_json("learning")
	_routes = _load_json("routes")
	_read_progress()
	_load_route_for_locale()

func _text(key: String) -> String:
	var choices: Dictionary = ACTION_TEXT.get(_locale, ACTION_TEXT["en"])
	return str(choices.get(key, ""))

func _localized(value: Variant) -> String:
	if value is Dictionary:
		return str(value.get(_locale, value.get("en", "")))
	return str(value)

func _find_topic(id: String) -> Dictionary:
	for item in _library.get("topics", []):
		if item is Dictionary and str(item.get("id", "")) == id:
			return item
	return {}

func _pick_topic(topic_id: String) -> void:
	_topic = _find_topic(topic_id)
	if _topic.is_empty():
		return
	_topic_id = topic_id
	_mode = "questions"
	_last_answer = ""
	_last_question_index = -1
	_link_cursor = 0
	_asked_indices.clear()
	_mark_visit()

func set_topic(topic_id: String) -> void:
	# Selecting a normal article only PAUSES a route; the saved route is not lost.
	_route_enabled = false
	_pick_topic(topic_id)

func get_topic_id() -> String:
	return _topic_id

func get_group_id() -> String:
	return str(_topic.get("group", ""))

func set_locale(value: String) -> void:
	var target: String = value if LANGUAGES.has(value) else "en"
	var changed: bool = _locale != target
	_locale = target
	if changed:
		_depth = "starter"
		_load_route_for_locale()

func _topic_questions(lang: String) -> Array:
	var by_language: Dictionary = _topic.get("questions", {})
	return by_language.get(lang, by_language.get("en", []))

func _topic_answers(lang: String) -> Array:
	var by_language: Dictionary = _topic.get("answers", {})
	return by_language.get(lang, by_language.get("en", []))

func _route_record() -> Dictionary:
	return _routes.get("routes", {}).get(_route_id, {})

func _route_topics() -> Array:
	return _route_record().get("topic_ids", [])

func _next_route_topic() -> String:
	var steps: Array = _route_topics()
	return str(steps[_route_index + 1]) if _route_index + 1 < steps.size() else ""

func _first_related() -> String:
	var valid: Array[String] = []
	for edge in _knowledge.get("links", {}).get(_topic_id, []):
		var target: String = str(edge.get("to", ""))
		if target != _topic_id and not _find_topic(target).is_empty():
			valid.append(target)
	if valid.is_empty():
		return ""
	# A topic may link to many approved subjects. Rotate its suggestion after
	# each answer without adding extra buttons or showing all at once.
	return valid[_link_cursor % valid.size()]

func _title_for(topic_id: String) -> String:
	return _localized(_find_topic(topic_id).get("title", {}))

func _followup_options() -> Array:
	var third: String = _text("topic")
	if _route_enabled and not _route_id.is_empty():
		var next_id: String = _next_route_topic()
		third = _text("next") % _title_for(next_id) if not next_id.is_empty() else _text("finish")
	else:
		var related: String = _first_related()
		if not related.is_empty():
			third = _text("related") % _title_for(related)
	var routed: Dictionary = _deep.get("routing_by_topic", {}).get(_topic_id, {})
	var second: String = _text("repeat")
	if _investigations.get("experiments", {}).has(_topic_id):
		second = _text("invest")
	elif not routed.get("why", []).is_empty():
		second = _text("why")
	elif not routed.get("how", []).is_empty():
		second = _text("how")
	return [_text("more"), second, third]

func get_choices() -> Array:
	if _mode == "prediction":
		var study: Dictionary = _investigations.get("experiments", {}).get(_topic_id, {})
		var variants: Array = study.get("predictions", {}).get(_locale, study.get("predictions", {}).get("en", []))
		if variants.size() >= 2:
			return [str(variants[0]), str(variants[1]), _text("skip")]
	if _mode == "followups":
		return _followup_options()
	return _topic_questions(_locale).duplicate()

func get_hint(index: int) -> String:
	var choices: Array = get_choices()
	return str(choices[index]) if index >= 0 and index < choices.size() else ""

func _determine_depth(store: Node) -> void:
	_depth = "starter"
	var age: int = -1
	if store != null and store.has_method("get_answer"):
		var raw: String = str(store.call("get_answer", "age"))
		if raw.is_valid_int():
			age = int(raw)
	var visits: int = int(_progress.get("visits", {}).get(_locale, {}).size())
	var rules: Dictionary = _learning.get("policy", {})
	if age >= int(rules.get("explorer_min_age", 9)) and visits >= int(rules.get("explorer_min_distinct_visits", 4)):
		_depth = "explorer"
	elif age >= int(rules.get("curious_min_age", 6)) and visits >= int(rules.get("curious_min_distinct_visits", 2)):
		_depth = "curious"

func begin(_world_id: String, language: String, profile_store: Node) -> Dictionary:
	set_locale(language)
	_determine_depth(profile_store)
	# Beginning a conversation does not select an unrelated first topic.
	var introduction: String = _localized(_topic.get("title", {}))
	if _route_enabled and not _route_id.is_empty():
		var route: Dictionary = _route_record()
		introduction = _localized(route.get("title", {})) + ": " + introduction
	else:
		for group_entry in _library.get("groups", []):
			if group_entry is Dictionary and str(group_entry.get("id", "")) == get_group_id():
				introduction = _localized(group_entry.get("prompt", {}))
				break
	return {"available": not _topic.is_empty(), "npc": introduction, "choices": get_choices()}

func _find_question(typed: String) -> int:
	for lang in _search_languages():
		var options: Array = _topic_questions(lang)
		for i in range(options.size()):
			if MATCHER.score(typed, str(options[i])) != MATCHER.NO_MATCH:
				return i
	return -1

func _search_languages() -> Array[String]:
	var languages: Array[String] = [_locale]
	for lang in LANGUAGES:
		if lang != _locale:
			languages.append(lang)
	return languages

func _matches(typed: String, variants: Array) -> bool:
	for phrase in variants:
		if MATCHER.score(typed, str(phrase)) != MATCHER.NO_MATCH:
			return true
	return false

func _action_matches(typed: String, action: String) -> bool:
	for lang in _search_languages():
		var options: Dictionary = ACTION_TEXT.get(lang, {})
		if MATCHER.score(typed, str(options.get(action, ""))) != MATCHER.NO_MATCH:
			return true
	return false

func _finish_response(message: String) -> Dictionary:
	return {"accepted": true, "npc": message, "choices": get_choices()}

func _answer_for(index: int) -> Dictionary:
	var answers: Array = _topic_answers(_locale)
	if index < 0 or index >= answers.size():
		return {"accepted": false, "npc": _text("unclear")}
	_last_answer = str(answers[index])
	_last_question_index = index
	_link_cursor += 1
	if not _asked_indices.has(index):
		_asked_indices.append(index)
	_mode = "followups"
	_save_progress()
	return _finish_response(_last_answer)

func _next_unasked() -> int:
	var options: Array = _topic_questions(_locale)
	# Three age/visit-driven exploration orders; science text stays reviewed.
	if _depth == "curious":
		var guide: Dictionary = _learning.get("topic_guides", {}).get(_topic_id, {})
		var approved: int = int(guide.get("approved_question_index", -1))
		if approved >= 0 and approved < options.size() and not _asked_indices.has(approved):
			return approved
	elif _depth == "explorer":
		for reverse_index in range(options.size() - 1, -1, -1):
			if not _asked_indices.has(reverse_index):
				return reverse_index
	for i in range(options.size()):
		if not _asked_indices.has(i):
			return i
	return -1

func _deep_answer_index(typed: String) -> int:
	var routed: Dictionary = _deep.get("routing_by_topic", {}).get(_topic_id, {})
	var all_followups: Dictionary = _deep.get("followups", {})
	for lang in _search_languages():
		var lang_followups: Dictionary = all_followups.get(lang, {})
		for kind in ["why", "how", "where", "what_if", "more", "repeat"]:
			if _matches(typed, lang_followups.get(kind, [])):
				if kind == "repeat":
					return -2
				if kind == "more":
					return -3
				var indices: Array = routed.get(kind, [])
				for index in indices:
					if int(index) != _last_question_index:
						return int(index)
				if not indices.is_empty():
					return int(indices[0])
				return -4
	return -1

func _self_answer(typed: String) -> String:
	var self_dialogue: Dictionary = _living.get("self_dialogue", {})
	for lang in _search_languages():
		var bank: Dictionary = self_dialogue.get(lang, {})
		var qs: Array = bank.get("questions", [])
		for i in range(qs.size()):
			if MATCHER.score(typed, str(qs[i])) != MATCHER.NO_MATCH:
				var responses: Array = self_dialogue.get(_locale, self_dialogue.get("en", {})).get("answers", [])
				return str(responses[i]) if i < responses.size() else ""
	return ""

func _choose_topic_by_alias(typed: String) -> String:
	# Only exact known topics/aliases; no speculative fact generation.
	var actual: String = MATCHER.normalize(typed)
	for topic in _library.get("topics", []):
		for lang in _search_languages():
			var title: String = MATCHER.normalize(str(topic.get("title", {}).get(lang, "")))
			if title.length() >= 3 and (actual == title or actual == "what is " + title or actual == "что такое " + title or actual == "расскажи про " + title):
				return str(topic.get("id", ""))
	# Conservative: aliases match exactly or after simple known question stems.
	for topic_id in _living.get("topic_aliases", {}):
		var alias_bank: Dictionary = _living.get("topic_aliases", {}).get(topic_id, {})
		for lang in _search_languages():
			for alias in alias_bank.get(lang, []):
				var candidate: String = MATCHER.normalize(str(alias))
				if candidate.length() >= 3 and (actual == candidate or actual == "what is " + candidate or actual == "что такое " + candidate or actual == "расскажи про " + candidate):
					if not _find_topic(str(topic_id)).is_empty():
						return str(topic_id)
	return ""

func _prediction_response(typed: String) -> Dictionary:
	if _action_matches(typed, "skip"):
		_mode = "questions"
		return _finish_response(_localized(_investigations.get("ui", {}).get(_locale, {}).get("skipped", {})))
	var study: Dictionary = _investigations.get("experiments", {}).get(_topic_id, {})
	if _find_question(typed) >= 0:
		var hold_ui: Dictionary = _investigations.get("ui", {}).get(_locale, {})
		return {"accepted": false, "npc": str(hold_ui.get("question_hold", _text("unclear"))), "choices": get_choices()}
	var correct: int = int(study.get("aligned_prediction_index", -1))
	var prediction_index: int = -1
	for lang in _search_languages():
		var choices: Array = study.get("predictions", {}).get(lang, [])
		for i in range(choices.size()):
			if MATCHER.score(typed, str(choices[i])) != MATCHER.NO_MATCH:
				prediction_index = i
				break
		if prediction_index >= 0:
			break
	var info: Dictionary = _investigations.get("ui", {}).get(_locale, _investigations.get("ui", {}).get("en", {}))
	var feedback: String = str(info.get("free", "Thanks for your idea!"))
	if prediction_index >= 0:
		feedback = str(info.get("aligned", "")) if prediction_index == correct else str(info.get("other", ""))
	var index: int = int(study.get("source_answer_index", 0))
	var answers: Array = _topic_answers(_locale)
	var reference: String = str(answers[index]) if index >= 0 and index < answers.size() else ""
	_mode = "followups"
	_last_answer = reference
	_last_question_index = index
	if not _asked_indices.has(index):
		_asked_indices.append(index)
	return _finish_response(feedback + " " + str(info.get("fact", "")) + " " + reference + " " + str(info.get("finish", "")))

func _go_to_topic(id: String) -> Dictionary:
	_route_enabled = false
	_pick_topic(id)
	return _finish_response(_localized(_topic.get("title", {})) + " — " + str(_topic_answers(_locale)[0]) if not _topic_answers(_locale).is_empty() else _localized(_topic.get("title", {})))

func _advance_route() -> Dictionary:
	var steps: Array = _route_topics()
	if _route_index + 1 < steps.size():
		_route_index += 1
		_pick_topic(str(steps[_route_index]))
		_save_progress()
		return _finish_response((_text("next") % _localized(_topic.get("title", {}))) + ". " + str(_topic_answers(_locale)[0]) if not _topic_answers(_locale).is_empty() else _localized(_topic.get("title", {})))
	var route_title: String = _localized(_route_record().get("title", {}))
	_route_enabled = false
	_route_id = ""
	_route_index = 0
	var routes_saved: Dictionary = _progress.get("routes", {})
	routes_saved.erase(_locale)
	_progress["routes"] = routes_saved
	_save_progress()
	_mode = "questions"
	return _finish_response(_text("route_done") % route_title)

func accept(typed: String) -> Dictionary:
	if _topic.is_empty() or typed.strip_edges().is_empty():
		return {"accepted": false, "npc": _text("unclear")}
	if _mode == "prediction":
		return _prediction_response(typed)
	# The existing tablet passes typed text; no raw child message is saved.
	var own: String = _self_answer(typed)
	if not own.is_empty():
		return _finish_response(own)
	# Explicit already-approved question variants work in every state/language.
	var index: int = _find_question(typed)
	if index >= 0:
		return _answer_for(index)
	if _mode == "followups":
		if _route_enabled and (_action_matches(typed, "finish") or _matches_next_route(typed)):
			return _advance_route()
		if _action_matches(typed, "invest"):
			var study: Dictionary = _investigations.get("experiments", {}).get(_topic_id, {})
			if not study.is_empty():
				_mode = "prediction"
				var ui: Dictionary = _investigations.get("ui", {}).get(_locale, {})
				return _finish_response(str(ui.get("intro", "")) + " " + _localized(study.get("prompt", {})))
		if _action_matches(typed, "more"):
			var next_index: int = _next_unasked()
			return _answer_for(next_index) if next_index >= 0 else _finish_response(_text("no_more"))
		if _action_matches(typed, "repeat"):
			_link_cursor += 1
			return _finish_response(_last_answer)
		if _action_matches(typed, "topic"):
			_mode = "questions"
			return _finish_response(_localized(_topic.get("title", {})))
		var related: String = _first_related()
		if not related.is_empty() and _matches_related(typed, related):
			return _go_to_topic(related)
		var deep_index: int = _deep_answer_index(typed)
		if deep_index == -2:
			_link_cursor += 1
			return _finish_response(_last_answer)
		if deep_index == -3:
			var unasked: int = _next_unasked()
			return _answer_for(unasked) if unasked >= 0 else _finish_response(_text("no_more"))
		if deep_index >= 0:
			return _answer_for(deep_index)
		if deep_index == -4:
			return _finish_response(_text("no_more"))
	var alias: String = _choose_topic_by_alias(typed)
	if not alias.is_empty():
		return _go_to_topic(alias)
	return {"accepted": false, "npc": _text("unclear"), "choices": get_choices()}

func _matches_next_route(typed: String) -> bool:
	var next_id: String = _next_route_topic()
	if next_id.is_empty():
		return false
	for lang in _search_languages():
		var v: String = str(ACTION_TEXT.get(lang, {}).get("next", "")) % _local_title(next_id, lang)
		if MATCHER.score(typed, v) != MATCHER.NO_MATCH:
			return true
	return false

func _local_title(id: String, lang: String) -> String:
	var v: Variant = _find_topic(id).get("title", {})
	return str(v.get(lang, v.get("en", ""))) if v is Dictionary else str(v)

func _matches_related(typed: String, id: String) -> bool:
	for lang in _search_languages():
		var v: String = str(ACTION_TEXT.get(lang, {}).get("related", "")) % _local_title(id, lang)
		if MATCHER.score(typed, v) != MATCHER.NO_MATCH:
			return true
	return false

func get_route_ids_for_group(group_id: String) -> Array:
	var result: Array = []
	for id in _routes.get("order", []):
		var route: Dictionary = _routes.get("routes", {}).get(str(id), {})
		var ids: Array = route.get("topic_ids", [])
		if not ids.is_empty() and str(_find_topic(str(ids[0])).get("group", "")) == group_id:
			result.append(str(id))
	return result

func get_route_label(id: String) -> String:
	return _text("route_prefix") + _localized(_routes.get("routes", {}).get(id, {}).get("title", {}))

func start_route(id: String) -> bool:
	var route: Dictionary = _routes.get("routes", {}).get(id, {})
	var ids: Array = route.get("topic_ids", [])
	if ids.is_empty() or _find_topic(str(ids[0])).is_empty():
		return false
	_route_id = id
	_route_index = 0
	_route_enabled = true
	_pick_topic(str(ids[0]))
	_save_progress()
	return true

func get_resume_label() -> String:
	return _text("resume") if not _route_id.is_empty() and _route_index < _route_topics().size() else ""

func resume_route() -> bool:
	if _route_id.is_empty():
		return false
	var ids: Array = _route_topics()
	if _route_index >= ids.size() or ids.is_empty():
		return false
	_route_enabled = true
	_pick_topic(str(ids[_route_index]))
	_save_progress()
	return true

func _read_progress() -> void:
	if not _progress_persistence_enabled:
		_progress = {"schema": 1, "routes": {}, "visits": {}}
		return
	if FileAccess.file_exists(SAVE_PATH):
		var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(SAVE_PATH))
		if parsed is Dictionary and int(parsed.get("schema", 0)) == 1:
			_progress = parsed
	if _progress.is_empty():
		_progress = {"schema": 1, "routes": {}, "visits": {}}

func _load_route_for_locale() -> void:
	var route: Dictionary = _progress.get("routes", {}).get(_locale, {})
	var id: String = str(route.get("id", ""))
	_route_id = id if _routes.get("routes", {}).has(id) else ""
	_route_index = maxi(0, int(route.get("index", 0)))
	_route_enabled = false

func _mark_visit() -> void:
	if _topic_id.is_empty():
		return
	var all: Dictionary = _progress.get("visits", {})
	var visited: Dictionary = all.get(_locale, {})
	visited[_topic_id] = mini(MAX_VISITS, int(visited.get(_topic_id, 0)) + 1)
	all[_locale] = visited
	_progress["visits"] = all
	_save_progress()

func _save_progress() -> void:
	if not _progress_persistence_enabled:
		return
	var routes: Dictionary = _progress.get("routes", {})
	if not _route_id.is_empty():
		routes[_locale] = {"id": _route_id, "index": _route_index}
	_progress["routes"] = routes
	var file: FileAccess = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file != null:
		file.store_string(JSON.stringify(_progress))
		file.close()
