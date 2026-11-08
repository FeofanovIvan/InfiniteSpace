extends Control
## Single-action visual laboratory for idle. All controls are optional for gameplay.

@onready var background: Node2D = $Background
@onready var bubble: MikaBubbleIdle = $Bubble
@onready var hud: CanvasLayer = $Hud

var _paused: bool = false
var _pause_button: Button
var _status: Label
var _speed_label: Label
var _breath_label: Label
var _motion_label: Label
var _spring_label: Label

func _ready() -> void:
    _create_hud()
    get_viewport().size_changed.connect(_layout_stage)
    _layout_stage()

func _process(_delta: float) -> void:
    if _status != null:
        var state: String = "ПАУЗА" if _paused else bubble.get_breath_label().to_upper()
        _status.text = "%s  •  %.1f с  •  %s" % [state, bubble.elapsed, "покой / idle"]

func _layout_stage() -> void:
    var sz: Vector2 = get_viewport_rect().size
    var center_x: float = sz.x * (0.66 if sz.x >= 950.0 else 0.52)
    var center_y: float = sz.y * 0.53
    var s: float = clampf(minf(sz.x / 1450.0, sz.y / 950.0), 0.43, 0.88)
    bubble.position = Vector2(center_x, center_y)
    bubble.scale = Vector2.ONE * s
    background.queue_redraw()

func _create_hud() -> void:
    var panel := PanelContainer.new()
    panel.position = Vector2(22.0, 22.0)
    panel.custom_minimum_size = Vector2(318.0, 0.0)
    var style := StyleBoxFlat.new()
    style.bg_color = Color(0.055, 0.105, 0.18, 0.94)
    style.border_color = Color(0.25, 0.55, 0.72, 0.58)
    style.set_border_width_all(1)
    style.set_corner_radius_all(18)
    style.set_content_margin_all(18)
    panel.add_theme_stylebox_override("panel", style)
    hud.add_child(panel)

    var v := VBoxContainer.new()
    v.add_theme_constant_override("separation", 10)
    panel.add_child(v)

    var title := Label.new()
    title.text = "БАББЛ  /  01. ПОКОЙ"
    title.add_theme_font_size_override("font_size", 22)
    title.add_theme_color_override("font_color", Color("c0e9ff"))
    v.add_child(title)

    var description := Label.new()
    description.text = "Спокойное дыхание • мягкий перенос веса\n5 связанных пузырей с инерцией\nМордочка без анимации"
    description.add_theme_color_override("font_color", Color("b1c5d8"))
    v.add_child(description)

    _status = Label.new()
    _status.text = "ПОКОЙ  •  0.0 с"
    _status.add_theme_color_override("font_color", Color("94efce"))
    v.add_child(_status)

    var sep := HSeparator.new()
    v.add_child(sep)

    _speed_label = _add_slider(v, "Темп: 1.00×", 0.5, 1.75, 1.0, _on_speed)
    _breath_label = _add_slider(v, "Амплитуда дыхания: 1.00×", 0.0, 2.0, 1.0, _on_breath)
    _motion_label = _add_slider(v, "Подвижность пузырей: 1.00×", 0.0, 2.0, 1.0, _on_motion)
    _spring_label = _add_slider(v, "Упругость связи: 1.00×", 0.5, 2.0, 1.0, _on_spring)

    var check := CheckBox.new()
    check.text = "Редкая смена положения"
    check.button_pressed = true
    check.toggled.connect(_on_reposition_toggled)
    v.add_child(check)

    var buttons := HBoxContainer.new()
    buttons.add_theme_constant_override("separation", 12)
    v.add_child(buttons)
    _pause_button = Button.new()
    _pause_button.text = "Пауза"
    _pause_button.custom_minimum_size.x = 120.0
    _pause_button.pressed.connect(_toggle_pause)
    buttons.add_child(_pause_button)

    var reset_button := Button.new()
    reset_button.text = "Начать заново"
    reset_button.custom_minimum_size.x = 145.0
    reset_button.pressed.connect(_reset)
    buttons.add_child(reset_button)

    var footnote := Label.new()
    footnote.text = "Пробел — пауза    R — сброс\nGodot 4.7.1  •  только анимация покоя"
    footnote.add_theme_font_size_override("font_size", 12)
    footnote.add_theme_color_override("font_color", Color("8398ab"))
    v.add_child(footnote)

func _add_slider(parent: VBoxContainer, label_text: String, minimum: float, maximum: float, current: float, callback: Callable) -> Label:
    var label := Label.new()
    label.text = label_text
    parent.add_child(label)
    var slider := HSlider.new()
    slider.min_value = minimum
    slider.max_value = maximum
    slider.step = 0.05
    slider.value = current
    slider.custom_minimum_size = Vector2(275, 20)
    slider.value_changed.connect(callback)
    parent.add_child(slider)
    return label

func _on_reposition_toggled(pressed: bool) -> void:
    bubble.subtle_reposition = pressed

func _on_speed(value: float) -> void:
    bubble.time_scale = value
    _speed_label.text = "Темп: %.2f×" % value

func _on_breath(value: float) -> void:
    bubble.breathing_amount = value
    _breath_label.text = "Амплитуда дыхания: %.2f×" % value

func _on_motion(value: float) -> void:
    bubble.satellite_motion = value
    _motion_label.text = "Подвижность пузырей: %.2f×" % value

func _on_spring(value: float) -> void:
    bubble.follower_responsiveness = value
    _spring_label.text = "Упругость связи: %.2f×" % value

func _toggle_pause() -> void:
    _paused = not _paused
    bubble.set_process(not _paused)
    _pause_button.text = "Продолжить" if _paused else "Пауза"

func _reset() -> void:
    bubble.reset_idle()

func _unhandled_key_input(event: InputEvent) -> void:
    if event is InputEventKey and event.pressed and not event.echo:
        if event.keycode == KEY_SPACE:
            _toggle_pause()
            get_viewport().set_input_as_handled()
        elif event.keycode == KEY_R:
            _reset()
            get_viewport().set_input_as_handled()
