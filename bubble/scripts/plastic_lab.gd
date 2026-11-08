extends Control
## Godot 4.7.1 test stage for six independent body-plastic actions.

const IDS: Array[String] = ["detach", "rejoin", "stretch", "contract", "gas", "sleep"]
const TITLES: Array[String] = [
    "1 · Отделение", "2 · Соединение", "3 · Потягивание",
    "4 · Сжатие", "5 · Выпуск газа", "6 · Сон"
]
const DETAILS: Array[String] = [
    "Пять пузырей отделяются от центрального тела и продолжают плавать рядом, не теряя формы.",
    "Пять самостоятельных шариков поочерёдно приближаются к центру и снова становятся единым телом.",
    "Тело вытягивается по диагонали; верхние и боковые пузыри запаздывают и затем возвращаются.",
    "Баббл собирается в маленький упругий клубок, удерживает форму и раскрывается с отскоком.",
    "Корпус надувается, выпускает газовые пузырьки и мягко отскакивает от реактивного толчка.",
    "Пузырчатая масса расслабляется, опускается и распластывается в спокойной позе для сна."
]

@onready var bg: Node2D = $Background
@onready var markers: Node2D = $Markers
@onready var bubble: MikaBubblePlastic = $Bubble
@onready var hud: CanvasLayer = $HUD

var current: int = 0
var paused: bool = false
var automatic: bool = true
var cooldown: float = 0.0
var world_rate: float = 1.0
var origin: Vector2 = Vector2.ZERO
var char_scale: float = 0.78
var buttons: Array[Button] = []
var auto_toggle: CheckButton
var pause_btn: Button
var status_lbl: Label
var description_lbl: Label
var progress_bar: ProgressBar
var speed_lbl: Label
var spring_lbl: Label
var amplitude_lbl: Label

func _ready() -> void:
    bubble.standalone_autoplay = false
    _build_controls()
    get_viewport().size_changed.connect(_relayout)
    _relayout()
    _start(0)

func _process(delta: float) -> void:
    if paused:
        return
    if bubble.has_finished:
        bubble.hold_pose(delta * world_rate)
        cooldown += delta * world_rate
        if cooldown > 1.5 and automatic:
            _start((current + 1) % IDS.size())
    else:
        bubble.advance(delta * world_rate)
    _place_actor()
    _update_status()

func _relayout() -> void:
    var sz: Vector2 = get_viewport_rect().size
    char_scale = clampf(minf(sz.x / 1600.0, sz.y / 900.0) * 0.83, 0.42, 0.83)
    origin = Vector2(sz.x * 0.66, sz.y * 0.53)
    bubble.scale = Vector2.ONE * char_scale
    _place_actor()
    bg.queue_redraw()

func _place_actor() -> void:
    bubble.position = origin
    markers.call("refresh", bubble.position, char_scale, IDS[current])

func _start(index: int) -> void:
    current = posmod(index, IDS.size())
    cooldown = 0.0
    bubble.start_action(IDS[current])
    _place_actor()
    _update_status()

func _build_controls() -> void:
    var panel := PanelContainer.new()
    panel.position = Vector2(20.0, 20.0)
    panel.custom_minimum_size = Vector2(382.0, 0.0)
    var style := StyleBoxFlat.new()
    style.bg_color = Color(0.035, 0.074, 0.134, 0.97)
    style.border_color = Color(0.32, 0.60, 0.82, 0.66)
    style.set_border_width_all(1)
    style.set_corner_radius_all(18)
    style.set_content_margin_all(18)
    panel.add_theme_stylebox_override("panel", style)
    hud.add_child(panel)
    var layout := VBoxContainer.new()
    layout.add_theme_constant_override("separation", 9)
    panel.add_child(layout)
    var heading := Label.new()
    heading.text = "БАББЛ  /  ПЛАСТИКА ТЕЛА"
    heading.add_theme_font_size_override("font_size", 21)
    heading.add_theme_color_override("font_color", Color("b6e8fc"))
    layout.add_child(heading)
    var sub := Label.new()
    sub.text = "6 анимаций · Godot 4.7.1"
    sub.add_theme_font_size_override("font_size", 13)
    sub.add_theme_color_override("font_color", Color("a9c6db"))
    layout.add_child(sub)
    var grid := GridContainer.new()
    grid.columns = 2
    grid.add_theme_constant_override("h_separation", 7)
    grid.add_theme_constant_override("v_separation", 7)
    layout.add_child(grid)
    for i in range(IDS.size()):
        var btn := Button.new()
        btn.text = TITLES[i]
        btn.custom_minimum_size = Vector2(161.0, 44.0)
        btn.toggle_mode = true
        btn.add_theme_font_size_override("font_size", 14)
        btn.pressed.connect(_select.bind(i))
        buttons.append(btn)
        grid.add_child(btn)
    status_lbl = Label.new()
    status_lbl.add_theme_font_size_override("font_size", 15)
    status_lbl.add_theme_color_override("font_color", Color("93f2d2"))
    layout.add_child(status_lbl)
    description_lbl = Label.new()
    description_lbl.custom_minimum_size = Vector2(330.0, 70.0)
    description_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    description_lbl.add_theme_font_size_override("font_size", 13)
    description_lbl.add_theme_color_override("font_color", Color("c7dae9"))
    layout.add_child(description_lbl)
    progress_bar = ProgressBar.new()
    progress_bar.show_percentage = false
    progress_bar.max_value = 100.0
    progress_bar.custom_minimum_size.y = 10.0
    layout.add_child(progress_bar)
    layout.add_child(HSeparator.new())
    speed_lbl = _slider(layout, "Скорость: 1.00×", 0.50, 2.00, 1.0, _set_speed)
    spring_lbl = _slider(layout, "Упругость: 1.00×", 0.45, 1.95, 1.0, _set_spring)
    amplitude_lbl = _slider(layout, "Пластичность: 1.00×", 0.50, 1.60, 1.0, _set_amplitude)
    auto_toggle = CheckButton.new()
    auto_toggle.text = "Автопоказ всех шести действий"
    auto_toggle.button_pressed = true
    auto_toggle.toggled.connect(_set_auto)
    layout.add_child(auto_toggle)
    var row := HBoxContainer.new()
    row.add_theme_constant_override("separation", 7)
    layout.add_child(row)
    pause_btn = Button.new()
    pause_btn.text = "Пауза"
    pause_btn.pressed.connect(_toggle_pause)
    row.add_child(pause_btn)
    var replay := Button.new()
    replay.text = "Повторить"
    replay.pressed.connect(_replay)
    row.add_child(replay)
    var next_btn := Button.new()
    next_btn.text = "Следующее"
    next_btn.pressed.connect(_next)
    row.add_child(next_btn)
    var shortcuts := Label.new()
    shortcuts.text = "1–6: действие   Space: пауза   R: повтор   N: дальше"
    shortcuts.add_theme_font_size_override("font_size", 12)
    shortcuts.add_theme_color_override("font_color", Color("91acc2"))
    layout.add_child(shortcuts)
    var disclaimer := Label.new()
    disclaimer.text = "Мимика сохранена. Новые PNG не требуются."
    disclaimer.add_theme_font_size_override("font_size", 12)
    disclaimer.add_theme_color_override("font_color", Color("91acc2"))
    layout.add_child(disclaimer)

func _slider(parent: VBoxContainer, caption: String, bottom: float, top: float, v: float, fn: Callable) -> Label:
    var label := Label.new()
    label.text = caption
    label.add_theme_font_size_override("font_size", 13)
    parent.add_child(label)
    var slider := HSlider.new()
    slider.min_value = bottom
    slider.max_value = top
    slider.step = 0.05
    slider.value = v
    slider.custom_minimum_size = Vector2(335.0, 20.0)
    slider.value_changed.connect(fn)
    parent.add_child(slider)
    return label

func _update_status() -> void:
    if status_lbl == null:
        return
    var state: String = "ПАУЗА" if paused else ("ЗАВЕРШЕНО" if bubble.has_finished else bubble.current_stage)
    status_lbl.text = "%s  •  %.2f / %.2f с" % [state, bubble.elapsed, bubble.duration]
    description_lbl.text = DETAILS[current]
    progress_bar.value = bubble.progress * 100.0
    for i in range(buttons.size()):
        buttons[i].button_pressed = i == current
    pause_btn.text = "Продолжить" if paused else "Пауза"

func _select(i: int) -> void:
    automatic = false
    auto_toggle.button_pressed = false
    _start(i)

func _set_speed(v: float) -> void:
    world_rate = v
    speed_lbl.text = "Скорость: %.2f×" % v

func _set_spring(v: float) -> void:
    bubble.spring_responsiveness = v
    spring_lbl.text = "Упругость: %.2f×" % v

func _set_amplitude(v: float) -> void:
    bubble.pose_amplitude = v
    amplitude_lbl.text = "Пластичность: %.2f×" % v

func _set_auto(v: bool) -> void:
    automatic = v
    if v and bubble.has_finished:
        _start((current + 1) % IDS.size())

func _toggle_pause() -> void:
    paused = not paused
    _update_status()

func _replay() -> void:
    _start(current)

func _next() -> void:
    _start((current + 1) % IDS.size())

func _unhandled_key_input(e: InputEvent) -> void:
    if e is InputEventKey and e.pressed and not e.echo:
        match e.keycode:
            KEY_1, KEY_2, KEY_3, KEY_4, KEY_5, KEY_6:
                _select(int(e.keycode - KEY_1))
                get_viewport().set_input_as_handled()
            KEY_SPACE:
                _toggle_pause()
                get_viewport().set_input_as_handled()
            KEY_R:
                _replay()
                get_viewport().set_input_as_handled()
            KEY_N:
                _next()
                get_viewport().set_input_as_handled()
