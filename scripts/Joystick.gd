extends Control
## Mouse and multi-touch compatible joystick. Input is normalized to [-1,1].
signal direction_changed(value: Vector2)

const STICK_RADIUS: float = 66.0
const KNOB_RADIUS: float = 26.0
var direction: Vector2 = Vector2.ZERO
var _touch_id: int = -1
var _mouse_down: bool = false


func _ready() -> void:
	size = Vector2(184.0, 184.0)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	queue_redraw()


func clear_input() -> void:
	_touch_id = -1
	_mouse_down = false
	_set_direction(Vector2.ZERO)


func _input(event: InputEvent) -> void:
	if not is_visible_in_tree():
		return
	if event is InputEventScreenTouch:
		if event.pressed and _touch_id < 0 and _in_joystick(event.position):
			_touch_id = event.index
			_set_from_screen(event.position)
			get_viewport().set_input_as_handled()
		elif not event.pressed and _touch_id == event.index:
			_touch_id = -1
			_set_direction(Vector2.ZERO)
			get_viewport().set_input_as_handled()
	elif event is InputEventScreenDrag and event.index == _touch_id:
		_set_from_screen(event.position)
		get_viewport().set_input_as_handled()
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed and _in_joystick(event.position):
			_mouse_down = true
			_set_from_screen(event.position)
			get_viewport().set_input_as_handled()
		elif not event.pressed and _mouse_down:
			_mouse_down = false
			_set_direction(Vector2.ZERO)
			get_viewport().set_input_as_handled()
	elif event is InputEventMouseMotion and _mouse_down:
		_set_from_screen(event.position)
		get_viewport().set_input_as_handled()


func _in_joystick(screen_point: Vector2) -> bool:
	var local: Vector2 = get_global_transform_with_canvas().affine_inverse() * screen_point
	return local.distance_to(size * 0.5) <= STICK_RADIUS * 1.43


func _set_from_screen(screen_point: Vector2) -> void:
	var local: Vector2 = get_global_transform_with_canvas().affine_inverse() * screen_point
	var relative: Vector2 = local - size * 0.5
	_set_direction(relative / STICK_RADIUS)


func _set_direction(next_direction: Vector2) -> void:
	direction = next_direction.limit_length(1.0)
	direction_changed.emit(direction)
	queue_redraw()


func _draw() -> void:
	var center: Vector2 = size * 0.5
	draw_circle(center, 83, Color(0.02, 0.10, 0.18, 0.36))
	draw_circle(center, 67, Color(0.04, 0.17, 0.28, 0.43))
	draw_arc(center, 67, 0.0, TAU, 64, Color(0.38, 0.80, 1.0, 0.42), 2.0, true)
	draw_arc(center, 49, 0.0, TAU, 64, Color(0.18, 0.51, 0.70, 0.22), 1.0, true)
	for a in range(4):
		var direction_line := Vector2.UP.rotated(float(a) * PI * 0.5)
		draw_line(center + direction_line * 52, center + direction_line * 61, Color(0.48, 0.85, 1.0, 0.40), 2.0)
	var knob: Vector2 = center + direction * STICK_RADIUS
	draw_circle(knob, KNOB_RADIUS + 5.0, Color(0.09, 0.49, 0.68, 0.22))
	draw_circle(knob, KNOB_RADIUS, Color(0.09, 0.34, 0.53, 0.95))
	draw_arc(knob, KNOB_RADIUS, 0.0, TAU, 48, Color(0.60, 0.91, 1.0, 0.80), 2.0, true)
	draw_circle(knob + Vector2(-5.0, -6.0), 7.0, Color(0.47, 0.80, 0.93, 0.32))
