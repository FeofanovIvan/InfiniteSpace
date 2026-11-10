extends Control
## MIKA Pinball v2.1: a one-axis slider with the flight joystick's neon language.
## Horizontal (power) releases to fire. Vertical (aim) retains its position.

signal value_changed(value: float)
signal drag_finished(value: float)

var vertical: bool = false
var value: float = 0.5
var _touch_id: int = -1
var _mouse_down: bool = false
var _pressed: bool = false


func _ready() -> void:
    mouse_filter = Control.MOUSE_FILTER_IGNORE
    queue_redraw()


func setup(is_vertical: bool, initial_value: float) -> void:
    vertical = is_vertical
    value = clampf(initial_value, 0.0, 1.0)
    queue_redraw()


func set_value_silently(next_value: float) -> void:
    value = clampf(next_value, 0.0, 1.0)
    queue_redraw()


func _point_in_bounds(screen_point: Vector2) -> bool:
    var p: Vector2 = get_global_transform_with_canvas().affine_inverse() * screen_point
    var rect: Rect2 = Rect2(Vector2.ZERO, size).grow(8.0)
    return rect.has_point(p)


func _set_screen_value(screen_point: Vector2) -> void:
    var p: Vector2 = get_global_transform_with_canvas().affine_inverse() * screen_point
    var padding: float = minf(size.x, size.y) * 0.47
    var span: float = maxf(1.0, (size.y if vertical else size.x) - 2.0 * padding)
    var coordinate: float = p.y if vertical else p.x
    var next_value: float = clampf((coordinate - padding) / span, 0.0, 1.0)
    if absf(next_value - value) > 0.0001:
        value = next_value
        value_changed.emit(value)
        queue_redraw()


func _input(event: InputEvent) -> void:
    if not is_visible_in_tree():
        return
    if event is InputEventScreenTouch:
        var touch: InputEventScreenTouch = event as InputEventScreenTouch
        if touch.pressed and _touch_id < 0 and _point_in_bounds(touch.position):
            _touch_id = touch.index
            _pressed = true
            _set_screen_value(touch.position)
            queue_redraw()
            get_viewport().set_input_as_handled()
        elif not touch.pressed and touch.index == _touch_id:
            _set_screen_value(touch.position)
            _touch_id = -1
            _pressed = false
            drag_finished.emit(value)
            queue_redraw()
            get_viewport().set_input_as_handled()
    elif event is InputEventScreenDrag:
        var drag: InputEventScreenDrag = event as InputEventScreenDrag
        if _touch_id == drag.index:
            _set_screen_value(drag.position)
            get_viewport().set_input_as_handled()
    elif event is InputEventMouseButton:
        var mouse: InputEventMouseButton = event as InputEventMouseButton
        if mouse.button_index != MOUSE_BUTTON_LEFT:
            return
        if mouse.pressed and not _mouse_down and _point_in_bounds(mouse.position):
            _mouse_down = true
            _pressed = true
            _set_screen_value(mouse.position)
            queue_redraw()
            get_viewport().set_input_as_handled()
        elif not mouse.pressed and _mouse_down:
            _set_screen_value(mouse.position)
            _mouse_down = false
            _pressed = false
            drag_finished.emit(value)
            queue_redraw()
            get_viewport().set_input_as_handled()
    elif event is InputEventMouseMotion and _mouse_down:
        _set_screen_value((event as InputEventMouseMotion).position)
        get_viewport().set_input_as_handled()


func _draw() -> void:
    var c: Vector2 = size * 0.5
    var axis_length: float = size.y if vertical else size.x
    var radius: float = minf(size.x, size.y) * 0.25
    var padding: float = minf(size.x, size.y) * 0.47
    var extent: float = maxf(2.0, axis_length - padding * 2.0)
    var first: Vector2 = Vector2(c.x, padding) if vertical else Vector2(padding, c.y)
    var last: Vector2 = Vector2(c.x, padding + extent) if vertical else Vector2(padding + extent, c.y)
    var knob: Vector2 = first.lerp(last, value)
    var bg: Rect2 = Rect2(Vector2.ZERO, size)
    var sb := StyleBoxFlat.new()
    sb.bg_color = Color(0.02, 0.10, 0.18, 0.37)
    sb.border_color = Color(0.38, 0.80, 1.0, 0.33)
    sb.set_border_width_all(2)
    sb.set_corner_radius_all(roundi(minf(size.x, size.y) * 0.45))
    draw_style_box(sb, bg)
    draw_line(first, last, Color(0.07, 0.28, 0.48, 0.86), radius * 0.40, true)
    draw_line(first, last, Color(0.44, 0.80, 1.0, 0.54), 3.0, true)
    draw_line(first, knob, Color(0.53, 0.96, 1.0, 0.86), 5.0, true)
    for i in range(5):
        var p: Vector2 = first.lerp(last, float(i) / 4.0)
        if vertical:
            draw_line(p + Vector2(-10.0, 0.0), p + Vector2(10.0, 0.0), Color(0.63, 0.86, 1.0, 0.37), 1.5, true)
        else:
            draw_line(p + Vector2(0.0, -10.0), p + Vector2(0.0, 10.0), Color(0.63, 0.86, 1.0, 0.37), 1.5, true)
    draw_circle(knob, radius + 7.0, Color(0.11, 0.65, 0.87, 0.26 if not _pressed else 0.43))
    draw_circle(knob, radius, Color(0.07, 0.35, 0.56, 0.96))
    draw_arc(knob, radius, 0.0, TAU, 48, Color(0.72, 0.98, 1.0), 2.5, true)
    draw_circle(knob + Vector2(-4.0, -5.0), 6.0, Color(0.65, 0.91, 1.0, 0.38))
