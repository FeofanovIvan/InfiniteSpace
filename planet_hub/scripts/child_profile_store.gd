extends Node
## v93: consent-light local preference store.
## Never create a demo child's name, age, or favorite color.
## Values are learned only after the child voluntarily types a matching phrase.
signal profile_ready
signal answer_learned(key: String, value: Variant)

const DB_PATH: String = "user://miko_child_profile.json"
const ALLOWED_COLORS := ["red", "blue", "green", "yellow", "orange", "purple", "pink", "black"]
const OLD_DEMO: Dictionary = {
	"name": "Алися",
	"name_cyrillic": "Алися",
	"name_latin": "Alisya",
	"age": 3,
	"favorite_color": "голубой"
}
var profile: Dictionary = {}
var questions: Array = []

func _ready() -> void:
	var old: Dictionary = _read_json(DB_PATH)
	var answers: Dictionary = old.get("answers", {})
	if int(old.get("schema_version", 0)) >= 3 and answers is Dictionary:
		for key in ["name", "age", "favorite_color"]:
			if answers.has(key):
				_set_validated(key, answers[key])
	elif answers is Dictionary:
		# v60.1 persisted a fabricated profile at first run.
		# Keep only values clearly unlike the sample: ambiguous demo data is not user input.
		for key in ["name", "age", "favorite_color"]:
			if answers.has(key) and str(answers[key]) != str(OLD_DEMO.get(key, "")):
				var value: Variant = answers[key]
				if key == "favorite_color" and str(value).to_lower() == "голубой":
					value = "blue"
				_set_validated(key, value)
	_save()
	profile_ready.emit()

func _read_json(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {}
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	return parsed if parsed is Dictionary else {}

func _set_validated(key: String, value: Variant) -> bool:
	match key:
		"name":
			var nickname: String = str(value).strip_edges()
			if nickname.length() >= 2 and nickname.length() <= 24 and not nickname.contains("\n"):
				profile["name"] = nickname
				return true
		"age":
			var age: int = int(value) if str(value).is_valid_int() else -1
			if age >= 1 and age <= 120:
				profile["age"] = age
				return true
		"favorite_color":
			var color_id: String = str(value).to_lower().strip_edges()
			if ALLOWED_COLORS.has(color_id):
				profile["favorite_color"] = color_id
				return true
	return false

func remember_answer(key: String, value: Variant) -> bool:
	if not _set_validated(key, value):
		return false
	_save()
	answer_learned.emit(key, profile[key])
	return true

func _save() -> void:
	var file: FileAccess = FileAccess.open(DB_PATH, FileAccess.WRITE)
	if file != null:
		file.store_string(JSON.stringify({
			"schema_version": 3,
			"profile_initialized": false,
			"answers": profile
		}, "  "))
		file.close()

func get_answer(field: String) -> String:
	return str(profile.get(field, ""))

func get_questions() -> Array:
	# Legacy method retained; no first-run questionnaire.
	return questions.duplicate(true)

func get_display_name(_locale: String = "ru") -> String:
	return str(profile.get("name", ""))

func clear_answer(field: String) -> void:
	if profile.has(field):
		profile.erase(field)
		_save()
