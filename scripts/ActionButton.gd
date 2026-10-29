extends Control
## Independent multitouch context-action button: "use", "take", "talk", "land".
## The nearest interactive object may select the mode in a later project phase.
signal action_requested(mode: String)

const CIRCLE_RADIUS: float = 67.0
const SIZE: float = 184.0
const VALID_MODES: Array[String] = ["use", "take", "talk", "land"]

var action_mode: String = "use"
var interaction_available: bool = false
var _touch_id: int = -1
var _mouse_down: bool = false
var _pressed_visual: bool = false
var _press_flash: float = 0.0


func _ready() -> void:
	size = Vector2(SIZE, SIZE)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	queue_redraw()


func set_action_mode(mode: String) -> void:
	if not VALID_MODES.has(mode):
		push_warning("Unknown action mode: %s" % mode)
		return
	action_mode = mode
	queue_redraw()


func set_action_available(available: bool) -> void:
	if interaction_available == available:
		return
	interaction_available = available
	_pressed_visual = false
	queue_redraw()


func _input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		if event.pressed and _touch_id < 0 and _in_circle(event.position):
			_touch_id = event.index
			_pressed_visual = true
			queue_redraw()
			get_viewport().set_input_as_handled()
		elif not event.pressed and _touch_id == event.index:
			_touch_id = -1
			var accepted: bool = _in_circle(event.position)
			_pressed_visual = false
			if accepted:
				_trigger_action()
			queue_redraw()
			get_viewport().set_input_as_handled()
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed and _in_circle(event.position):
			_mouse_down = true
			_pressed_visual = true
			queue_redraw()
			get_viewport().set_input_as_handled()
		elif not event.pressed and _mouse_down:
			_mouse_down = false
			var accepted: bool = _in_circle(event.position)
			_pressed_visual = false
			if accepted:
				_trigger_action()
			queue_redraw()
			get_viewport().set_input_as_handled()


func _in_circle(screen_point: Vector2) -> bool:
	var local: Vector2 = get_global_transform_with_canvas().affine_inverse() * screen_point
	return local.distance_to(size * 0.5) <= 83.0


func _trigger_action() -> void:
	if not interaction_available:
		return
	_press_flash = 0.18
	set_process(true)
	action_requested.emit(action_mode)


func _process(delta: float) -> void:
	if _press_flash <= 0.0:
		set_process(false)
		return
	_press_flash = maxf(0.0, _press_flash - delta)
	queue_redraw()


func _draw() -> void:
	var center := size * 0.5
	var active: float = 1.0 if _pressed_visual else 0.0
	var flash: float = _press_flash / 0.18
	# Visual treatment intentionally matches the right joystick.
	draw_circle(center, 83.0, Color(0.02, 0.10, 0.18, 0.36))
	draw_circle(center, CIRCLE_RADIUS, Color(0.04, 0.17, 0.28, 0.43 + active * 0.15))
	draw_arc(center, CIRCLE_RADIUS, 0.0, TAU, 64, Color(0.38, 0.80, 1.0, 0.42 + flash * 0.46), 2.0 + active, true)
	draw_arc(center, 49.0, 0.0, TAU, 64, Color(0.18, 0.51, 0.70, 0.22), 1.0, true)
	if _pressed_visual or flash > 0.0:
		draw_circle(center, 45.0, Color(0.13, 0.56, 0.82, 0.13 + 0.11 * maxf(active, flash)))
	if not interaction_available:
		return  # Empty circle: no eligible interaction target nearby.
	match action_mode:
		"use":
			_draw_hand(center)
		"take":
			_draw_hand(center)
			draw_circle(center + Vector2(26, -22), 6.0, Color(0.60, 0.96, 1.0, 0.90))
		"talk":
			_draw_speech(center)
		"land":
			_draw_landing(center)


func _draw_hand(center: Vector2) -> void:
	# Small stylized open hand, with a raised index finger.
	var p := PackedVector2Array([
		Vector2(-23, 6), Vector2(-27, -6), Vector2(-23, -12),
		Vector2(-17, -13), Vector2(-11, -6), Vector2(-11, -27),
		Vector2(-8, -33), Vector2(-2, -35), Vector2(4, -29),
		Vector2(4, -9), Vector2(9, -23), Vector2(15, -27),
		Vector2(21, -22), Vector2(18, -6), Vector2(23, -14),
		Vector2(30, -15), Vector2(35, -8), Vector2(29, 12),
		Vector2(21, 27), Vector2(10, 33), Vector2(-7, 30),
		Vector2(-15, 23)
	])
	for i in range(p.size()):
		p[i] += center
	draw_colored_polygon(p, Color(0.58, 0.84, 0.96, 0.89))
	var line := p.duplicate()
	line.append(p[0])
	draw_polyline(line, Color(0.84, 0.98, 1.0, 0.90), 2.5, true)
	draw_line(center + Vector2(-6, 17), center + Vector2(15, 21), Color(0.10, 0.33, 0.53, 0.36), 2.0, true)


func _draw_speech(center: Vector2) -> void:
	var bubble := PackedVector2Array([
		center + Vector2(-31, -20), center + Vector2(30, -20),
		center + Vector2(30, 15), center + Vector2(3, 15),
		center + Vector2(-12, 31), center + Vector2(-13, 15),
		center + Vector2(-31, 15)
	])
	draw_colored_polygon(bubble, Color(0.65, 0.90, 1.0, 0.86))
	for i in range(3):
		draw_circle(center + Vector2(-16 + 16 * i, -2), 4.0, Color(0.07, 0.31, 0.51))


func _draw_landing(center: Vector2) -> void:
	var tone := Color(0.69, 0.95, 1.0, 0.92)
	draw_line(center + Vector2(0, -32), center + Vector2(0, 9), tone, 5.0, true)
	draw_line(center + Vector2(-15, -5), center + Vector2(0, 12), tone, 5.0, true)
	draw_line(center + Vector2(15, -5), center + Vector2(0, 12), tone, 5.0, true)
	draw_line(center + Vector2(-31, 25), center + Vector2(31, 25), tone, 4.0, true)
