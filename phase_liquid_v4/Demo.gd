extends Control
## Click buttons or the creature to see the tentacles merge and reappear elsewhere.
const CREATURE: PackedScene = preload("res://phase_liquid_v4/PhaseLiquid3D.tscn")
const INK: Color = Color("071326")
const ACCENT: Color = Color("8ddff5")
const SUBTLE: Color = Color("b2c8e0")
var creature
var status: Label

func _ready() -> void:
    var background := ColorRect.new()
    background.color = INK
    background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    background.mouse_filter = Control.MOUSE_FILTER_IGNORE
    add_child(background)

    var margin := MarginContainer.new()
    margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    margin.add_theme_constant_override("margin_left", 18)
    margin.add_theme_constant_override("margin_right", 18)
    margin.add_theme_constant_override("margin_top", 18)
    margin.add_theme_constant_override("margin_bottom", 18)
    add_child(margin)
    var columns := HBoxContainer.new()
    columns.add_theme_constant_override("separation", 22)
    margin.add_child(columns)

    var stage := PanelContainer.new()
    stage.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    stage.size_flags_stretch_ratio = 1.75
    stage.add_theme_stylebox_override("panel", _panel(Color("102743")))
    columns.add_child(stage)
    var stage_layout := VBoxContainer.new()
    stage_layout.add_theme_constant_override("separation", 6)
    stage.add_child(stage_layout)
    var header := _label("MIKA  /  PHASE LIQUID  /  3D → 2D  /  v4", 19, ACCENT)
    header.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    stage_layout.add_child(header)
    var center := CenterContainer.new()
    center.size_flags_vertical = Control.SIZE_EXPAND_FILL
    center.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    stage_layout.add_child(center)
    creature = CREATURE.instantiate()
    creature.high_quality = true
    creature.custom_minimum_size = Vector2(365, 480)
    center.add_child(creature)
    var stage_hint := _label("Одно тело • живые сливающиеся языки • тяжёлый низ", 14, SUBTLE)
    stage_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    stage_layout.add_child(stage_hint)

    var scroll := ScrollContainer.new()
    scroll.custom_minimum_size = Vector2(336, 0)
    scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
    columns.add_child(scroll)
    var controls := VBoxContainer.new()
    controls.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    controls.add_theme_constant_override("separation", 10)
    scroll.add_child(controls)
    controls.add_child(_label("Жидкое фазовое существо", 24, Color.WHITE))
    controls.add_child(_label("Версия 4: усиленная геометрическая рябь, спиральные волны и ускоренные слияния.", 16, SUBTLE))
    status = _label("Режим: спокойствие", 15, ACCENT)
    controls.add_child(status)
    var modes := GridContainer.new()
    modes.columns = 2
    controls.add_child(modes)
    _mode_button(modes, "Спокойствие", "idle")
    _mode_button(modes, "Тихая речь", "talk_soft")
    _mode_button(modes, "Активная речь", "talk_active")
    _mode_button(modes, "Сильная эмоция", "emotion_peak")
    controls.add_child(_label("При переключении режима изменения формы плавные. Нажми на существо для краткой реакции.", 13, SUBTLE))
    _slider(controls, "Сила перестройки формы", 1.18, 0.0, 2.0, func(v: float) -> void: creature.set_morph(v))
    _slider(controls, "Вытягивание / слияние", 1.24, 0.0, 1.8, func(v: float) -> void: creature.set_lobes(v))
    _slider(controls, "Бегущая рябь (геометрия)", 0.61, 0.0, 1.3, func(v: float) -> void: creature.set_ripples(v))
    _slider(controls, "Пузыревидные утолщения", 0.64, 0.0, 1.4, func(v: float) -> void: creature.set_bubbles(v))
    _slider(controls, "Спираль", 1.08, 0.0, 1.6, func(v: float) -> void: creature.set_spiral(v))
    _slider(controls, "Скорость перетекания", 1.35, 0.2, 3.0, func(v: float) -> void: creature.set_flow(v))
    _slider(controls, "Тяжесть нижней части", 1.03, 0.6, 1.5, func(v: float) -> void: creature.set_gravity(v))
    _slider(controls, "Свечение", 1.18, 0.0, 2.5, func(v: float) -> void: creature.set_glow(v))
    _slider(controls, "Прозрачность поверхности", 0.96, 0.75, 1.0, func(v: float) -> void: creature.set_opacity(v))
    controls.add_child(_label("Только жидкая форма. Весь рельеф — на одном замкнутом теле.", 13, SUBTLE))

func _mode_button(parent: Node, caption: String, mode: String) -> void:
    var btn := Button.new()
    btn.text = caption
    btn.custom_minimum_size = Vector2(158, 44)
    btn.pressed.connect(func() -> void:
        creature.set_speech_state(mode)
        status.text = "Режим: " + caption
    )
    parent.add_child(btn)

func _slider(parent: VBoxContainer, caption: String, value: float, min_v: float, max_v: float, callback: Callable) -> void:
    var group := VBoxContainer.new()
    group.add_theme_constant_override("separation", 2)
    group.add_child(_label(caption, 15, Color.WHITE))
    var slider := HSlider.new()
    slider.min_value = min_v
    slider.max_value = max_v
    slider.step = 0.01
    slider.value = value
    slider.custom_minimum_size = Vector2(300, 27)
    slider.value_changed.connect(callback)
    group.add_child(slider)
    parent.add_child(group)

func _label(message: String, font_size: int, tint: Color) -> Label:
    var l := Label.new()
    l.text = message
    l.add_theme_font_size_override("font_size", font_size)
    l.add_theme_color_override("font_color", tint)
    l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    return l

func _panel(color: Color) -> StyleBoxFlat:
    var p := StyleBoxFlat.new()
    p.bg_color = color
    p.border_color = Color("2e5371")
    p.set_corner_radius_all(20)
    p.set_border_width_all(1)
    return p
