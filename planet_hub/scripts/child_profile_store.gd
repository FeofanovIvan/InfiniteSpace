extends Node
## ChildProfileStore: first-run local-only prototype with three editable answers.
## Do not send data to a server. This is a developer sample, not final onboarding.
signal profile_ready
const DB_PATH: String = "user://miko_child_profile.json"
const SEED_PATH: String = "res://data/child_profile_seed.json"
const LABELS: Dictionary = {
	"ru": {"heading":"Знакомство", "next":"Дальше", "finish":"Начать путешествие", "hint":"Ответ можно изменить", "age_error":"Введи возраст цифрами от 1 до 17"},
	"en": {"heading":"Let's meet!", "next":"Next", "finish":"Start adventure", "hint":"You can change this answer", "age_error":"Enter an age from 1 to 17"},
	"fr": {"heading":"Faisons connaissance", "next":"Suivant", "finish":"Commencer", "hint":"Tu peux modifier la réponse", "age_error":"Entre un âge entre 1 et 17"},
	"de": {"heading":"Wir lernen uns kennen", "next":"Weiter", "finish":"Los geht's", "hint":"Du kannst die Antwort ändern", "age_error":"Alter von 1 bis 17 eingeben"},
	"es": {"heading":"¡Vamos a conocernos!", "next":"Siguiente", "finish":"Empezar", "hint":"Puedes cambiar la respuesta", "age_error":"Escribe una edad de 1 a 17"},
	"pt_BR": {"heading":"Vamos nos conhecer!", "next":"Próximo", "finish":"Começar", "hint":"Você pode mudar a resposta", "age_error":"Digite uma idade de 1 a 17"}
}
var profile: Dictionary = {}
var questions: Array = []
var _seed: Dictionary = {}
var _step: int = 0
var _layer: CanvasLayer
var _root: Control
var _panel: PanelContainer
var _title: Label
var _progress: Label
var _question: Label
var _answer: LineEdit
var _action: Button
var _status: Label
var _ui_ready: bool = false

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_seed = _read_json(SEED_PATH)
	questions = _seed.get("questions", [])
	profile = _seed.get("demo_profile", {}).duplicate(true)
	var stored: Dictionary = _read_json(DB_PATH)
	if bool(stored.get("onboarding_completed", false)):
		profile = stored.get("answers", profile).duplicate(true)
		profile_ready.emit()
	else:
		# Pause after current scene exists; prevent the prologue from progressing
		# until the child confirms the three sample answers.
		call_deferred("_show_first_run")

func _read_json(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {}
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	return parsed if parsed is Dictionary else {}

func get_answer(field: String) -> String:
	return str(profile.get(field, ""))

func get_questions() -> Array:
	return questions.duplicate(true)

func current_language() -> String:
	var loc: Node = get_node_or_null("/root/MobileLocale")
	var lang: String = str(loc.get("language")) if loc != null else "ru"
	return lang if LABELS.has(lang) else "en"

func _show_first_run() -> void:
	if _ui_ready:
		return
	_ui_ready = true
	_layer = CanvasLayer.new()
	_layer.name = "ChildFirstRunQuestions"
	_layer.layer = 120
	add_child(_layer)
	_root = Control.new()
	_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_root.mouse_filter = Control.MOUSE_FILTER_STOP
	_layer.add_child(_root)
	var bg := ColorRect.new()
	bg.color = Color(0.02, 0.06, 0.13, 0.97)
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_root.add_child(bg)
	_panel = PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = Color("112b49")
	style.border_color = Color("48b8ee")
	style.set_border_width_all(2)
	style.set_corner_radius_all(22)
	style.set_content_margin_all(22)
	_panel.add_theme_stylebox_override("panel", style)
	_root.add_child(_panel)
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 14)
	_panel.add_child(col)
	_title = Label.new()
	_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_title.add_theme_font_size_override("font_size", 27)
	col.add_child(_title)
	_progress = Label.new()
	_progress.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_progress.add_theme_color_override("font_color", Color("75d6ff"))
	col.add_child(_progress)
	_question = Label.new()
	_question.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_question.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_question.add_theme_font_size_override("font_size", 24)
	col.add_child(_question)
	_answer = LineEdit.new()
	_answer.add_theme_font_size_override("font_size", 26)
	_answer.custom_minimum_size.y = 55
	_answer.text_submitted.connect(func(_text: String): _submit())
	col.add_child(_answer)
	_status = Label.new()
	_status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_status.add_theme_color_override("font_color", Color("b1d7e9"))
	col.add_child(_status)
	_action = Button.new()
	_action.custom_minimum_size.y = 58
	_action.add_theme_font_size_override("font_size", 22)
	_action.pressed.connect(_submit)
	col.add_child(_action)
	get_viewport().size_changed.connect(_layout)
	_step = 0
	_render_step()
	_layout()
	get_tree().paused = true

func _render_step() -> void:
	if _step >= questions.size():
		return
	var lang: String = current_language()
	var labels: Dictionary = LABELS.get(lang, LABELS["ru"])
	var q: Dictionary = questions[_step]
	_title.text = str(labels.get("heading", ""))
	_progress.text = "%d / %d" % [_step + 1, questions.size()]
	_question.text = str(q.get(lang, q.get("ru", "")))
	_answer.text = str(profile.get(str(q.get("id", "")), ""))
	_answer.max_length = 48
	_answer.select_all_on_focus = false
	_action.text = str(labels.get("finish" if _step == questions.size() - 1 else "next", ""))
	_status.text = str(labels.get("hint", ""))

func _submit() -> void:
	var q: Dictionary = questions[_step]
	var key: String = str(q.get("id", ""))
	var response: String = _answer.text.strip_edges()
	if response.is_empty():
		return
	if key == "age":
		if not response.is_valid_int() or int(response) < 1 or int(response) > 17:
			_status.text = str(LABELS.get(current_language(), LABELS["ru"]).get("age_error"))
			return
		profile[key] = int(response)
	else:
		profile[key] = response
	_step += 1
	if _step < questions.size():
		_render_step()
	else:
		var payload: Dictionary = {"schema_version": 1, "onboarding_completed": true, "answers": profile}
		var file: FileAccess = FileAccess.open(DB_PATH, FileAccess.WRITE)
		if file != null:
			file.store_string(JSON.stringify(payload, "  "))
			file.close()
		get_tree().paused = false
		_layer.queue_free()
		profile_ready.emit()

func _layout() -> void:
	if _panel == null:
		return
	var view: Vector2 = get_viewport().get_visible_rect().size
	_root.size = view
	var width: float = minf(view.x * 0.76, 660.0)
	var height: float = minf(view.y * 0.85, 370.0)
	_panel.position = Vector2((view.x - width) * 0.5, (view.y - height) * 0.5)
	_panel.size = Vector2(width, height)
