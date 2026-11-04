extends RefCounted
const InputMatcher = preload("res://planet_hub/scripts/dialogue_input_matcher.gd")
## v93: deterministic, offline, world-aware, child-friendly conversation engine.
## Only the SELECTED choice guides typing; validation accepts all matching intents.
## No onboarding form, no fabricated age/name/color. Stored locally on device.

const WORLDS_PATH := "res://planet_hub/data/dialogue_worlds.json"
const PHRASES_PATH := "res://planet_hub/data/dialogue_phrases.json"
const STORIES_PATH := "res://planet_hub/data/dialogue_story_scenes.json"
const STORY_QUIZZES_PATH := "res://planet_hub/data/dialogue_story_quizzes.json"
const ROSTER_PATH := "res://planet_hub/data/representatives.json"
const SAVE_PATH := "user://miko_dialogue_progress.json"
const TOPIC_ORDER := ["self", "world", "race", "race_about", "origin", "ability", "work", "energy", "age", "learn"]
const MATH_CHALLENGES := [[1, 2], [2, 3], [3, 1], [4, 2], [5, 1], [3, 3], [2, 5], [4, 4]]

var language: String = "ru"
var place_id: String = ""
var stage: String = "greeting"
var choices: Array[String] = []
var _world: Dictionary = {}
var _race: Dictionary = {}
var _words: Dictionary = {}
var _roster: Dictionary = {}
var _ages: Dictionary = {}
var _state: Dictionary = {}
var _visited: Dictionary = {}
var _profile: Node
var _topic_count: int = 0
var _pending_personal: String = ""
var _current_math_topic: String = ""
var _math_a: int = 1
var _math_b: int = 2
var _enabled: bool = false
var _stories: Dictionary = {}
var _story: Dictionary = {}
var _story_quizzes: Dictionary = {}
var _story_opened_this_visit: bool = false

func _read(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {}
	var data: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	return data if data is Dictionary else {}

func _save() -> void:
	var file: FileAccess = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file != null:
		file.store_string(JSON.stringify(_state, "  "))
		file.close()

func _localized(value: Variant) -> String:
	if value is Dictionary:
		return str(value.get(language, value.get("en", value.get("ru", ""))))
	return str(value)

func _ui(key: String) -> String:
	var translations: Dictionary = _words.get("ui", {})
	return str(translations.get(language, translations.get("en", {})).get(key, key))

func _options(kind: String) -> Array[String]:
	var collection: Dictionary = _words.get("personal", {})
	var entry: Dictionary = collection.get(kind, {})
	var raw: Array = entry.get(language, entry.get("en", []))
	var result: Array[String] = []
	for line in raw:
		result.append(str(line))
	return result

func _clean(value: String) -> String:
	return InputMatcher.normalize(value)

func _matches(text: String, candidates: Array) -> bool:
	return InputMatcher.matches(text, candidates)

func _profile_get(key: String) -> String:
	if _profile != null and _profile.has_method("get_answer"):
		return str(_profile.call("get_answer", key))
	return ""

func _profile_set(key: String, value: Variant) -> void:
	if _profile != null and _profile.has_method("remember_answer"):
		_profile.call("remember_answer", key, value)

func begin(target: String, locale: String, profile: Node = null) -> Dictionary:
	_profile = profile
	language = locale
	place_id = target
	_topic_count = 0
	_pending_personal = ""
	_current_math_topic = ""
	_story_opened_this_visit = false
	stage = "greeting"
	choices.clear()
	var world_database: Dictionary = _read(WORLDS_PATH)
	_words = _read(PHRASES_PATH)
	_stories = _read(STORIES_PATH)
	_story = _stories.get("scenes", {}).get(target, {})
	_story_quizzes = _read(STORY_QUIZZES_PATH)
	_roster = _read(ROSTER_PATH).get("assignments", {})
	_ages = world_database.get("character_ages", {})
	_world = world_database.get("worlds", {}).get(target, {})
	_enabled = not _world.is_empty() and bool(_world.get("inhabited", false))
	if not _enabled:
		return {"accepted": false, "npc": "", "choices": [], "available": false}
	var race_id: String = str(_world.get("race", ""))
	_race = world_database.get("races", {}).get(race_id, {})
	_state = _read(SAVE_PATH)
	if not _state.has("locations"):
		_state["locations"] = {}
	if not _state.has("personal_asked"):
		_state["personal_asked"] = []
	var places: Dictionary = _state["locations"]
	_visited = places.get(target, {"visits": 0, "seen": [], "response_counter": 0})
	_visited["visits"] = int(_visited.get("visits", 0)) + 1
	places[target] = _visited
	_state["locations"] = places
	_save()
	choices = _options("greeting")
	var hello: String = _ui("hello") + " " + _localized(_race.get("greeting", {}))
	var nickname: String = _profile_get("name")
	if int(_visited.get("visits", 0)) > 1 and not nickname.is_empty():
		hello += (" С возвращением, %s!" if language == "ru" else " Welcome back, %s!") % nickname
	return {"accepted": true, "npc": hello, "choices": choices.duplicate(), "available": true}

func get_choices() -> Array[String]:
	return choices.duplicate()

func get_hint(selected_index: int) -> String:
	if selected_index >= 0 and selected_index < choices.size():
		return choices[selected_index]
	return ""

func _topic_for(text: String) -> String:
	var topics: Dictionary = _words.get("topics", {})
	var winning_intent: String = ""
	var best_score: int = InputMatcher.NO_MATCH
	var ambiguous: bool = false
	for key in TOPIC_ORDER:
		var record: Dictionary = topics.get(key, {})
		var variants: Array = record.get(language, record.get("en", []))
		var english: Array = record.get("en", [])
		var station_variants: Array = _words.get("station_world", {}).get(language, []) if topic_is_station(key) else []
		var station_english: Array = _words.get("station_world", {}).get("en", []) if topic_is_station(key) else []
		var intent_score: int = InputMatcher.NO_MATCH
		for candidate in variants + english + station_variants + station_english:
			intent_score = mini(intent_score, InputMatcher.score(text, str(candidate)))
		if intent_score >= InputMatcher.NO_MATCH:
			continue
		if intent_score < best_score:
			winning_intent = key
			best_score = intent_score
			ambiguous = false
		elif intent_score == best_score and key != winning_intent:
			# Two similar topics: don't guess which question the child meant.
			ambiguous = true
	return "" if ambiguous else winning_intent

func topic_is_station(key: String) -> bool:
	return key == "world" and bool(_world.get("is_station", false))

func _topic_options() -> Array[String]:
	var topics: Dictionary = _words.get("topics", {})
	var seen: Array = _visited.get("seen", [])
	var ordered: Array = []
	for topic in TOPIC_ORDER:
		if not seen.has(topic):
			ordered.append(topic)
	for topic in TOPIC_ORDER:
		if seen.has(topic):
			ordered.append(topic)
	var selected: Array[String] = []
	for topic in ordered:
		if selected.size() >= 3:
			break
		var record: Dictionary = topics.get(topic, {})
		var variants: Array = record.get(language, record.get("en", []))
		if topic_is_station(topic):
			variants = _words.get("station_world", {}).get(language, _words.get("station_world", {}).get("en", variants))
		if variants.size() > 0:
			var age_text: String = _profile_get("age")
			var young: bool = age_text.is_valid_int() and int(age_text) <= 6
			var variant_index: int = 0 if young else (int(_visited.get("response_counter", 0)) + selected.size()) % variants.size()
			selected.append(str(variants[variant_index]))
	return selected

func _choose_next() -> Dictionary:
	stage = "choose"
	choices = _topic_options()
	var message: String = _ui("choose") if _topic_count == 0 else _ui("thanks")
	var seen: Array = _visited.get("seen", [])
	if seen.size() >= TOPIC_ORDER.size():
		message = _ui("done") + " " + _ui("choose")
	return {"accepted": true, "npc": message, "choices": choices.duplicate(), "available": true}

func _quiz_for_race() -> Dictionary:
	var race_id: String = str(_world.get("race", ""))
	return _story_quizzes.get("quizzes", {}).get(race_id, {})

func _quiz_choices() -> Array[String]:
	var q: Dictionary = _quiz_for_race()
	var all_locales: Dictionary = q.get("options", {})
	var raw: Array = all_locales.get(language, all_locales.get("en", []))
	var result: Array[String] = []
	for option in raw:
		result.append(str(option))
	return result

func _quiz_choice_index(text: String) -> int:
	var translations: Dictionary = _quiz_for_race().get("options", {})
	var winning: int = -1
	var best: int = InputMatcher.NO_MATCH
	var tied: bool = false
	for lang in translations:
		var options: Array = translations[lang]
		for i in range(options.size()):
			var result: int = InputMatcher.score(text, str(options[i]))
			if result >= InputMatcher.NO_MATCH:
				continue
			if result < best:
				best = result
				winning = i
				tied = false
			elif result == best and winning != i:
				tied = true
	return -1 if tied else winning

func _begin_story_quiz(base_answer: String) -> Dictionary:
	var quiz: Dictionary = _quiz_for_race()
	var options: Array[String] = _quiz_choices()
	if quiz.is_empty() or options.size() != 3:
		var ordinary: Dictionary = _choose_next()
		ordinary["npc"] = base_answer + "\n\n" + str(ordinary.get("npc", ""))
		return ordinary
	stage = "story_quiz"
	choices = options
	var question: String = _localized(quiz.get("question", {}))
	return {"accepted": true, "available": true,
		"npc": base_answer + "\n\n" + question, "choices": choices.duplicate()}

func _accept_story_quiz(text: String) -> Dictionary:
	if _skip(text):
		var skipped: Dictionary = _choose_next()
		skipped["npc"] = _localized(_story_quizzes.get("feedback", {}).get("skip", {})) + "\n\n" + str(skipped.get("npc", ""))
		return skipped
	var chosen: int = _quiz_choice_index(text)
	if chosen < 0:
		var other: String = _topic_for(text)
		if not other.is_empty():
			stage = "choose"
			return accept(text)
		return {"accepted": false, "available": true, "npc": _ui("bad"), "choices": choices.duplicate()}
	var correct: int = int(_story_quizzes.get("correct_index", 0))
	if chosen != correct:
		return {"accepted": false, "available": true,
			"npc": _localized(_story_quizzes.get("feedback", {}).get("retry", {})),
			"choices": choices.duplicate()}
	_visited["quiz_success"] = int(_visited.get("quiz_success", 0)) + 1
	_store_location()
	var next: Dictionary = _choose_next()
	next["npc"] = _localized(_story_quizzes.get("feedback", {}).get("success", {})) + "\n\n" + str(next.get("npc", ""))
	return next

func _story_choices() -> Array[String]:
	var results: Array[String] = []
	var race_id: String = str(_world.get("race", ""))
	var translated: Dictionary = _stories.get("choices_by_race", {}).get(race_id, {})
	var raw: Array = translated.get(language, translated.get("en", []))
	for phrase in raw:
		results.append(str(phrase))
	return results

func _open_story_if_possible(topic: String, base_answer: String) -> Dictionary:
	if topic != "world" or _story.is_empty() or _story_opened_this_visit:
		return {}
	var new_choices: Array[String] = _story_choices()
	if new_choices.size() != 3:
		return {}
	_story_opened_this_visit = true
	stage = "story"
	choices = new_choices
	var intro: String = _localized(_story.get("hook", {}))
	var prior_stories: int = int(_visited.get("story_turns", 0))
	if prior_stories > 0:
		var revisit_line: Dictionary = {
			"ru": "Помнишь, мы уже рассматривали это место? Давай заметим что-нибудь ещё.",
			"en": "Remember looking at this place before? Let's notice something new.",
			"fr": "Tu te souviens de cet endroit ? Regardons encore.",
			"de": "Erinnerst du dich an diesen Ort? Sehen wir noch einmal hin.",
			"es": "¿Recuerdas este lugar? Observemos algo nuevo.",
			"pt_BR": "Lembra deste lugar? Vamos observar algo novo."
		}
		intro = _localized(revisit_line) + " " + intro
	return {"accepted": true, "available": true,
		"npc": base_answer + "\n\n" + intro,
		"choices": choices.duplicate()}

func _story_choice_index(text: String) -> int:
	var translated: Dictionary = _stories.get("choices_by_race", {}).get(str(_world.get("race", "")), {})
	var best: int = InputMatcher.NO_MATCH
	var result: int = -1
	var tied: bool = false
	# All known equivalent sentences, not only the highlighted hint, are valid.
	for lang in translated.keys():
		var variants: Array = translated[lang]
		for i in range(mini(3, variants.size())):
			var score: int = InputMatcher.score(text, str(variants[i]))
			if score >= InputMatcher.NO_MATCH:
				continue
			if score < best:
				best = score
				result = i
				tied = false
			elif score == best and i != result:
				tied = true
	return -1 if tied else result

func _accept_story(text: String) -> Dictionary:
	var index: int = _story_choice_index(text)
	if index < 0:
		# Story questions are optional. A new recognized general question
		# can take the place of a suggested follow-up, without dead-ending.
		var ordinary_topic: String = _topic_for(text)
		if not ordinary_topic.is_empty():
			stage = "choose"
			return accept(text)
		return {"accepted": false, "npc": _ui("bad"), "choices": choices.duplicate()}
	var responses: Array = _story.get("responses", [])
	if index >= responses.size():
		return {"accepted": false, "npc": _ui("bad"), "choices": choices.duplicate()}
	var answer: String = _localized(responses[index])
	var race_id: String = str(_world.get("race", ""))
	var reactions: Dictionary = _stories.get("reactions_by_race", {}).get(race_id, {})
	var variants: Array = reactions.get(language, reactions.get("en", []))
	if index < variants.size():
		answer = str(variants[index]) + " " + answer
	_visited["story_turns"] = int(_visited.get("story_turns", 0)) + 1
	_visited["story_last_choice"] = index
	_store_location()
	if index == 2:
		return _begin_story_quiz(answer)
	var next: Dictionary = _choose_next()
	next["npc"] = answer + "\n\n" + str(next.get("npc", ""))
	return next

func _race_fact(field: String) -> String:
	return str(_race.get(field + ("_ru" if language == "ru" else "_en"), ""))

func _name() -> String:
	var entry: Dictionary = _roster.get(place_id, {})
	return str(entry.get("name_ru", ""))

func _world_name() -> String:
	return _localized(_world.get("name", {}))

func _favorite_color_line(description: String) -> String:
	var color_id: String = _profile_get("favorite_color")
	if color_id.is_empty():
		return ""
	var patterns: Dictionary = {
		"red": ["крас", "багров", "ржав", "red", "crimson", "rust"],
		"blue": ["син", "голуб", "бирюз", "blue", "turquoise"],
		"green": ["зел", "green"],
		"yellow": ["жёл", "золот", "yellow", "golden"],
		"orange": ["оранж", "orange"],
		"purple": ["фиолет", "сирен", "purple", "violet", "lavender", "lilac"],
		"pink": ["розов", "pink"],
		"black": ["чёрн", "черн", "black"]
	}
	var mentioned: bool = false
	for pattern in patterns.get(color_id, []):
		if description.to_lower().contains(str(pattern)):
			mentioned = true
			break
	if not mentioned:
		return ""
	var label: String = color_id
	for entry in _words.get("colors", []):
		if str(entry.get("id", "")) == color_id:
			label = str(entry.get("labels", {}).get(language, entry.get("labels", {}).get("en", color_id)))
			break
	return ("Ты рассказывал, что любишь цвет «%s». Здесь тоже можно его увидеть!" if language == "ru" else "You told me you like %s. You can spot that color here too!") % label

func _response(topic: String) -> String:
	var ru: bool = language == "ru"
	var name: String = _name()
	var world: String = _world_name()
	var race_name: String = str(_race.get("ru" if ru else "en", ""))
	var description: String = _localized(_world.get("world", {}))
	var structure: String = _localized(_world.get("structure", {}))
	var variant: int = int(_visited.get("response_counter", 0)) % 3
	var answer: String = ""
	match topic:
		"self":
			var who: String = name if not name.is_empty() else ("представитель своей цивилизации" if ru else "a representative of my people")
			var clauses: Array = ([
				"Меня зовут %s. Сейчас мы находимся в мире %s." % [who, world],
				"Рад встрече! Я %s. Здесь, на %s, много интересного." % [who, world],
				"Ты встретил меня на %s. Можешь называть меня %s." % [world, who]
			] if ru else [
				"My name is %s. We are now at %s." % [who, world],
				"Glad to meet you! I am %s. There is much to discover at %s." % [who, world],
				"You met me at %s. You may call me %s." % [world, who]
			])
			answer = str(clauses[variant])
		"age":
			var character: Dictionary = _roster.get(place_id, {})
			var saved_age: Dictionary = _ages.get(str(character.get("asset", "")), {})
			var age_label: String = _localized(saved_age)
			if not age_label.is_empty():
				var age_patterns: Array = ([
					"Мне %s.", "Я прожил уже %s.", "Мой возраст — %s."
				] if ru else [
					"I am %s old.", "I have lived for %s.", "My age is %s."
				])
				# A fictional local-cycle age, not necessarily Earth years.
				answer = str(age_patterns[variant]) % age_label
			else:
				answer = "Мы измеряем возраст по-своему." if ru else "We measure age in our own way."
		"race":
			var race_patterns: Array = ([
				"Мой народ называется «%s».", "Мы называем себя «%s».", "Перед тобой представитель расы «%s»."
			] if ru else [
				"My species is called %s.", "We call ourselves %s.", "You are talking to a member of the %s species."
			])
			answer = str(race_patterns[variant]) % race_name
		"race_about":
			var race_intro: Array = ["", "Вот что я расскажу: ", "Наш народ необычен. "] if ru else ["", "Here is something to know: ", "Our people are unusual. "]
			answer = str(race_intro[variant]) + _race_fact("about")
		"origin":
			var origin_patterns: Array = ([
				"Сейчас мой дом здесь, на %s. Наш народ живёт в разных мирах.",
				"Я встретил тебя на %s. Но моя цивилизация исследует много планет.",
				"Сейчас мы на %s. Представители моей расы путешествуют между мирами."
			] if ru else [
				"My home is at %s for now. My people live across many worlds.",
				"You met me at %s, but my civilization explores many planets.",
				"We are at %s now. My species travels among worlds."
			])
			answer = str(origin_patterns[variant]) % world
		"world":
			answer = description
			if variant == 1 and not structure.is_empty():
				answer += " " + structure
			elif variant == 2:
				answer = (("Посмотри вокруг! " if ru else "Look around! ") + description)
			var color_comment: String = _favorite_color_line(description)
			if not color_comment.is_empty():
				answer += " " + color_comment
		"ability":
			var ability_intro: Array = ["", "Да, и это интересно: ", "Знаешь, что мы умеем? "] if ru else ["", "Here is something interesting: ", "Do you know what we can do? "]
			answer = str(ability_intro[variant]) + _race_fact("ability")
		"energy":
			var energy_intro: Array = ["", "У каждого вида свои потребности. ", "Мы совсем не обязаны питаться одинаково. "] if ru else ["", "Each species has different needs. ", "Not all life eats in the same way. "]
			answer = str(energy_intro[variant]) + _race_fact("energy")
		"work":
			answer = structure if not structure.is_empty() else description
			if variant == 1:
				answer = ("Здесь есть что исследовать. " if ru else "There is much to explore here. ") + answer
			elif variant == 2:
				answer = ("Посмотри на это место: " if ru else "Look at this place: ") + answer
		_:
			answer = description
	_visited["response_counter"] = int(_visited.get("response_counter", 0)) + 1
	_store_location()
	return answer

func _store_location() -> void:
	var places: Dictionary = _state.get("locations", {})
	places[place_id] = _visited
	_state["locations"] = places
	_save()

func _personal_turn() -> Dictionary:
	var desired: String = ""
	if _topic_count >= 2 and _profile_get("favorite_color").is_empty():
		desired = "color"
	elif _topic_count >= 5 and _profile_get("name").is_empty():
		desired = "name"
	elif _topic_count >= 7 and _profile_get("age").is_empty():
		desired = "age"
	if desired.is_empty():
		return {}
	var asked: Array = _state.get("personal_asked", [])
	if asked.has(desired):
		return {}
	asked.append(desired)
	_state["personal_asked"] = asked
	_save()
	_pending_personal = desired
	stage = "personal"
	choices = _options(desired)
	var field: String = desired + "_q"
	return {"accepted": true, "npc": _ui(field), "choices": choices.duplicate(), "available": true}

func _skip(text: String) -> bool:
	var normalized: String = _clean(text)
	for phrase in ["i prefer not to say", "i don't want to say", "я не хочу говорить", "prefiro não dizer", "prefiero no decirlo", "je préfère ne pas le dire", "das möchte ich nicht sagen", "pass", "skip", "пропустить"]:
		if normalized == _clean(phrase):
			return true
	return false

func _begin_math() -> Dictionary:
	# Fixed per world/visit, but different challenges between worlds and visits.
	var offset: int = absi(hash(place_id) + int(_visited.get("visits", 0)) + _topic_count) % MATH_CHALLENGES.size()
	_math_a = int(MATH_CHALLENGES[offset][0])
	_math_b = int(MATH_CHALLENGES[offset][1])
	var value: int = _math_a + _math_b
	var dictionary: Dictionary = _words.get("math_number_words", {})
	var label: String = str(dictionary.get(str(value), {}).get(language, dictionary.get(str(value), {}).get("en", str(value))))
	choices = [str(value), label.capitalize(), "%d + %d = %d" % [_math_a, _math_b, value]]
	stage = "math"
	var format: String = str(_words.get("math_formats", {}).get(language, _words.get("math_formats", {}).get("en", "What is %d + %d?")))
	return {"accepted": true, "npc": format % [_math_a, _math_b], "choices": choices.duplicate()}

func _accept_math(text: String) -> bool:
	if _clean(text) == str(_math_a + _math_b):
		return true
	if _matches(text, choices):
		return true
	var dictionary: Dictionary = _words.get("math_number_words", {})
	var number: Dictionary = dictionary.get(str(_math_a + _math_b), {})
	for translated in number.values():
		if _clean(text) == _clean(str(translated)):
			return true
	return false

func _color_id(text: String) -> String:
	var normalized: String = " " + _clean(text) + " "
	for entry in _words.get("colors", []):
		var labels: Dictionary = entry.get("labels", {})
		for value in labels.values() + entry.get("aliases", []):
			if normalized.contains(" " + _clean(str(value)) + " "):
				return str(entry.get("id", ""))
	return ""

func _age_value(text: String) -> int:
	var normalized: String = _clean(text)
	for num in range(1, 121):
		var s: String = str(num)
		if (" " + normalized + " ").contains(" " + s + " "):
			return num
	var number_words: Dictionary = {"eight": 8, "ten": 10, "восемь": 8, "десять": 10, "huit": 8, "dix": 10, "acht": 8, "zehn": 10, "ocho": 8, "diez": 10, "oito": 8, "dez": 10}
	for token in number_words:
		if (" " + normalized + " ").contains(" " + token + " "):
			return int(number_words[token])
	return 0

func _name_value(text: String) -> String:
	var normalized: String = _clean(text)
	if _skip(text) or normalized.contains("explorer") or normalized.contains("исследовател") or normalized.contains("explorador") or normalized.contains("entdecker"):
		return ""
	for prefix in ["my name is ", "call me ", "you can call me ", "меня зовут ", "зови меня ", "je m'appelle ", "appelle-moi ", "ich heiße ", "nenn mich ", "me llamo ", "llámame ", "meu nome é ", "me chame de "]:
		if normalized.begins_with(prefix):
			normalized = normalized.trim_prefix(prefix).strip_edges()
			break
	if normalized.length() < 2 or normalized.length() > 24 or normalized.contains(" "):
		return ""
	if normalized.is_valid_int():
		return ""
	return normalized.substr(0, 1).to_upper() + normalized.substr(1)

func _accept_personal(text: String) -> bool:
	if _skip(text):
		return true
	match _pending_personal:
		"color":
			var color: String = _color_id(text)
			if not color.is_empty():
				_profile_set("favorite_color", color)
				return true
		"age":
			var age: int = _age_value(text)
			if age > 0:
				_profile_set("age", age)
				return true
		"name":
			var name: String = _name_value(text)
			if not name.is_empty():
				_profile_set("name", name)
				return true
			if _matches(text, _options("name")):
				return true # Generic nickname or refusal, never invent a legal name.
	return false

func accept(text: String) -> Dictionary:
	if not _enabled or _clean(text).is_empty():
		return {"accepted": false, "npc": _ui("bad"), "choices": choices.duplicate(), "available": _enabled}
	match stage:
		"greeting":
			if not _matches(text, _options("greeting")):
				# Also accept the English greeting independently of the selected hint.
				if not _matches(text, _words.get("personal", {}).get("greeting", {}).get("en", [])):
					return {"accepted": false, "npc": _ui("bad"), "choices": choices.duplicate()}
			return _choose_next()
		"story":
			return _accept_story(text)
		"story_quiz":
			return _accept_story_quiz(text)
		"personal":
			if not _accept_personal(text):
				return {"accepted": false, "npc": _ui("bad"), "choices": choices.duplicate()}
			_pending_personal = ""
			var next: Dictionary = _choose_next()
			next["npc"] = _ui("skip") if _skip(text) else _ui("thanks")
			return next
		"math":
			if not _accept_math(text):
				return {"accepted": false, "npc": _ui("math_bad"), "choices": choices.duplicate()}
			var math_result: Dictionary = _choose_next()
			math_result["npc"] = _ui("math_ok") + " " + _ui("choose")
			return math_result
		"choose":
			var topic: String = _topic_for(text)
			if topic.is_empty():
				return {"accepted": false, "npc": _ui("bad"), "choices": choices.duplicate()}
			var seen: Array = _visited.get("seen", [])
			if not seen.has(topic):
				seen.append(topic)
				_visited["seen"] = seen
			_topic_count += 1
			_store_location()
			if topic == "learn":
				return _begin_math()
			var response: String = _response(topic)
			var story: Dictionary = _open_story_if_possible(topic, response)
			if not story.is_empty():
				return story
			var personal: Dictionary = _personal_turn()
			if not personal.is_empty():
				personal["npc"] = response + "\n\n" + str(personal.get("npc", ""))
				return personal
			var result: Dictionary = _choose_next()
			result["npc"] = response + "\n\n" + str(result.get("npc", ""))
			return result
	return {"accepted": false, "npc": _ui("bad"), "choices": choices.duplicate()}
