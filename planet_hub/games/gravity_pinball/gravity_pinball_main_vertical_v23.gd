extends "res://scripts/Joystick.gd"
## Exact main-flight circular joystick base; only vertical Y motion is enabled.
## Aim persists after finger release, so the other hand can hold the launch button.
signal value_changed(value: float)

var value: float = 0.50


func setup(initial_value: float) -> void:
    set_value_silently(initial_value)


func set_value_silently(next_value: float) -> void:
    value = clampf(next_value, 0.0, 1.0)
    direction = Vector2(0.0, value * 2.0 - 1.0)
    queue_redraw()


func clear_input() -> void:
    _touch_id = -1
    _mouse_down = false
    set_value_silently(0.50)


func _notification(what: int) -> void:
    if what == NOTIFICATION_WM_WINDOW_FOCUS_OUT or what == NOTIFICATION_APPLICATION_PAUSED:
        _touch_id = -1
        _mouse_down = false


func _input(event: InputEvent) -> void:
    if not is_visible_in_tree():
        return
    if event is InputEventScreenTouch:
        var touch: InputEventScreenTouch = event as InputEventScreenTouch
        if touch.pressed and _touch_id < 0 and _in_joystick(touch.position):
            _touch_id = touch.index
            _set_from_screen(touch.position)
            get_viewport().set_input_as_handled()
        elif not touch.pressed and _touch_id == touch.index:
            _touch_id = -1
            # Unlike a flight stick, launch aim remains at the selected Y.
            get_viewport().set_input_as_handled()
    elif event is InputEventScreenDrag:
        var drag: InputEventScreenDrag = event as InputEventScreenDrag
        if drag.index == _touch_id:
            _set_from_screen(drag.position)
            get_viewport().set_input_as_handled()
    elif event is InputEventMouseButton:
        var mouse: InputEventMouseButton = event as InputEventMouseButton
        if mouse.button_index != MOUSE_BUTTON_LEFT:
            return
        if mouse.pressed and not _mouse_down and _in_joystick(mouse.position):
            _mouse_down = true
            _set_from_screen(mouse.position)
            get_viewport().set_input_as_handled()
        elif not mouse.pressed and _mouse_down:
            _mouse_down = false
            get_viewport().set_input_as_handled()
    elif event is InputEventMouseMotion and _mouse_down:
        _set_from_screen((event as InputEventMouseMotion).position)
        get_viewport().set_input_as_handled()


func _set_from_screen(screen_point: Vector2) -> void:
    var local: Vector2 = get_global_transform_with_canvas().affine_inverse() * screen_point
    var y: float = clampf((local.y - size.y * 0.5) / STICK_RADIUS, -1.0, 1.0)
    if absf(value - (y + 1.0) * 0.5) < 0.0001:
        return
    value = (y + 1.0) * 0.5
    direction = Vector2(0.0, y)  # no sideways movement under any touch position
    direction_changed.emit(direction)
    value_changed.emit(value)
    queue_redraw()


func _draw() -> void:
    var center: Vector2 = size * 0.5
    # Original circles and colors from scripts/Joystick.gd, unchanged.
    draw_circle(center, 83.0, Color(0.02, 0.10, 0.18, 0.36))
    draw_circle(center, 67.0, Color(0.04, 0.17, 0.28, 0.43))
    draw_arc(center, 67.0, 0.0, TAU, 64, Color(0.38, 0.80, 1.0, 0.42), 2.0, true)
    draw_arc(center, 49.0, 0.0, TAU, 64, Color(0.18, 0.51, 0.70, 0.22), 1.0, true)
    # A subtle Y-only track makes the travel direction obvious.
    draw_line(center + Vector2(0.0, -58.0), center + Vector2(0.0, 58.0), Color(0.48, 0.85, 1.0, 0.19), 3.0, true)
    for axis in [Vector2.UP, Vector2.DOWN]:
        draw_line(center + axis * 52.0, center + axis * 61.0, Color(0.48, 0.85, 1.0, 0.40), 2.0, true)
    var knob: Vector2 = center + Vector2(0.0, value * 2.0 - 1.0) * STICK_RADIUS
    draw_circle(knob, KNOB_RADIUS + 5.0, Color(0.09, 0.49, 0.68, 0.22))
    draw_circle(knob, KNOB_RADIUS, Color(0.09, 0.34, 0.53, 0.95))
    draw_arc(knob, KNOB_RADIUS, 0.0, TAU, 48, Color(0.60, 0.91, 1.0, 0.80), 2.0, true)
    draw_circle(knob + Vector2(-5.0, -6.0), 7.0, Color(0.47, 0.80, 0.93, 0.32))
