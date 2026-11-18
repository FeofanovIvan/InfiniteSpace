extends Control
## Eight interactive demonstrations from four action families, all local procedural body motion.

const ACTION_IDS: Array[String] = ["turn_45_left", "turn_45_right", "turn_90_left", "turn_90_right", "turn_180_left", "turn_180_right", "turn_move_left", "turn_move_right"]
const TITLES: Array[String] = ["45° налево", "45° направо", "90° налево", "90° направо", "180° налево", "180° направо", "Разворот + влево", "Разворот + вправо"]
const DETAILS: Array[String] = [
    "Лёгкая поправка траектории. Один мягкий перенос опоры.",
    "Лёгкая поправка траектории в противоположную сторону.",
    "Переход в профиль. Две фазы переноса опоры.",
    "Переход в профиль вправо. Боковые пузыри отстают.",
    "Лицо уходит из виду: видим спину пузырчатого тела.",
    "Поворот через другой бок: задний вид и инерция.",
    "Торможение → разворот → шаги влево, единый переход.",
    "Торможение → разворот → шаги вправо, единый переход."
]

@onready var background: Node2D = $Background
@onready var markers: Node2D = $Markers
@onready var bubble: MikaBubbleTurn = $Bubble
@onready var hud: CanvasLayer = $HUD

var current_index: int = 0
var pause: bool = false
var auto_mode: bool = true
var cooldown: float = 0.0
var actor_origin: Vector2 = Vector2.ZERO
var actor_scale: float = 0.74
var world_speed: float = 1.0
var _buttons: Array[Button] = []
var _auto_button: CheckButton
var _pause_button: Button
var _status: Label
var _detail: Label
var _bar: ProgressBar
var _speed_text: Label
var _spring_text: Label
var _amplitude_text: Label

func _ready() -> void:
    bubble.standalone_autoplay = false
    _build_ui()
    get_viewport().size_changed.connect(_layout)
    _layout()
    _start(0)

func _process(delta: float) -> void:
    if pause:
        return
    if bubble.has_finished:
        cooldown += delta * world_speed
        if cooldown > 1.10 and auto_mode:
            _start((current_index + 1) % ACTION_IDS.size())
    else:
        bubble.advance(delta * world_speed)
    _update_position()
    _update_labels()

func _layout() -> void:
    var sz: Vector2 = get_viewport_rect().size
    actor_scale = clampf(minf(sz.x / 1650.0, sz.y / 970.0), 0.45, 0.79)
    actor_origin = Vector2(sz.x * (0.71 if sz.x >= 900 else 0.58), sz.y * 0.52)
    bubble.scale = Vector2.ONE * actor_scale
    _update_position()
    background.queue_redraw()

func _update_position() -> void:
    if bubble == null:
        return
    var move_dir: float = -1.0 if current_index == 6 else 1.0
    var walk_action: bool = current_index >= 6
    var slide: float = bubble.get_movement_fraction() if walk_action else 0.0
    bubble.position = actor_origin + Vector2(move_dir * 280.0 * actor_scale * slide, 0.0)
    markers.call("refresh", bubble.position, actor_origin, bubble.turn_heading, walk_action, move_dir, actor_scale)

func _start(index: int) -> void:
    current_index = posmod(index, ACTION_IDS.size())
    cooldown = 0.0
    bubble.start_turn(ACTION_IDS[current_index])
    _update_position()
    _update_labels()

func _build_ui() -> void:
    var panel := PanelContainer.new()
    panel.position = Vector2(18.0, 18.0)
    panel.custom_minimum_size = Vector2(336.0, 0.0)
    var style := StyleBoxFlat.new()
    style.bg_color = Color(0.033, 0.070, 0.128, 0.96)
    style.border_color = Color(0.30, 0.58, 0.78, 0.74)
    style.set_border_width_all(1)
    style.set_corner_radius_all(18)
    style.set_content_margin_all(17)
    panel.add_theme_stylebox_override("panel", style)
    hud.add_child(panel)

    var v := VBoxContainer.new()
    v.add_theme_constant_override("separation", 8)
    panel.add_child(v)
    var title := Label.new()
    title.text = "БАББЛ  /  ПОВОРОТЫ"
    title.add_theme_font_size_override("font_size", 22)
    title.add_theme_color_override("font_color", Color("b7e9fc"))
    v.add_child(title)
    var desc := Label.new()
    desc.text = "4 типа × 2 стороны = 8 анимаций
Пластика пузырей, поворот корпуса 2.5D
Мимика не меняется"
    desc.add_theme_font_size_override("font_size", 13)
    desc.add_theme_color_override("font_color", Color("a9c4d9"))
    v.add_child(desc)

    var grid := GridContainer.new()
    grid.columns = 2
    grid.add_theme_constant_override("h_separation", 6)
    grid.add_theme_constant_override("v_separation", 7)
    v.add_child(grid)
    for i in range(ACTION_IDS.size()):
        var b := Button.new()
        b.text = TITLES[i]
        b.toggle_mode = true
        b.custom_minimum_size = Vector2(146.0, 39.0)
        b.add_theme_font_size_override("font_size", 13)
        b.pressed.connect(_select.bind(i))
        _buttons.append(b)
        grid.add_child(b)

    _status = Label.new()
    _status.add_theme_font_size_override("font_size", 15)
    _status.add_theme_color_override("font_color", Color("92f1cc"))
    v.add_child(_status)
    _detail = Label.new()
    _detail.custom_minimum_size.y = 46.0
    _detail.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    _detail.add_theme_font_size_override("font_size", 13)
    _detail.add_theme_color_override("font_color", Color("c2d6e6"))
    v.add_child(_detail)
    _bar = ProgressBar.new()
    _bar.min_value = 0.0
    _bar.max_value = 100.0
    _bar.show_percentage = false
    _bar.custom_minimum_size.y = 10.0
    v.add_child(_bar)
    v.add_child(HSeparator.new())

    _speed_text = _add_slider(v, "Темп: 1.00×", 0.5, 2.0, 1.0, _on_speed)
    _spring_text = _add_slider(v, "Упругость пузырей: 1.00×", 0.5, 2.0, 1.0, _on_spring)
    _amplitude_text = _add_slider(v, "Пластика поворота: 1.00×", 0.4, 2.0, 1.0, _on_amplitude)

    _auto_button = CheckButton.new()
    _auto_button.text = "Автопоказ всех поворотов"
    _auto_button.button_pressed = true
    _auto_button.toggled.connect(_on_auto)
    v.add_child(_auto_button)

    var row := HBoxContainer.new()
    row.add_theme_constant_override("separation", 7)
    v.add_child(row)
    _pause_button = Button.new()
    _pause_button.text = "Пауза"
    _pause_button.custom_minimum_size.x = 80.0
    _pause_button.pressed.connect(_on_pause)
    row.add_child(_pause_button)
    var replay := Button.new()
    replay.text = "Повторить"
    replay.pressed.connect(_on_replay)
    row.add_child(replay)
    var next := Button.new()
    next.text = "Следующее"
    next.pressed.connect(_on_next)
    row.add_child(next)

    var notes := Label.new()
    notes.text = "1–8 — режим · Пробел — пауза
R — повторить · N — следующее
Godot 4.7.1 · без автообновлений"
    notes.add_theme_font_size_override("font_size", 12)
    notes.add_theme_color_override("font_color", Color("92adc2"))
    v.add_child(notes)

func _add_slider(parent: VBoxContainer, caption: String, low: float, high: float, value: float, fn: Callable) -> Label:
    var label := Label.new()
    label.text = caption
    label.add_theme_font_size_override("font_size", 13)
    parent.add_child(label)
    var slider := HSlider.new()
    slider.min_value = low
    slider.max_value = high
    slider.step = 0.05
    slider.value = value
    slider.custom_minimum_size = Vector2(288, 22)
    slider.value_changed.connect(fn)
    parent.add_child(slider)
    return label

func _update_labels() -> void:
    if _status == null:
        return
    var status: String = "ПАУЗА" if pause else ("ГОТОВО" if bubble.has_finished else "ПОВОРОТ")
    _status.text = "%s · %+.0f° · %.2f/%.2f с" % [status, bubble.get_turn_degrees(), bubble.elapsed, bubble.duration]
    _detail.text = DETAILS[current_index]
    _bar.value = bubble.turn_progress * 100.0
    for i in range(_buttons.size()):
        _buttons[i].button_pressed = (i == current_index)
    _pause_button.text = "Продолжить" if pause else "Пауза"

func _select(i: int) -> void:
    auto_mode = false
    _auto_button.button_pressed = false
    _start(i)

func _on_auto(on: bool) -> void:
    auto_mode = on
    if auto_mode and bubble.has_finished:
        _start((current_index + 1) % ACTION_IDS.size())

func _on_speed(v: float) -> void:
    world_speed = v
    _speed_text.text = "Темп: %.2f×" % v

func _on_spring(v: float) -> void:
    bubble.spring_responsiveness = v
    _spring_text.text = "Упругость пузырей: %.2f×" % v

func _on_amplitude(v: float) -> void:
    bubble.pose_amplitude = v
    _amplitude_text.text = "Пластика поворота: %.2f×" % v

func _on_pause() -> void:
    pause = not pause
    _update_labels()

func _on_replay() -> void:
    _start(current_index)

func _on_next() -> void:
    _start((current_index + 1) % ACTION_IDS.size())

func _unhandled_key_input(event: InputEvent) -> void:
    if event is InputEventKey and event.pressed and not event.echo:
        match event.keycode:
            KEY_1, KEY_2, KEY_3, KEY_4, KEY_5, KEY_6, KEY_7, KEY_8:
                _select(int(event.keycode - KEY_1))
                get_viewport().set_input_as_handled()
            KEY_SPACE:
                _on_pause()
                get_viewport().set_input_as_handled()
            KEY_R:
                _on_replay()
                get_viewport().set_input_as_handled()
            KEY_N:
                _on_next()
                get_viewport().set_input_as_handled()
