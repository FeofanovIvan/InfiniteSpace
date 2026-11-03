extends Control
const CloudChoiceButton = preload("res://planet_hub/scripts/cloud_choice_button.gd")
## v93.2: three floating cartoon speech clouds ABOVE the character on the left.
## Only the selected question is a typing hint; other meaningful input stays valid.
signal return_requested
@export var planet_background: String = "":
	set(value):
		planet_background = value
		_load_background()
@onready var character: Control = $RepresentativeCharacter
@onready var hint: Control = $PhraseHint
@onready var tablet: Control = $TranslatorTablet
var _background: Texture2D
var _back_button: Button
var _setup: bool = false
var _current_planet_id: String = ""
var _choice_dock: PanelContainer
var _choice_title: Label
var _choice_buttons: Array[Button] = []
var _selected_option: int = 0
const CHOICE_LABELS := {
	"ru": "ВЫБЕРИ ФРАЗУ И НАПЕЧАТАЙ",
	"en": "CHOOSE A PHRASE AND TYPE",
	"fr": "CHOISIS UNE PHRASE ET ÉCRIS",
	"de": "SATZ WÄHLEN UND EINGEBEN",
	"es": "ELIGE UNA FRASE Y ESCRIBE",
	"pt_BR": "ESCOLHA UMA FRASE E DIGITE"
}

func configure_for_planet(planet_id: String, _planet_name: String, background_path: String, portrait_path: String) -> void:
	_current_planet_id = planet_id
	planet_background = background_path
	if character != null:
		character.set("portrait_path", portrait_path)
	if tablet != null and tablet.has_method("configure_for_world"):
		tablet.call("configure_for_world", planet_id)
	queue_redraw()

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	process_mode = Node.PROCESS_MODE_ALWAYS
	_load_background()
	_back_button = Button.new()
	_back_button.name = "BackToPlanet"
	_back_button.text = "←"
	_back_button.tooltip_text = "Вернуться на планету"
	_back_button.focus_mode = Control.FOCUS_NONE
	_back_button.add_theme_font_size_override("font_size", 25)
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = Color("102c47")
	style.border_color = Color("65c9f5")
	style.set_corner_radius_all(12)
	style.set_border_width_all(1)
	_back_button.add_theme_stylebox_override("normal", style)
	var hover: StyleBoxFlat = style.duplicate() as StyleBoxFlat
	hover.bg_color = Color("23537d")
	_back_button.add_theme_stylebox_override("hover", hover)
	_back_button.add_theme_stylebox_override("pressed", hover)
	_back_button.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	add_child(_back_button)
	_back_button.pressed.connect(_go_back)
	# The old floating hint is hidden; all candidate phrases now live LEFT.
	hint.visible = false
	_build_choice_dock()
	if tablet != null and tablet.has_signal("suggestions_changed"):
		tablet.connect("suggestions_changed", Callable(self, "_on_suggestions_changed"))
		_on_suggestions_changed(tablet.call("get_suggestions"))
	_setup = true
	resized.connect(_layout_ui)
	_layout_ui()

func _build_choice_dock() -> void:
	_choice_dock = PanelContainer.new()
	_choice_dock.name = "LeftQuestionChoices"
	_choice_dock.mouse_filter = Control.MOUSE_FILTER_STOP
	# No box behind the choices: each cloud is free-floating.
	_choice_dock.add_theme_stylebox_override("panel", StyleBoxEmpty.new())
	add_child(_choice_dock)
	var column := VBoxContainer.new()
	column.name = "ChoicesLayout"
	column.add_theme_constant_override("separation", 6)
	_choice_dock.add_child(column)
	# The options speak for themselves; no instruction banner above the character.
	_choice_title = Label.new()
	_choice_title.name = "ChoiceInstruction"
	_choice_title.visible = false
	column.add_child(_choice_title)
	for index in range(3):
		var button: Button = CloudChoiceButton.new()
		button.name = "QuestionOption_%d" % index
		button.size_flags_vertical = Control.SIZE_EXPAND_FILL
		button.pressed.connect(_on_choice_pressed.bind(index))
		column.add_child(button)
		_choice_buttons.append(button)
	_choice_dock.visible = false

func _style_choice_button(button: Button, selected: bool) -> void:
	# Cream/gold Launch style when selected; pastel blue Simulator style otherwise.
	button.set("chosen", selected)

func _on_suggestions_changed(options: Array) -> void:
	if _choice_dock == null:
		return
	_selected_option = 0
	_choice_dock.visible = not options.is_empty()
	var locale: String = str(tablet.call("get_language")) if tablet != null else "ru"
	_choice_title.text = str(CHOICE_LABELS.get(locale, CHOICE_LABELS["en"]))
	for i in range(_choice_buttons.size()):
		var button: Button = _choice_buttons[i]
		button.visible = i < options.size()
		if button.visible:
			button.call("set_phrase", str(options[i]))
		_style_choice_button(button, i == _selected_option)
	_layout_ui()

func _on_choice_pressed(index: int) -> void:
	if tablet == null or index >= _choice_buttons.size() or not _choice_buttons[index].visible:
		return
	_selected_option = index
	tablet.call("select_suggestion", index)
	for i in range(_choice_buttons.size()):
		if _choice_buttons[i].visible:
			_style_choice_button(_choice_buttons[i], i == _selected_option)

func _load_background() -> void:
	_background = null
	if not planet_background.is_empty() and ResourceLoader.exists(planet_background):
		_background = load(planet_background) as Texture2D
	queue_redraw()

func _layout_ui() -> void:
	if not _setup or size.x < 200 or size.y < 140:
		return
	var w: float = size.x
	var h: float = size.y
	var split: float = w * 0.50
	# The character fills the lower half: the clouds hover over its head.
	character.position = Vector2(8, h * 0.36)
	character.size = Vector2(split - 16, h * 0.615)
	tablet.position = Vector2(split, 0)
	tablet.size = Vector2(w - split, h)
	if _choice_dock != null:
		var margin: float = maxf(70.0, split * 0.115)
		_choice_dock.position = Vector2(margin, h * 0.025)
		_choice_dock.size = Vector2(split - margin - maxf(18.0, split * 0.035), h * 0.395)
		for button in _choice_buttons:
			button.custom_minimum_size.y = clampf(h * 0.112, 57.0, 96.0)
	_back_button.position = Vector2(maxf(10, w * 0.009), maxf(10, h * 0.018))
	_back_button.size = Vector2(clampf(w * 0.05, 45, 68), clampf(h * 0.09, 42, 64))
	_back_button.move_to_front()
	queue_redraw()

func _go_back() -> void:
	if not Engine.is_editor_hint():
		return_requested.emit()

func _unhandled_key_input(event: InputEvent) -> void:
	if not Engine.is_editor_hint() and event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		_go_back()
		get_viewport().set_input_as_handled()

func _draw() -> void:
	var w: float = size.x
	var h: float = size.y
	if w < 5 or h < 5:
		return
	if _background != null:
		var ts: Vector2 = _background.get_size()
		var factor: float = maxf(w / ts.x, h / ts.y)
		var crop: Vector2 = Vector2(w, h) / factor
		draw_texture_rect_region(_background, Rect2(Vector2.ZERO, size), Rect2((ts - crop) * 0.5, crop))
	else:
		draw_rect(Rect2(Vector2.ZERO, size), Color("06192d"))
		var random: RandomNumberGenerator = RandomNumberGenerator.new()
		random.seed = 2412
		for i in range(150):
			var p: Vector2 = Vector2(random.randf_range(0, w * 0.5), random.randf_range(0, h))
			draw_circle(p, random.randf_range(0.3, 1.2), Color(0.66, 0.85, 1.0, random.randf_range(0.15, 0.50)))
	draw_rect(Rect2(0, 0, w * 0.5, h), Color(0.0, 0.02, 0.05, 0.18))
