extends Control
## User-facing laboratory: pick one of six movements or autoplay all.
## Motion is deliberately separated from the procedural creature pose.

const ACTION_IDS: Array[String] = [
    "walk_forward", "walk_backward", "strafe_left", "strafe_right", "accelerate", "brake"
]
const TITLES: Array[String] = [
    "1. Вперёд", "2. Назад", "3. Влево", "4. Вправо", "5. Ускорение", "6. Торможение"
]
const DETAILS: Array[String] = [
    "Попеременные шаги нижних пузырей.\nМягкий вертикальный толчок и пружинная инерция.",
    "Осторожное движение назад лицом к зрителю.\nКороче шаг, меньше амплитуда и наклон назад.",
    "Боковое смещение влево.\nПеренос веса и скользящая боковая опора.",
    "Боковое смещение вправо.\nЗеркальный перенос веса; лицо остаётся спереди.",
    "Плавный набор скорости.\nТело вытягивается, задние пузыри запаздывают.",
    "Резкое начало торможения, затем мягкая остановка.\nКорпус сжимается, боковые пузыри перелетают вперёд."
]
const DURATIONS: Array[float] = [4.5, 4.5, 4.3, 4.3, 4.6, 4.2]

@onready var backdrop: Node2D = $Backdrop
@onready var track: Node2D = $Track
@onready var bubble: MikaBubbleMovement = $Bubble
@onready var hud: CanvasLayer = $HUD

var current_index: int = 0
var elapsed: float = 0.0
var delay: float = 0.0
var finished: bool = false
var auto_demo: bool = true
var paused: bool = false
var playback_rate: float = 1.0
var left_x: float = 500.0
var right_x: float = 1300.0
var stage_y: float = 470.0
var bubble_scale: float = 0.73
var _mode_buttons: Array[Button] = []
var _auto_check: CheckButton
var _pause_button: Button
var _status: Label
var _details: Label
var _progress: ProgressBar
var _rate_text: Label
var _gait_text: Label
var _spring_text: Label

func _ready() -> void:
    _build_ui()
    get_viewport().size_changed.connect(_layout_stage)
    _layout_stage()
    _start_motion(0)

func _process(delta: float) -> void:
    if paused:
        return
    var dt: float = minf(delta, 0.05) * playback_rate
    if finished:
        if auto_demo:
            delay += dt
            if delay >= 0.85:
                _start_motion((current_index + 1) % ACTION_IDS.size())
        _update_hud()
        return

    elapsed += dt
    var duration: float = DURATIONS[current_index]
    var p: float = clampf(elapsed / duration, 0.0, 1.0)
    bubble.update_drive(p, elapsed < duration)
    _update_actor_position(p)
    if elapsed >= duration:
        elapsed = duration
        finished = true
        bubble.update_drive(1.0, false)
    _update_hud()

func _layout_stage() -> void:
    var screen: Vector2 = get_viewport_rect().size
    bubble_scale = clampf(minf(screen.x / 1580.0, screen.y / 900.0), 0.46, 0.73)
    stage_y = screen.y * 0.525
    var left_safe: float = 364.0 + 220.0 * bubble_scale + 20.0
    var right_safe: float = screen.x - 220.0 * bubble_scale - 36.0
    left_x = left_safe
    right_x = maxf(left_x + 90.0, right_safe)
    bubble.scale = Vector2.ONE * bubble_scale
    var duration: float = DURATIONS[current_index]
    _update_actor_position(clampf(elapsed / duration, 0.0, 1.0))
    backdrop.queue_redraw()

func _start_motion(index: int) -> void:
    current_index = posmod(index, ACTION_IDS.size())
    elapsed = 0.0
    delay = 0.0
    finished = false
    bubble.restart_motion(ACTION_IDS[current_index])
    bubble.update_drive(0.0, true)
    _update_actor_position(0.0)
    _update_hud()

func _update_actor_position(p: float) -> void:
    var act: String = ACTION_IDS[current_index]
    var t: float = p
    match act:
        "accelerate":
            # Quadratic displacement: beginning slow, ending fast.
            t = pow(p, 2.25)
        "brake":
            # Most distance in the first ~2 seconds, then a full stop.
            var u: float = minf(p / 0.57, 1.0)
            t = 1.0 - pow(1.0 - u, 3.0)
    var backwards: bool = act == "walk_backward" or act == "strafe_left"
    bubble.position = Vector2(lerpf(right_x, left_x, t) if backwards else lerpf(left_x, right_x, t), stage_y)
    track.call("refresh", left_x, right_x, stage_y + 195.0 * bubble_scale, bubble.position.x, bubble_scale, p, act)

func _build_ui() -> void:
    var panel := PanelContainer.new()
    panel.position = Vector2(18.0, 17.0)
    panel.custom_minimum_size = Vector2(328.0, 0.0)
    var st := StyleBoxFlat.new()
    st.bg_color = Color(0.040, 0.084, 0.15, 0.95)
    st.border_color = Color(0.31, 0.56, 0.73, 0.65)
    st.set_border_width_all(1)
    st.set_corner_radius_all(18)
    st.set_content_margin_all(17)
    panel.add_theme_stylebox_override("panel", st)
    hud.add_child(panel)

    var stack := VBoxContainer.new()
    stack.add_theme_constant_override("separation", 9)
    panel.add_child(stack)

    var title := Label.new()
    title.text = "БАББЛ  /  ПЕРЕМЕЩЕНИЕ"
    title.add_theme_font_size_override("font_size", 21)
    title.add_theme_color_override("font_color", Color("b9eafd"))
    stack.add_child(title)

    var sub := Label.new()
    sub.text = "6 вариантов · 5 независимых пузырей\nМордочка пока не анимируется"
    sub.add_theme_font_size_override("font_size", 13)
    sub.add_theme_color_override("font_color", Color("a8bfd1"))
    stack.add_child(sub)

    var modes := GridContainer.new()
    modes.columns = 2
    modes.add_theme_constant_override("h_separation", 7)
    modes.add_theme_constant_override("v_separation", 7)
    stack.add_child(modes)
    for i in range(ACTION_IDS.size()):
        var b := Button.new()
        b.text = TITLES[i]
        b.toggle_mode = true
        b.custom_minimum_size = Vector2(142.0, 40.0)
        b.add_theme_font_size_override("font_size", 14)
        b.pressed.connect(_select_mode.bind(i))
        _mode_buttons.append(b)
        modes.add_child(b)

    _status = Label.new()
    _status.add_theme_font_size_override("font_size", 15)
    _status.add_theme_color_override("font_color", Color("9ef0d1"))
    stack.add_child(_status)

    _details = Label.new()
    _details.custom_minimum_size.y = 56.0
    _details.add_theme_font_size_override("font_size", 13)
    _details.add_theme_color_override("font_color", Color("c1d5e5"))
    stack.add_child(_details)

    _progress = ProgressBar.new()
    _progress.min_value = 0.0
    _progress.max_value = 100.0
    _progress.show_percentage = false
    _progress.custom_minimum_size.y = 9.0
    stack.add_child(_progress)

    stack.add_child(HSeparator.new())
    _rate_text = _add_slider(stack, "Скорость демонстрации: 1.00×", 0.5, 1.75, 1.0, _set_rate)
    _gait_text = _add_slider(stack, "Амплитуда походки: 1.00×", 0.4, 2.0, 1.0, _set_gait)
    _spring_text = _add_slider(stack, "Упругость пузырей: 1.00×", 0.4, 2.0, 1.0, _set_spring)

    _auto_check = CheckButton.new()
    _auto_check.text = "Автоматически: все 6 по очереди"
    _auto_check.button_pressed = true
    _auto_check.toggled.connect(_set_auto)
    stack.add_child(_auto_check)

    var row := HBoxContainer.new()
    row.add_theme_constant_override("separation", 6)
    stack.add_child(row)
    _pause_button = Button.new()
    _pause_button.text = "Пауза"
    _pause_button.custom_minimum_size.x = 83.0
    _pause_button.pressed.connect(_toggle_pause)
    row.add_child(_pause_button)
    var reset := Button.new()
    reset.text = "Повторить"
    reset.pressed.connect(_repeat)
    row.add_child(reset)
    var next_button := Button.new()
    next_button.text = "Следующее"
    next_button.pressed.connect(_next)
    row.add_child(next_button)

    var note := Label.new()
    note.text = "1–6 — выбрать   ·   Space — пауза\nR — повторить   ·   N — следующее\nGodot 4.7.1 · без установки движка"
    note.add_theme_font_size_override("font_size", 12)
    note.add_theme_color_override("font_color", Color("8faabe"))
    stack.add_child(note)

func _add_slider(parent: VBoxContainer, name: String, mn: float, mx: float, current: float, fn: Callable) -> Label:
    var label := Label.new()
    label.text = name
    label.add_theme_font_size_override("font_size", 13)
    parent.add_child(label)
    var slider := HSlider.new()
    slider.min_value = mn
    slider.max_value = mx
    slider.step = 0.05
    slider.value = current
    slider.custom_minimum_size = Vector2(288, 20)
    slider.value_changed.connect(fn)
    parent.add_child(slider)
    return label

func _update_hud() -> void:
    if _status == null:
        return
    var dur: float = DURATIONS[current_index]
    _status.text = "%s  •  %.1f / %.1f с" % ["ПАУЗА" if paused else ("ЗАВЕРШЕНО" if finished else "ДВИЖЕНИЕ"), elapsed, dur]
    _details.text = DETAILS[current_index]
    _progress.value = 100.0 * clampf(elapsed / dur, 0.0, 1.0)
    for i in range(_mode_buttons.size()):
        var b: Button = _mode_buttons[i]
        b.button_pressed = i == current_index
    _pause_button.text = "Продолжить" if paused else "Пауза"

func _select_mode(i: int) -> void:
    auto_demo = false
    _auto_check.button_pressed = false
    _start_motion(i)

func _set_auto(on: bool) -> void:
    auto_demo = on
    if on and finished:
        _start_motion((current_index + 1) % ACTION_IDS.size())

func _set_rate(value: float) -> void:
    playback_rate = value
    bubble.playback_rate = value
    _rate_text.text = "Скорость демонстрации: %.2f×" % value

func _set_gait(value: float) -> void:
    bubble.gait_amplitude = value
    _gait_text.text = "Амплитуда походки: %.2f×" % value

func _set_spring(value: float) -> void:
    bubble.spring_responsiveness = value
    _spring_text.text = "Упругость пузырей: %.2f×" % value

func _toggle_pause() -> void:
    paused = not paused
    bubble.set_process(not paused)
    _update_hud()

func _repeat() -> void:
    _start_motion(current_index)

func _next() -> void:
    _start_motion((current_index + 1) % ACTION_IDS.size())

func _unhandled_key_input(event: InputEvent) -> void:
    if event is InputEventKey and event.pressed and not event.echo:
        match event.keycode:
            KEY_1, KEY_2, KEY_3, KEY_4, KEY_5, KEY_6:
                _select_mode(int(event.keycode - KEY_1))
                get_viewport().set_input_as_handled()
            KEY_SPACE:
                _toggle_pause()
                get_viewport().set_input_as_handled()
            KEY_R:
                _repeat()
                get_viewport().set_input_as_handled()
            KEY_N:
                _next()
                get_viewport().set_input_as_handled()
