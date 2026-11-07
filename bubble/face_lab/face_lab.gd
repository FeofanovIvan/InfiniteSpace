extends Control
## Side-by-side, isolated FaceRig laboratory. RUN SCENE WITH F6 IN GODOT.
## The main game, care room and fetch game are deliberately untouched.

const ORIGINAL_BUBBLE: PackedScene = preload("res://bubble/scenes/bubble_character.tscn")
const LAB_BRAIN: Script = preload("res://bubble/face_lab/bubble_lab_brain.gd")
const SAVE_FILE: String = "user://mika_bubble_face_lab.json"
const EXPRESSIONS: Array[String] = ["calm", "happy", "excited", "curious", "playful", "surprised", "content", "sleepy", "sad", "proud", "delighted"]

var _original: MikaBubbleBrain
var _experimental: MikaBubbleBrain
var _background: ColorRect
var _stages: Array[Panel] = []
var _stage_labels: Array[Label] = []
var _title: Label
var _controls: Panel
var _toolbar_scroll: ScrollContainer
var _toolbar: HBoxContainer
var _scroll: ScrollContainer
var _grid: GridContainer
var _sliders: Dictionary = {}
var _values: Dictionary = {}
var _expression: OptionButton
var _auto_turn: CheckButton
var _show_points: CheckButton
var _status: Label
var _yaw_angle: float = 0.0
var _loading: bool = true
var _old_movement_position: float = 0.0

const DEFAULTS: Dictionary = {
	"yaw": 0.0, "pitch": 0.0, "eye_spacing": 86.0, "eye_height": -36.0,
	"mouth_height": 88.0, "eye_size": 1.0, "mouth_size": 1.0,
	"surface_width": 193.0, "mouth_open": 0.0,
}

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	_build_stage()
	_build_controls()
	_original = ORIGINAL_BUBBLE.instantiate() as MikaBubbleBrain
	_original.name = "OriginalBubble_DoNotModify"
	_original.external_motion_control = true
	add_child(_original)
	_experimental = LAB_BRAIN.new() as MikaBubbleBrain
	_experimental.name = "ExperimentalBubble_SurfaceSockets"
	_experimental.external_motion_control = true
	add_child(_experimental)
	# Move bodies above the stage panels, but BELOW all UI.
	_original.z_index = 2
	_experimental.z_index = 2
	_title.z_index = 5
	_controls.z_index = 5
	for item in _stage_labels:
		item.z_index = 5
	_loading = false
	_load_settings()
	_apply_values()
	resized.connect(_layout)
	_layout()

func _panel_skin(fill: Color, edge: Color, corner: int = 19) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.border_color = edge
	style.set_border_width_all(2)
	style.set_corner_radius_all(corner)
	return style

func _button(label_text: String, callback: Callable) -> Button:
	var b := Button.new()
	b.text = label_text
	b.focus_mode = Control.FOCUS_NONE
	b.custom_minimum_size = Vector2(108, 37)
	b.add_theme_font_size_override("font_size", 14)
	b.add_theme_stylebox_override("normal", _panel_skin(Color("092642"), Color("53cbe5"), 12))
	b.add_theme_stylebox_override("hover", _panel_skin(Color("16445f"), Color("b8efff"), 12))
	b.pressed.connect(callback)
	return b

func _build_stage() -> void:
	_background = ColorRect.new()
	_background.color = Color("071525")
	_background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_background)
	_background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for caption in ["ТЕКУЩИЙ · FaceRig", "ЭКСПЕРИМЕНТ · ОБЪЁМНЫЕ ПОСАДОЧНЫЕ ТОЧКИ"]:
		var stage := Panel.new()
		stage.mouse_filter = Control.MOUSE_FILTER_IGNORE
		stage.add_theme_stylebox_override("panel", _panel_skin(Color("0a253a"), Color("32607f")))
		add_child(stage)
		_stages.append(stage)
		var label_node := Label.new()
		label_node.text = caption
		label_node.add_theme_font_size_override("font_size", 15)
		label_node.add_theme_color_override("font_color", Color("b7f3ff"))
		label_node.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(label_node)
		_stage_labels.append(label_node)
	_title = Label.new()
	_title.text = "БАББЛ · ЛАБОРАТОРИЯ ЛИЦА  |  сравнение на одной жидкой модели"
	_title.add_theme_font_size_override("font_size", 23)
	_title.add_theme_color_override("font_color", Color("eefbff"))
	_title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_title)

func _build_controls() -> void:
	_controls = Panel.new()
	_controls.add_theme_stylebox_override("panel", _panel_skin(Color("0b2137"), Color("3984a2")))
	add_child(_controls)
	_toolbar_scroll = ScrollContainer.new()
	_toolbar_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	_toolbar_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_controls.add_child(_toolbar_scroll)
	_toolbar = HBoxContainer.new()
	_toolbar.add_theme_constant_override("separation", 8)
	_toolbar_scroll.add_child(_toolbar)
	_expression = OptionButton.new()
	_expression.tooltip_text = "Мимика на обоих персонажах"
	_expression.custom_minimum_size = Vector2(135, 38)
	for id in EXPRESSIONS:
		_expression.add_item(id)
	_expression.item_selected.connect(_on_expression_selected)
	_toolbar.add_child(_expression)
	_auto_turn = CheckButton.new()
	_auto_turn.text = "Вращать"
	_auto_turn.button_pressed = true
	_toolbar.add_child(_auto_turn)
	_show_points = CheckButton.new()
	_show_points.text = "Якоря"
	_show_points.button_pressed = true
	_show_points.toggled.connect(_on_show_points_toggled)
	_toolbar.add_child(_show_points)
	_toolbar.add_child(_button("Сохранить", _save_settings))
	_toolbar.add_child(_button("Сброс", _reset_values))
	_toolbar.add_child(_button("Закрыть", _close_lab))
	_scroll = ScrollContainer.new()
	_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	_controls.add_child(_scroll)
	_grid = GridContainer.new()
	_grid.columns = 4
	_grid.add_theme_constant_override("h_separation", 11)
	_grid.add_theme_constant_override("v_separation", 5)
	_scroll.add_child(_grid)
	_add_slider("yaw", "Поворот · °", -180.0, 180.0, 1.0)
	_add_slider("pitch", "Наклон · °", -35.0, 35.0, 1.0)
	_add_slider("eye_spacing", "Расстояние глаз", 48.0, 130.0, 1.0)
	_add_slider("eye_height", "Высота глаз", -90.0, -5.0, 1.0)
	_add_slider("mouth_height", "Высота рта", 30.0, 130.0, 1.0)
	_add_slider("eye_size", "Масштаб глаз", 0.60, 1.30, 0.01)
	_add_slider("mouth_size", "Масштаб рта", 0.60, 1.35, 0.01)
	_add_slider("surface_width", "Радиус поверхности", 160.0, 230.0, 1.0)
	_add_slider("mouth_open", "Открытие рта", 0.0, 1.0, 0.01)
	_status = Label.new()
	_status.text = "Посадочные места: бирюзовый — глаза, янтарный — рот. Все настройки только для тестовой модели."
	_status.add_theme_color_override("font_color", Color("9cc7d8"))
	_status.add_theme_font_size_override("font_size", 12)
	_status.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_controls.add_child(_status)

func _add_slider(id: String, description: String, minimum: float, maximum: float, interval: float) -> void:
	var group := VBoxContainer.new()
	group.custom_minimum_size = Vector2(193, 59)
	_grid.add_child(group)
	var caption := Label.new()
	caption.text = description
	caption.add_theme_font_size_override("font_size", 13)
	caption.add_theme_color_override("font_color", Color("c9e8f5"))
	group.add_child(caption)
	var value := HSlider.new()
	value.custom_minimum_size = Vector2(186, 18)
	value.min_value = minimum
	value.max_value = maximum
	value.step = interval
	value.value = float(DEFAULTS.get(id, 0.0))
	value.value_changed.connect(_on_slider_changed.bind(id))
	group.add_child(value)
	_sliders[id] = value
	_values[id] = value.value

func _on_expression_selected(_index: int) -> void:
	_apply_values()

func _on_show_points_toggled(_checked: bool) -> void:
	_apply_values()

func _close_lab() -> void:
	get_tree().quit()

func _on_slider_changed(value: float, id: String) -> void:
	_values[id] = value
	if id == "yaw":
		_yaw_angle = value
	if not _loading:
		_apply_values()

func _apply_values() -> void:
	if _loading or not is_instance_valid(_experimental):
		return
	var face: Node = _experimental.get_face()
	if face != null and face.has_method("set_lab_calibration"):
		var d: Dictionary = _values.duplicate(true)
		d["show_sockets"] = _show_points.button_pressed
		face.call("set_lab_calibration", d)
	var selected: String = EXPRESSIONS[_expression.selected] if _expression.selected >= 0 else "calm"
	for b in [_original, _experimental]:
		if is_instance_valid(b):
			b.set_room_emotion(selected, 1000.0)
			b.set_mouth_open(float(_values.get("mouth_open", 0.0)))
	_update_heading()

func _update_heading() -> void:
	if not is_instance_valid(_original) or not is_instance_valid(_experimental):
		return
	var yaw: float = deg_to_rad(_yaw_angle)
	_original.set_room_heading(yaw)
	_experimental.set_room_heading(yaw)

func _process(delta: float) -> void:
	if _auto_turn != null and _auto_turn.button_pressed:
		_yaw_angle = wrapf(_yaw_angle + delta * 31.0, -180.0, 180.0)
		# Avoid calling the calibration on every incremental tick: update the body
		# and sockets together, preserving the face and liquid movement rig.
		_update_heading()
	else:
		_update_heading()
	if is_instance_valid(_original) and is_instance_valid(_experimental):
		var elapsed_motion: float = delta * 76.0
		_old_movement_position += elapsed_motion
		var moving: float = 0.17 + 0.22 * (0.5 + 0.5 * sin(_old_movement_position * 0.017))
		for b in [_original, _experimental]:
			b.set_room_locomotion("walk_forward", moving, elapsed_motion * moving)

func _layout() -> void:
	if _stages.is_empty() or _controls == null:
		return
	var viewport_size: Vector2 = size
	if viewport_size.x < 180.0 or viewport_size.y < 260.0:
		return
	var margin: float = clampf(viewport_size.x * 0.014, 8.0, 22.0)
	_title.position = Vector2(margin + 4.0, 10.0)
	_title.size = Vector2(viewport_size.x - margin * 2.0, 34.0)
	var footer_h: float = clampf(viewport_size.y * 0.36, 226.0, 300.0)
	var stage_y: float = 53.0
	var stage_h: float = maxf(120.0, viewport_size.y - footer_h - stage_y - margin * 2.0)
	var portrait: bool = viewport_size.x < viewport_size.y * 0.87
	var frames: Array[Rect2] = []
	if portrait:
		var single_height: float = (stage_h - margin) * 0.5
		frames.append(Rect2(margin, stage_y, viewport_size.x - 2.0 * margin, single_height))
		frames.append(Rect2(margin, stage_y + single_height + margin, viewport_size.x - 2.0 * margin, single_height))
	else:
		var single_width: float = (viewport_size.x - 3.0 * margin) * 0.5
		frames.append(Rect2(margin, stage_y, single_width, stage_h))
		frames.append(Rect2(2.0 * margin + single_width, stage_y, single_width, stage_h))
	for index in range(2):
		var frame: Rect2 = frames[index]
		_stages[index].position = frame.position
		_stages[index].size = frame.size
		_stage_labels[index].position = frame.position + Vector2(14.0, 8.0)
		_stage_labels[index].size = Vector2(frame.size.x - 28.0, 27.0)
		var actor: MikaBubbleBrain = _original if index == 0 else _experimental
		if is_instance_valid(actor):
			actor.position = frame.position + Vector2(frame.size.x * 0.5, frame.size.y * 0.56)
			var sc: float = clampf(minf(frame.size.x / 520.0, (frame.size.y - 28.0) / 510.0), 0.23, 1.20)
			actor.scale = Vector2.ONE * sc
	_controls.position = Vector2(margin, viewport_size.y - footer_h - margin)
	_controls.size = Vector2(viewport_size.x - 2.0 * margin, footer_h)
	var panel_width: float = _controls.size.x
	_toolbar_scroll.position = Vector2(12.0, 8.0)
	_toolbar_scroll.size = Vector2(panel_width - 24.0, 43.0)
	# On small phones the toolbar can be scrolled horizontally; no clipping of controls.
	var compact: bool = panel_width < 710.0
	for b in _toolbar.get_children():
		if b is Button:
			(b as Button).custom_minimum_size.x = 75.0 if compact else 108.0
	_grid.columns = 4 if panel_width >= 880.0 else (2 if panel_width >= 485.0 else 1)
	_scroll.position = Vector2(12.0, 60.0)
	_scroll.size = Vector2(panel_width - 24.0, footer_h - 97.0)
	_status.position = Vector2(13.0, footer_h - 31.0)
	_status.size = Vector2(panel_width - 26.0, 23.0)

func _load_settings() -> void:
	var loaded: Variant = null
	if FileAccess.file_exists(SAVE_FILE):
		loaded = JSON.parse_string(FileAccess.get_file_as_string(SAVE_FILE))
	var saved: Dictionary = loaded if loaded is Dictionary else {}
	_loading = true
	for id in DEFAULTS.keys():
		var value: float = float(saved.get(id, DEFAULTS[id]))
		var slider: HSlider = _sliders[id] as HSlider
		slider.value = clampf(value, slider.min_value, slider.max_value)
		_values[id] = slider.value
	_yaw_angle = float(_values["yaw"])
	_auto_turn.button_pressed = bool(saved.get("auto_turn", true))
	_show_points.button_pressed = bool(saved.get("show_points", true))
	var expr: String = str(saved.get("expression", "calm"))
	_expression.select(maxi(0, EXPRESSIONS.find(expr)))
	_loading = false

func _save_settings() -> void:
	var data: Dictionary = _values.duplicate(true)
	data["auto_turn"] = _auto_turn.button_pressed
	data["show_points"] = _show_points.button_pressed
	data["expression"] = EXPRESSIONS[_expression.selected] if _expression.selected >= 0 else "calm"
	var f: FileAccess = FileAccess.open(SAVE_FILE, FileAccess.WRITE)
	if f == null:
		_status.text = "Не удалось сохранить настройки: " + str(FileAccess.get_open_error())
		return
	f.store_string(JSON.stringify(data, "\t"))
	f.close()
	_status.text = "Настройки сохранены: user://mika_bubble_face_lab.json"

func _reset_values() -> void:
	_loading = true
	for id in DEFAULTS.keys():
		var slider: HSlider = _sliders[id] as HSlider
		slider.value = float(DEFAULTS[id])
		_values[id] = slider.value
	_yaw_angle = 0.0
	_auto_turn.button_pressed = false
	_show_points.button_pressed = true
	_expression.select(0)
	_loading = false
	_apply_values()
	_status.text = "Настройки возвращены к исходным (на диске остаётся последняя сохранённая версия)."

func _unhandled_key_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_ESCAPE:
		get_tree().quit()
