extends Control
## Square STOP replaces the joystick for the whole autopilot flight.
## Touch and mouse behaviour mirrors the original joystick hit target.
signal stop_requested()

const CENTER: Vector2 = Vector2(92.0, 92.0)
const HIT_RADIUS: float = 84.0
var _touch_id: int = -1
var _mouse_down: bool = false


func _ready() -> void:
    size = Vector2(184.0, 184.0)
    mouse_filter = Control.MOUSE_FILTER_IGNORE
    visible = false
    var caption: Label = Label.new()
    caption.text = "СТОП"
    caption.position = Vector2(47.0, 127.0)
    caption.size = Vector2(90.0, 24.0)
    caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    caption.mouse_filter = Control.MOUSE_FILTER_IGNORE
    caption.add_theme_font_size_override("font_size", 16)
    caption.add_theme_color_override("font_color", Color(0.82, 0.96, 1.0))
    add_child(caption)
    queue_redraw()


func _input(event: InputEvent) -> void:
    if not is_visible_in_tree():
        _touch_id = -1
        _mouse_down = false
        return
    if event is InputEventScreenTouch:
        if event.pressed and _touch_id < 0 and _contains(event.position):
            _touch_id = event.index
            get_viewport().set_input_as_handled()
        elif not event.pressed and _touch_id == event.index:
            _touch_id = -1
            if _contains(event.position):
                stop_requested.emit()
            get_viewport().set_input_as_handled()
    elif event is InputEventScreenDrag and event.index == _touch_id:
        get_viewport().set_input_as_handled()
    elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
        if event.pressed and _contains(event.position):
            _mouse_down = true
            get_viewport().set_input_as_handled()
        elif not event.pressed and _mouse_down:
            _mouse_down = false
            if _contains(event.position):
                stop_requested.emit()
            get_viewport().set_input_as_handled()
    elif event is InputEventMouseMotion and _mouse_down:
        get_viewport().set_input_as_handled()


func _contains(screen_point: Vector2) -> bool:
    var local_point: Vector2 = get_global_transform_with_canvas().affine_inverse() * screen_point
    return local_point.distance_to(CENTER) <= HIT_RADIUS


func _draw() -> void:
    draw_circle(CENTER, 83.0, Color(0.025, 0.12, 0.20, 0.70))
    draw_circle(CENTER, 68.0, Color(0.055, 0.25, 0.38, 0.94))
    draw_arc(CENTER, 68.0, 0.0, TAU, 64, Color(0.51, 0.89, 1.0, 0.86), 2.4, true)
    draw_rect(Rect2(CENTER - Vector2(23.0, 23.0), Vector2(46.0, 46.0)), Color(0.91, 0.98, 1.0), true)
    draw_rect(Rect2(CENTER - Vector2(23.0, 23.0), Vector2(46.0, 46.0)), Color(0.42, 0.82, 1.0), false, 2.0)
