extends Control
## Unified workspace: 31 actions + automatic expressions + 10-tooth brushing.

const GROUP_KEYS: Array[String] = ["idle", "movement", "turn", "gesture", "plastic", "care"]
const GROUP_NAMES: Array[String] = ["Покой", "Перемещение", "Повороты", "Жесты", "Пластика", "Уход"]
const GROUP_ACTIONS: Dictionary = {
    "idle": ["idle"],
    "movement": ["walk_forward", "walk_backward", "strafe_left", "strafe_right", "accelerate", "brake"],
    "turn": ["turn_45_left", "turn_45_right", "turn_90_left", "turn_90_right", "turn_180_left", "turn_180_right", "turn_move_left", "turn_move_right"],
    "gesture": ["wave", "jump", "roll", "float", "spin", "look"],
    "plastic": ["detach", "rejoin", "stretch", "contract", "gas", "sleep"],
    "care": ["eat", "drink", "brush_teeth", "bath"]
}
const LABELS: Dictionary = {
    "idle":"Покой · дыхание", "walk_forward":"Идёт вперёд", "walk_backward":"Идёт назад",
    "strafe_left":"Шаг влево", "strafe_right":"Шаг вправо", "accelerate":"Ускорение", "brake":"Торможение",
    "turn_45_left":"Поворот 45° влево", "turn_45_right":"Поворот 45° вправо",
    "turn_90_left":"Поворот 90° влево", "turn_90_right":"Поворот 90° вправо",
    "turn_180_left":"Поворот 180° влево", "turn_180_right":"Поворот 180° вправо",
    "turn_move_left":"Разворот + ходьба влево", "turn_move_right":"Разворот + ходьба вправо",
    "wave":"Махание", "jump":"Прыжок", "roll":"Перекат", "float":"Парение", "spin":"Вращение", "look":"Оглядывание",
    "detach":"Отделение пузырей", "rejoin":"Соединение пузырей", "stretch":"Потягивание", "contract":"Сжатие", "gas":"Выпуск газа", "sleep":"Сон",
    "eat":"Еда из миски", "drink":"Питьё из миски", "brush_teeth":"Чистка зубов", "bath":"Купание в ванне"
}

@onready var bubble: MikaBubbleBrain = $Bubble
@onready var background: Node2D = $Background
@onready var hud: CanvasLayer = $HUD

var _selected_group: String = "care"
var _selected_action: String = "eat"
var _auto_mode: bool = false
var _paused: bool = false
var _wait: float = 0.0
var _idle_time: float = 0.0
var _group_choice: OptionButton
var _action_choice: OptionButton
var _status: Label
var _description: Label
var _rate_title: Label
var _spring_title: Label
var _amount_title: Label
var _progress: ProgressBar
var _pause_button: Button
var _auto_button: CheckButton
var _started: bool = false
var _expression_choice: OptionButton
var _expression_auto: CheckButton
var _face_status: Label
var _teeth_progress: ProgressBar
var _brush_tool: Sprite2D
var _brush_dragging: bool = false
var _brush_offset: Vector2 = Vector2.ZERO
var _brush_last_tip: Vector2 = Vector2.ZERO
var _expression_keys: Array[String] = []
var _preview_brush: bool = false

func _ready() -> void:
    _make_ui()
    get_viewport().size_changed.connect(_update_layout)
    _update_layout()
    bubble.auto_return_idle = false
    bubble.action_finished.connect(_finished_action)
    bubble.face_expression_changed.connect(_on_expression_changed)
    bubble.brush_progress_changed.connect(_on_brush_progress)
    bubble.brush_ready.connect(_on_brush_ready)
    _selected_group = "care"
    _select_group_by_key("care")
    _play("eat")
    _started = true

func _process(delta: float) -> void:
    if not _started or _paused: return
    var dt: float = minf(delta, 0.06)
    if _selected_action == "idle":
        _idle_time += dt
        if _auto_mode and _idle_time > 4.2:
            _next_auto()
    elif bubble.finished and _auto_mode:
        _wait += dt
        if _wait > 1.2:
            _next_auto()
    _update_status()

func _update_layout() -> void:
    var size: Vector2 = get_viewport_rect().size
    if bubble != null and not _started:
        bubble.position = Vector2(size.x * 0.68, size.y * 0.50)
    var base_scale: float = clampf(minf(size.x / 1600.0, size.y / 900.0) * 0.74, 0.46, 0.81)
    bubble.scale = Vector2.ONE * (base_scale * 1.82 if _selected_action == "brush_teeth" else base_scale)
    background.queue_redraw()

func _select_group_by_key(key: String) -> void:
    _selected_group = key
    var idx: int = GROUP_KEYS.find(key)
    if idx >= 0:
        _group_choice.select(idx)
    _fill_actions()

func _fill_actions() -> void:
    _action_choice.clear()
    var ids: Array = GROUP_ACTIONS[_selected_group]
    for id in ids:
        _action_choice.add_item(str(LABELS[id]))
    if ids.size() > 0:
        _action_choice.select(0)

func _on_group_change(index: int) -> void:
    _selected_group = GROUP_KEYS[index]
    _fill_actions()
    _auto_mode = false
    _auto_button.button_pressed = false
    _play(str(GROUP_ACTIONS[_selected_group][0]))

func _on_action_change(index: int) -> void:
    _auto_mode = false
    _auto_button.button_pressed = false
    var ids: Array = GROUP_ACTIONS[_selected_group]
    _play(str(ids[index]))

func _play(id: String) -> void:
    _selected_action = id
    _wait = 0.0
    _idle_time = 0.0
    _brush_dragging = false
    _preview_brush = id == "brush_teeth"
    if is_instance_valid(_brush_tool):
        _brush_tool.visible = _preview_brush
        _brush_tool.position = Vector2(get_viewport_rect().size.x * 0.81, get_viewport_rect().size.y * 0.83)
    if is_instance_valid(_teeth_progress):
        _teeth_progress.value = 0.0
    # Test laboratory start point, not a teleport inside the shared character API.
    bubble.position = Vector2(get_viewport_rect().size.x * 0.67, get_viewport_rect().size.y * 0.50)
    bubble.play_action(id)
    _update_layout()
    _update_status()

func _finished_action(_id: String) -> void:
    _wait = 0.0
    _update_status()

func _next_auto() -> void:
    _wait = 0.0
    _idle_time = 0.0
    var order: Array[String] = MikaBubbleBrain.ACTIONS
    var at: int = order.find(_selected_action)
    var next: String = order[(at + 1) % order.size()]
    # Interactive brushing must not be silently completed by a scripted demo.
    if _auto_mode and next == "brush_teeth":
        next = order[(at + 2) % order.size()]
    _selected_group = bubble.group_for(next)
    _select_group_by_key(_selected_group)
    var group_array: Array = GROUP_ACTIONS[_selected_group]
    _action_choice.select(group_array.find(next))
    _play(next)

func _make_ui() -> void:
    var panel := PanelContainer.new()
    panel.position = Vector2(18, 18)
    panel.custom_minimum_size = Vector2(356, 0)
    var style := StyleBoxFlat.new()
    style.bg_color = Color(0.035, 0.070, 0.135, 0.95)
    style.border_color = Color(0.30, 0.61, 0.77, 0.62)
    style.set_border_width_all(1)
    style.set_corner_radius_all(18)
    style.set_content_margin_all(17)
    panel.add_theme_stylebox_override("panel",style)
    hud.add_child(panel)
    # Scroll vertically; 17-expression controls must fit shorter Mac screens.
    var scroll := ScrollContainer.new()
    scroll.name = "ControlScroll"
    scroll.custom_minimum_size = Vector2(320, 745)
    scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
    scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
    panel.add_child(scroll)
    var stack := VBoxContainer.new()
    stack.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    stack.add_theme_constant_override("separation", 10)
    scroll.add_child(stack)
    var header := Label.new()
    header.text = "БАББЛ  /  СИСТЕМА ПОВЕДЕНИЯ"
    header.add_theme_font_size_override("font_size", 19)
    header.add_theme_color_override("font_color", Color("b4eeff"))
    stack.add_child(header)
    var subtitle := Label.new()
    subtitle.text = "31 действие · 17 эмоций · единый персонаж\nGodot 4.7.1 · уход и мимика вместе"
    subtitle.add_theme_font_size_override("font_size", 12)
    subtitle.add_theme_color_override("font_color", Color("a5bacf"))
    stack.add_child(subtitle)
    var back_room := Button.new()
    back_room.text = "← Интерактивная комната"
    back_room.pressed.connect(func(): get_tree().change_scene_to_file("res://bubble/scenes/interaction_playroom.tscn"))
    stack.add_child(back_room)
    var group_label := Label.new()
    group_label.text = "Группа движений"
    stack.add_child(group_label)
    _group_choice = OptionButton.new()
    _group_choice.custom_minimum_size.y = 38
    for name in GROUP_NAMES: _group_choice.add_item(name)
    _group_choice.item_selected.connect(_on_group_change)
    stack.add_child(_group_choice)
    var action_label := Label.new()
    action_label.text = "Действие"
    stack.add_child(action_label)
    _action_choice = OptionButton.new()
    _action_choice.custom_minimum_size.y = 38
    _action_choice.item_selected.connect(_on_action_change)
    stack.add_child(_action_choice)
    var buttons := HBoxContainer.new()
    buttons.add_theme_constant_override("separation", 7)
    stack.add_child(buttons)
    var run := Button.new()
    run.text = "▶ Запустить"
    run.custom_minimum_size.x = 123
    run.pressed.connect(_repeat)
    buttons.add_child(run)
    _pause_button = Button.new()
    _pause_button.text = "Пауза"
    _pause_button.pressed.connect(_toggle_pause)
    buttons.add_child(_pause_button)
    var next := Button.new()
    next.text = "Следующее"
    next.pressed.connect(_next_manual)
    buttons.add_child(next)
    _auto_button = CheckButton.new()
    _auto_button.text = "Автопоказ (чистка зубов вручную)"
    _auto_button.toggled.connect(_on_auto_changed)
    stack.add_child(_auto_button)
    _status = Label.new()
    _status.add_theme_font_size_override("font_size", 14)
    _status.add_theme_color_override("font_color", Color("98f5d6"))
    stack.add_child(_status)
    _progress = ProgressBar.new()
    _progress.custom_minimum_size.y = 12
    _progress.max_value = 100.0
    _progress.show_percentage = false
    stack.add_child(_progress)
    stack.add_child(HSeparator.new())
    var face_heading := Label.new()
    face_heading.text = "Выражение лица"
    stack.add_child(face_heading)
    _expression_auto = CheckButton.new()
    _expression_auto.text = "Автомимика по действиям"
    _expression_auto.button_pressed = true
    _expression_auto.toggled.connect(_on_expression_auto)
    stack.add_child(_expression_auto)
    _expression_choice = OptionButton.new()
    var data: Variant = JSON.parse_string(FileAccess.get_file_as_string("res://bubble/docs/expression_presets.json"))
    if data is Dictionary:
        var presets: Dictionary = data
        for key in presets.keys():
            _expression_keys.append(str(key))
            _expression_choice.add_item(str(presets[key].get("label", key)))
    _expression_choice.item_selected.connect(_choose_expression)
    stack.add_child(_expression_choice)
    _face_status = Label.new()
    _face_status.add_theme_font_size_override("font_size", 13)
    _face_status.text = "Мимика следует за движением"
    stack.add_child(_face_status)
    var teeth_label := Label.new()
    teeth_label.text = "Очистка зубов (только для действия Чистка зубов)"
    teeth_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    stack.add_child(teeth_label)
    _teeth_progress = ProgressBar.new()
    _teeth_progress.max_value = 100.0
    _teeth_progress.value = 0.0
    _teeth_progress.show_percentage = true
    stack.add_child(_teeth_progress)
    stack.add_child(HSeparator.new())
    _rate_title = _slider(stack,"Темп: 1.00×", 0.5, 2.0, 1.0, _on_rate)
    _spring_title = _slider(stack,"Пружинность: 1.00×", 0.5, 1.75, 1.0, _on_spring)
    _amount_title = _slider(stack,"Выразительность: 1.00×", 0.5, 1.75, 1.0, _on_amount)
    _description = Label.new()
    _description.text = "Чистка: выбери действие, дождись раскрытия рта, возьми щётку и очищай зубы до 92%."
    _description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    _description.custom_minimum_size = Vector2(285, 53)
    _description.add_theme_font_size_override("font_size", 13)
    _description.add_theme_color_override("font_color", Color("b0c9df"))
    stack.add_child(_description)
    var help := Label.new()
    help.text = "Space — пауза   ·   R — повторить\nN — следующее   ·   Esc — выйти"
    help.add_theme_font_size_override("font_size", 12)
    help.add_theme_color_override("font_color", Color("91adc6"))
    stack.add_child(help)
    _brush_tool = Sprite2D.new()
    _brush_tool.name = "InteractiveToothbrush"
    _brush_tool.texture = load("res://bubble/assets/toothbrush.png")
    _brush_tool.scale = Vector2.ONE * 0.65
    _brush_tool.position = Vector2(1270, 738)
    _brush_tool.z_index = 30
    _brush_tool.visible = false
    hud.add_child(_brush_tool)

func _on_expression_auto(enabled: bool) -> void:
    if enabled:
        bubble.clear_expression_override()
        _face_status.text = "Мимика следует за движением"
    elif _expression_choice.item_count > 0:
        _choose_expression(_expression_choice.selected)

func _choose_expression(index: int) -> void:
    if index < 0 or index >= _expression_keys.size():
        return
    _expression_auto.set_pressed_no_signal(false)
    bubble.set_expression(_expression_keys[index])
    _face_status.text = "Ручная эмоция: " + _expression_keys[index]

func _on_expression_changed(id: String) -> void:
    if _expression_auto.button_pressed and is_instance_valid(_face_status):
        _face_status.text = "Автомимика: " + id

func _on_brush_progress(ratio: float) -> void:
    if is_instance_valid(_teeth_progress):
        _teeth_progress.value = ratio * 100.0

func _on_brush_ready() -> void:
    if is_instance_valid(_face_status):
        _face_status.text = "Рот открыт — можно чистить зубы!"

func _input(event: InputEvent) -> void:
    if not _preview_brush or not is_instance_valid(_brush_tool) or _paused:
        return
    if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
        if event.pressed:
            _brush_begin(event.position)
        else:
            _brush_dragging = false
    elif event is InputEventMouseMotion and _brush_dragging:
        _brush_move(event.position)
    elif event is InputEventScreenTouch:
        if event.pressed:
            _brush_begin(event.position)
        else:
            _brush_dragging = false
    elif event is InputEventScreenDrag and _brush_dragging:
        _brush_move(event.position)

func _brush_begin(pointer: Vector2) -> void:
    if not bubble.is_brushing_ready():
        return
    if pointer.distance_to(_brush_tool.position) > 105.0:
        return
    _brush_dragging = true
    _brush_offset = pointer - _brush_tool.position
    _brush_last_tip = _brush_tip()
    get_viewport().set_input_as_handled()

func _brush_tip() -> Vector2:
    return _brush_tool.position + Vector2(-84.0, 0.0)

func _brush_move(pointer: Vector2) -> void:
    var bounds: Vector2 = get_viewport_rect().size
    var target: Vector2 = pointer - _brush_offset
    _brush_tool.position = Vector2(clampf(target.x, 370.0, bounds.x - 15.0), clampf(target.y, 80.0, bounds.y - 22.0))
    var tip: Vector2 = _brush_tip()
    var distance: float = tip.distance_to(_brush_last_tip)
    if distance > 2.0 and bubble.is_brushing_ready():
        var samples: int = mini(40, maxi(1, int(ceil(distance / 4.0))))
        for i in range(1, samples + 1):
            var sample: Vector2 = _brush_last_tip.lerp(tip, float(i) / float(samples))
            bubble.brush_teeth_at(sample, 16.0)
            if not bubble.is_brushing_ready():
                break
        var face_rig: MikaBubbleFace = bubble.get_face()
        if is_instance_valid(face_rig):
            face_rig.set_gaze(Vector2(0.6, 0.55))
    _brush_last_tip = tip
    get_viewport().set_input_as_handled()

func _slider(parent: VBoxContainer, label: String, minimum: float, maximum: float, start: float, callback: Callable) -> Label:
    var title := Label.new()
    title.text = label
    title.add_theme_font_size_override("font_size", 13)
    parent.add_child(title)
    var slide := HSlider.new()
    slide.min_value = minimum
    slide.max_value = maximum
    slide.step = 0.05
    slide.value = start
    slide.custom_minimum_size = Vector2(292,22)
    slide.value_changed.connect(callback)
    parent.add_child(slide)
    return title

func _update_status() -> void:
    if _status == null or bubble == null:return
    var progress: float = bubble.get_progress()
    _status.text = "%s · %s" % [str(LABELS[_selected_action]), ("ПАУЗА" if _paused else ("ГОТОВО" if bubble.finished else "ДВИЖЕНИЕ"))]
    _progress.value = progress * 100.0
    if _selected_action == "brush_teeth":
        _progress.value = bubble.get_brushing_progress() * 100.0
    if is_instance_valid(_brush_tool) and _preview_brush:
        _brush_tool.visible = not bubble.finished
    _pause_button.text = "Продолжить" if _paused else "Пауза"

func _repeat() -> void:
    _play(_selected_action)

func _next_manual() -> void:
    _auto_mode = false
    _auto_button.button_pressed = false
    _next_auto()

func _toggle_pause() -> void:
    _paused = not _paused
    bubble.set_paused(_paused)
    _update_status()

func _on_auto_changed(value: bool) -> void:
    _auto_mode = value
    if _auto_mode and bubble.finished: _next_auto()

func _on_rate(value: float) -> void:
    bubble.set_playback_rate(value)
    _rate_title.text = "Темп: %.2f×" % value

func _on_spring(value: float) -> void:
    bubble.set_plasticity(value)
    _spring_title.text = "Пружинность: %.2f×" % value

func _on_amount(value: float) -> void:
    bubble.set_amplitude(value)
    _amount_title.text = "Выразительность: %.2f×" % value

func _unhandled_key_input(event: InputEvent) -> void:
    if event is InputEventKey and event.pressed and not event.echo:
        match event.keycode:
            KEY_SPACE: _toggle_pause()
            KEY_R: _repeat()
            KEY_N: _next_manual()
            KEY_ESCAPE: get_tree().quit()
