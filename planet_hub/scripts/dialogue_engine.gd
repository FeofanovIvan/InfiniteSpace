extends RefCounted
## v93: deterministic, offline, world-aware, child-friendly conversation engine.
## Only the SELECTED choice guides typing; validation accepts all matching intents.
## No onboarding form, no fabricated age/name/color. Stored locally on device.

const WORLDS_PATH := "res://planet_hub/data/dialogue_worlds.json"
const PHRASES_PATH := "res://planet_hub/data/dialogue_phrases.json"
const ROSTER_PATH := "res://planet_hub/data/representatives.json"
const SAVE_PATH := "user://miko_dialogue_progress.json"
const TOPIC_ORDER := ["self", "world", "race", "race_about", "origin", "ability", "work", "energy", "age", "learn"]

var language: String = "ru"
var place_id: String = ""
var stage: String = "greeting"
var choices: Array[String] = []
var _world: Dictionary = {}
var _race: Dictionary = {}
var _words: Dictionary = {}
var _roster: Dictionary = {}
var _state: Dictionary = {}
var _visited: Dictionary = {}
var _profile: Node
var _topic_count: int = 0
var _pending_personal: String = ""
var _current_math_topic: String = ""
var _enabled: bool = false

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
	var text: String = value.to_lower().strip_edges()
	for mark in ["!", "?", ".", ",", ";", ":", "¡", "¿", "…", "«", "»", "\"", "“", "”", "—", "–"]:
		text = text.replace(mark, " ")
	while text.contains("  "):
		text = text.replace("  ", " ")
	return text.strip_edges()

func _matches(text: String, candidates: Array) -> bool:
	for item in candidates:
		if _clean(text) == _clean(str(item)):
			return true
	return false

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
	stage = "greeting"
	choices.clear()
	var world_database: Dictionary = _read(WORLDS_PATH)
	_words = _read(PHRASES_PATH)
	_roster = _read(ROSTER_PATH).get("assignments", {})
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
	var hello: String = _ui("hello")
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
	var normalized: String = _clean(text)
	var topics: Dictionary = _words.get("topics", {})
	for key in TOPIC_ORDER:
		var record: Dictionary = topics.get(key, {})
		var variants: Array = record.get(language, record.get("en", []))
		var english: Array = record.get("en", [])
		var station_variants: Array = _words.get("station_world", {}).get(language, []) if topic_is_station(key) else []
		var station_english: Array = _words.get("station_world", {}).get("en", []) if topic_is_station(key) else []
		for candidate in variants + english + station_variants + station_english:
			if normalized == _clean(str(candidate)):
				return key
	return ""

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
			var nonhuman: bool = str(_world.get("race", "")) != "human"
			var responses: Array = ([
				"Мы не все измеряем возраст земными годами.",
				"У разных рас свои способы измерять время жизни.",
				"Мой возраст трудно перевести в земные годы."
			] if ru else [
				"Not all of us measure age in Earth years.",
				"Different species measure the passage of a lifetime differently.",
				"My age is hard to translate into Earth years."
			]) if nonhuman else ([
				"Я предпочитаю не называть точный возраст.",
				"Не будем считать мои годы — давай лучше изучать планеты!",
				"Возраст — личная информация, но я с радостью расскажу о своей работе."
			] if ru else [
				"I prefer not to give my exact age.",
				"Let's explore planets instead of counting my years!",
				"Age is personal, but I can tell you about my work."
			])
			answer = str(responses[variant])
		"race":
			var patterns: Array = ([
				"Мой народ называется «%s».", "Мы называем себя «%s».", "Перед тобой представитель расы «%s»."
			] if ru else [
				"My species is called %s.", "We call ourselves %s.", "You are talking to a member of the %s species."
			])
			answer = str(patterns[variant]) % race_name
		"race_about":
			var intro: Array = ["", "Вот что я расскажу: ", "Наш народ необычен. "] if ru else ["", "Here is something to know: ", "Our people are unusual. "]
			answer = str(intro[variant]) + _race_fact("about")
		"origin":
			var patterns: Array = ([
				"Сейчас мой дом здесь, на %s. Наш народ живёт в разных мирах.",
				"Я встретил тебя на %s. Но моя цивилизация исследует много планет.",
				"Сейчас мы на %s. Представители моей расы путешествуют между мирами."
			] if ru else [
				"My home is at %s for now. My people live across many worlds.",
				"You met me at %s, but my civilization explores many planets.",
				"We are at %s now. My species travels among worlds."
			])
			answer = str(patterns[variant]) % world
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
			var intro: Array = ["", "Да, и это интересно: ", "Знаешь, что мы умеем? "] if ru else ["", "Here is something interesting: ", "Do you know what we can do? "]
			answer = str(intro[variant]) + _race_fact("ability")
		"energy":
			var intro: Array = ["", "У каждого вида свои потребности. ", "Мы совсем не обязаны питаться одинаково. "] if ru else ["", "Each species has different needs. ", "Not all life eats in the same way. "]
			answer = str(intro[variant]) + _race_fact("energy")
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

func _color_id(text: String) -> String:
	var normalized: String = " " + _clean(text) + " "
	for entry in _words.get("colors", []):
		var labels: Dictionary = entry.get("labels", {})
		for value in labels.values():
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
		"personal":
			if not _accept_personal(text):
				return {"accepted": false, "npc": _ui("bad"), "choices": choices.duplicate()}
			_pending_personal = ""
			var next: Dictionary = _choose_next()
			next["npc"] = _ui("skip") if _skip(text) else _ui("thanks")
			return next
		"math":
			if not _matches(text, _options("math")) and _clean(text) not in ["3", "three", "три", "trois", "drei", "tres", "três"]:
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
				stage = "math"
				choices = _options("math")
				return {"accepted": true, "npc": _ui("math_q"), "choices": choices.duplicate()}
			var response: String = _response(topic)
			var personal: Dictionary = _personal_turn()
			if not personal.is_empty():
				personal["npc"] = response + "\n\n" + str(personal.get("npc", ""))
				return personal
			var result: Dictionary = _choose_next()
			result["npc"] = response + "\n\n" + str(result.get("npc", ""))
			return result
	return {"accepted": false, "npc": _ui("bad"), "choices": choices.duplicate()}
