extends RefCounted
const InputMatcher = preload("res://planet_hub/scripts/dialogue_input_matcher.gd")
## v93: deterministic, offline, world-aware, child-friendly conversation engine.
## Only the SELECTED choice guides typing; validation accepts all matching intents.
## No onboarding form, no fabricated age/name/color. Stored locally on device.

const WORLDS_PATH := "res://planet_hub/data/dialogue_worlds.json"
const PHRASES_PATH := "res://planet_hub/data/dialogue_phrases.json"
const STORIES_PATH := "res://planet_hub/data/dialogue_story_scenes.json"
const STORY_QUIZZES_PATH := "res://planet_hub/data/dialogue_story_quizzes.json"
const ADVENTURES_PATH := "res://planet_hub/data/dialogue_adventures.json"
const ADVENTURES_V99_PATH := "res://planet_hub/data/dialogue_adventures_v99.json"
const REPRESENTATIVE_PROFILES_PATH := "res://planet_hub/data/representative_profiles.json"
const RESPONSE_TRANSLATIONS_PATH := "res://planet_hub/data/dialogue_responses_i18n.json"
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
var _adventures: Dictionary = {}
var _adventures_v99: Dictionary = {}
var _representative: Dictionary = {}
var _replies: Dictionary = {}
var _active_adventure: Dictionary = {}
var _active_adventure_index: int = -1
var _pending_adventure_quiz: bool = false
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
	_active_adventure = {}
	_active_adventure_index = -1
	_pending_adventure_quiz = false
	stage = "greeting"
	choices.clear()
	var world_database: Dictionary = _read(WORLDS_PATH)
	_words = _read(PHRASES_PATH)
	_stories = _read(STORIES_PATH)
	_story = _stories.get("scenes", {}).get(target, {})
	_story_quizzes = _read(STORY_QUIZZES_PATH)
	_adventures = _read(ADVENTURES_PATH)
	_adventures_v99 = _read(ADVENTURES_V99_PATH)
	_representative = _read(REPRESENTATIVE_PROFILES_PATH).get("characters", {}).get(target, {})
	_replies = _read(RESPONSE_TRANSLATIONS_PATH).get("locales", {}).get(language, {})
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
	if not _state.has("character_adventures") or not (_state["character_adventures"] is Dictionary):
		_state["character_adventures"] = {}
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
		hello += " " + str(_replies.get("return", "Welcome back, %s!")) % nickname
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
		# Match semantic variants in every game language, not just current+English.
		# UI/hints remain in the chosen locale. No cloud translation or free-form AI.
		var all_candidates: Array = []
		for locale in ["ru", "en", "fr", "de", "es", "pt_BR"]:
			all_candidates.append_array(record.get(locale, []))
			if topic_is_station(key):
				all_candidates.append_array(_words.get("station_world", {}).get(locale, []))
		var intent_score: int = InputMatcher.NO_MATCH
		for candidate in all_candidates:
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

## One representative may appear on several planets. Progress is attached to
## their existing portrait assignment (never to a typed name or child data).
func _adventure_memory_key() -> String:
	# Portraits are reusable visual templates, not identities. Never share memory
	# between two planets merely because they display the same PNG.
	return str(_representative.get("character_id", "npc_" + place_id))

func _adventure_memory() -> Dictionary:
	var all: Dictionary = _state.get("character_adventures", {})
	return all.get(_adventure_memory_key(), {})

func _adventure_episodes() -> Array:
	var race_id: String = str(_world.get("race", ""))
	var episodes: Array = _adventures.get("races", {}).get(race_id, []).duplicate()
	var additional: Array = _adventures_v99.get("races", {}).get(race_id, [])
	episodes.append_array(additional)
	return episodes

func _migrate_chapters_if_needed() -> Dictionary:
	var memory: Dictionary = _adventure_memory()
	if memory.is_empty() or str(memory.get("chapter_set", "")) == "v99":
		return memory
	var count: int = maxi(0, int(memory.get("completed", 0)))
	# v98 had only two episodes, so a high count meant replaying them.
	# Offer chapters 3 and 4 next, without destroying any old choices/history.
	memory["legacy_completed_v98"] = count
	memory["completed"] = mini(count, 2)
	memory["chapter_set"] = "v99"
	var saved: Dictionary = _state.get("character_adventures", {})
	saved[_adventure_memory_key()] = memory
	_state["character_adventures"] = saved
	_save()
	return memory

func _adventure_options(episode: Dictionary) -> Array[String]:
	var options: Array[String] = []
	for entry in episode.get("choices", []):
		options.append(_localized(entry))
	return options

func _begin_adventure(prelude: String, follow_with_quiz: bool) -> Dictionary:
	var episodes: Array = _adventure_episodes()
	if episodes.is_empty():
		if follow_with_quiz:
			return _begin_story_quiz(prelude)
		var ordinary: Dictionary = _choose_next()
		ordinary["npc"] = prelude + "\n\n" + str(ordinary.get("npc", ""))
		return ordinary
	var memory: Dictionary = _migrate_chapters_if_needed()
	var completed: int = maxi(0, int(memory.get("completed", 0)))
	var index: int = completed % episodes.size()
	_active_adventure_index = index
	_active_adventure = episodes[index]
	_pending_adventure_quiz = follow_with_quiz
	choices = _adventure_options(_active_adventure)
	if choices.size() != 3:
		_active_adventure = {}
		_active_adventure_index = -1
		_pending_adventure_quiz = false
		var next: Dictionary = _choose_next()
		next["npc"] = prelude + "\n\n" + str(next.get("npc", ""))
		return next
	stage = "story_adventure"
	var intro: String = _localized(_active_adventure.get("intro", {}))
	var cues: Array = _representative.get("i18n", {}).get(language, {}).get("chapter_cues", _representative.get("chapter_cues", []))
	if index < cues.size():
		intro = str(cues[index]) + "\n" + intro
	if completed > 0:
		var prior_episode: int = int(memory.get("last_episode", -1))
		var prior_choice: int = int(memory.get("last_choice", -1))
		if prior_episode >= 0 and prior_episode < episodes.size():
			var previous: Dictionary = episodes[prior_episode]
			var labels: Array = previous.get("choices", [])
			if prior_choice >= 0 and prior_choice < labels.size():
				var linked_to_previous: bool = str(_active_adventure.get("follows", "")) == str(previous.get("id", ""))
				var echoes: Array = _active_adventure.get("callbacks", [])
				if linked_to_previous and prior_choice < echoes.size():
					intro = _localized(echoes[prior_choice]) + "\n" + intro
				else:
					var previous_phrase: String = _localized(labels[prior_choice])
					var memory_format: String = _localized(_adventures.get("revisit_prefix", {}))
					if memory_format.contains("%s"):
						intro = (memory_format % previous_phrase) + "\n" + intro
	return {"accepted": true, "available": true,
		"npc": prelude + "\n\n" + intro, "choices": choices.duplicate()}

func _adventure_choice_index(text: String) -> int:
	var best: int = InputMatcher.NO_MATCH
	var winning: int = -1
	var tied: bool = false
	var alternatives: Array = _active_adventure.get("choices", [])
	for i in range(alternatives.size()):
		var translations: Dictionary = alternatives[i]
		for locale in translations.keys():
			var quality: int = InputMatcher.score(text, str(translations[locale]))
			if quality >= InputMatcher.NO_MATCH:
				continue
			if quality < best:
				best = quality
				winning = i
				tied = false
			elif quality == best and winning != i:
				tied = true
	return -1 if tied else winning

func _accept_adventure(text: String) -> Dictionary:
	if _skip(text):
		_pending_adventure_quiz = false
		var skipped: Dictionary = _choose_next()
		skipped["npc"] = _ui("skip") + "\n\n" + str(skipped.get("npc", ""))
		return skipped
	var selected: int = _adventure_choice_index(text)
	if selected < 0:
		# The child may abandon any optional branch and ask a known topic.
		var other_topic: String = _topic_for(text)
		if not other_topic.is_empty():
			_pending_adventure_quiz = false
			stage = "choose"
			return accept(text)
		return {"accepted": false, "available": true,
			"npc": _ui("bad"), "choices": choices.duplicate()}
	var outcomes: Array = _active_adventure.get("outcomes", [])
	if selected >= outcomes.size():
		return {"accepted": false, "available": true,
			"npc": _ui("bad"), "choices": choices.duplicate()}
	var answer: String = _localized(outcomes[selected])
	if _active_adventure_index == 3 and not _representative.is_empty():
		answer += "\n" + _personal_share()
	# No numeric score or failure; the three choices tell different stories.
	var memory: Dictionary = _adventure_memory()
	var total: int = maxi(0, int(memory.get("completed", 0))) + 1
	memory["completed"] = total
	memory["chapter_set"] = "v99"
	memory["last_episode"] = _active_adventure_index
	memory["last_choice"] = selected
	memory["last_place"] = place_id
	var history: Array = memory.get("history", [])
	history.append({"episode": _active_adventure_index, "choice": selected})
	if history.size() > 8:
		history = history.slice(history.size() - 8)
	memory["history"] = history
	var all: Dictionary = _state.get("character_adventures", {})
	all[_adventure_memory_key()] = memory
	_state["character_adventures"] = all
	_visited["adventures_completed"] = int(_visited.get("adventures_completed", 0)) + 1
	_store_location()
	var wants_quiz: bool = _pending_adventure_quiz
	_pending_adventure_quiz = false
	_active_adventure = {}
	if wants_quiz:
		return _begin_story_quiz(answer)
	var next: Dictionary = _choose_next()
	next["npc"] = answer + "\n\n" + str(next.get("npc", ""))
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
	if not _representative.is_empty():
		intro = (str(_replies.get("story_identity", "I'm %s. My role: %s.")) % [_name(), _role()]) + "\n" + intro
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
	return _begin_adventure(answer, index == 2)

func _race_fact(field: String) -> String:
	return str(_race.get(field + "_" + language, _race.get(field + "_en", "")))

func _name() -> String:
	if not _representative.is_empty():
		return str(_representative.get("name_localized", {}).get(language, _representative.get("name", "")))
	var entry: Dictionary = _roster.get(place_id, {})
	return str(entry.get("display_name", entry.get("name_ru", "")))

func _locale_person() -> Dictionary:
	return _representative.get("i18n", {}).get(language, _representative.get("i18n", {}).get("en", {}))

func _role() -> String:
	return str(_locale_person().get("role", _representative.get("role", "")))

func _personal_work() -> String:
	return str(_locale_person().get("work", _representative.get("work", "")))

func _personal_mystery() -> String:
	return str(_locale_person().get("mystery", _representative.get("mystery", "")))

func _personal_share() -> String:
	return str(_locale_person().get("share", _representative.get("share", "")))

func _world_name() -> String:
	return _localized(_world.get("name", {}))

func _reply_variant(key: String, variant: int) -> String:
	var raw: Variant = _replies.get(key, [])
	if raw is Array and not raw.is_empty():
		return str(raw[variant % raw.size()])
	return ""

func _favorite_color_line(description: String) -> String:
	var favorite: String = _profile_get("favorite_color")
	if favorite.is_empty():
		return ""
	var color_id: String = _color_id(favorite)
	if color_id.is_empty():
		return ""  # Do not claim a visual match for an unknown color.
	for entry in _words.get("colors", []):
		if str(entry.get("id", "")) != color_id:
			continue
		var labels: Dictionary = entry.get("labels", {})
		var label: String = str(labels.get(language, labels.get("en", "")))
		if not label.is_empty() and description.to_lower().contains(label.to_lower()):
			return str(_replies.get("favorite", "")) % label
	return ""

func _response(topic: String) -> String:
	var name: String = _name()
	var world: String = _world_name()
	var race_name: String = str(_race.get(language, _race.get("en", "")))
	var description: String = _localized(_world.get("world", {}))
	var structure: String = _localized(_world.get("structure", {}))
	var variant: int = int(_visited.get("response_counter", 0)) % 3
	var answer: String = ""
	match topic:
		"self":
			var age_hint: String = _profile_get("age")
			var little: bool = age_hint.is_valid_int() and int(age_hint) <= 5
			if little:
				# A short first-person introduction for preschoolers, no gendered titles.
				answer = str(_replies.get("self_young", "I'm %s. %s")) % [name, _personal_work()]
			else:
				answer = _reply_variant("self", variant) % [name, _role(), _personal_work()]
		"age":
			# Ages previously keyed by shared portrait were not character-specific.
			# Avoid fabricating a gender/age. The answer is still meaningful.
			answer = _reply_variant("age", variant)
		"race":
			answer = _reply_variant("race", variant) % race_name
		"race_about":
			answer = _reply_variant("race_about", variant) + _race_fact("about")
		"origin":
			answer = _reply_variant("origin", variant) % world
		"world":
			answer = description
			if variant == 1 and not structure.is_empty():
				answer += " " + structure
			elif variant == 2:
				answer = str(_replies.get("world_look", "")) + description
			var colors: String = _favorite_color_line(description)
			if not colors.is_empty():
				answer += " " + colors
		"ability":
			answer = _reply_variant("ability", variant) + _race_fact("ability")
		"energy":
			answer = _reply_variant("energy", variant) + _race_fact("energy")
		"work":
			answer = _reply_variant("work", variant) + _personal_work()
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
			var greetings: Array = []
			for locale in ["ru", "en", "fr", "de", "es", "pt_BR"]:
				greetings.append_array(_words.get("personal", {}).get("greeting", {}).get(locale, []))
			if not _matches(text, greetings):
				return {"accepted": false, "npc": _ui("bad"), "choices": choices.duplicate()}
			return _choose_next()
		"story":
			return _accept_story(text)
		"story_adventure":
			return _accept_adventure(text)
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
