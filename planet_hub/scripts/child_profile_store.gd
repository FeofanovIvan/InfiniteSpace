extends Node
## v60.1: sample answers are available immediately. NO first-run questionnaire.
## This is local prototype data; future child onboarding is a separate feature.
signal profile_ready
const DB_PATH: String = "user://miko_child_profile.json"
const SEED_PATH: String = "res://data/child_profile_seed.json"
const DEFAULT_PROFILE: Dictionary = {
	"name": "Алися",
	"name_cyrillic": "Алися",
	"name_latin": "Alisya",
	"age": 3,
	"favorite_color": "голубой"
}
var profile: Dictionary = {}
var questions: Array = []

func _ready() -> void:
	# Do not pause the prologue, do not create any screen or modal.
	var seed: Dictionary = _read_json(SEED_PATH)
	questions = seed.get("questions", []).duplicate(true)
	var initial: Dictionary = seed.get("demo_profile", DEFAULT_PROFILE)
	profile = DEFAULT_PROFILE.duplicate(true)
	for key in DEFAULT_PROFILE.keys():
		if initial.has(key):
			profile[key] = initial[key]
	# Keep existing data from previous attempts instead of deleting a save.
	var previous: Dictionary = _read_json(DB_PATH)
	var saved: Variant = previous.get("answers", {})
	if saved is Dictionary:
		for key in ["name", "age", "favorite_color"]:
			if saved.has(key) and str(saved[key]).strip_edges() != "":
				profile[key] = saved[key]
		for key in ["name_cyrillic", "name_latin"]:
			if saved.has(key) and str(saved[key]).strip_edges() != "":
				profile[key] = saved[key]
	# v60 saved only `name`; provide two scripts for the sample name.
	var name_value: String = str(profile.get("name", "Алися"))
	if name_value != "Алися" and str(profile.get("name_cyrillic", "")) == "Алися":
		profile["name_cyrillic"] = name_value
		# For customized names the future onboarding will collect transliteration.
		# Never silently change an unfamiliar name into "Alisya".
		profile["name_latin"] = name_value
	profile["name"] = str(profile.get("name_cyrillic", "Алися"))
	if profile.get("age") is String and str(profile["age"]).is_valid_int():
		profile["age"] = int(profile["age"])
	# Make the demo record persistent even when the child has never opened a form.
	var payload: Dictionary = {
		"schema_version": 2,
		"profile_initialized": true,
		"answers": profile.duplicate(true)
	}
	if previous != payload:
		var save_file: FileAccess = FileAccess.open(DB_PATH, FileAccess.WRITE)
		if save_file != null:
			save_file.store_string(JSON.stringify(payload, "  "))
			save_file.close()
		else:
			push_warning("Miko child demo profile could not be persisted to user://")
	profile_ready.emit()

func _read_json(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {}
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	return parsed if parsed is Dictionary else {}

func get_answer(field: String) -> String:
	return str(profile.get(field, ""))

func get_questions() -> Array:
	# Retained for later scripted conversations with planet representatives.
	return questions.duplicate(true)

func get_display_name(locale: String = "ru") -> String:
	# Russian uses Cyrillic; the other five supported locales use Latin.
	if locale == "ru":
		return str(profile.get("name_cyrillic", profile.get("name", "Алися")))
	return str(profile.get("name_latin", "Alisya"))
