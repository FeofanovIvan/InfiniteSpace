class_name ChildJoystick
extends Control

signal direction_changed(direction: Vector2)

@export_range(0.0, 0.8, 0.01) var dead_zone := 0.14
@export_range(0.2, 0.9, 0.01) var knob_limit := 0.58

var direction := Vector2.ZERO
var _active := false
var _touch_index := -1
var _mouse_active := false


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	focus_mode = Control.FOCUS_NONE
	set_process_input(true)
	resized.connect(queue_redraw)
	visibility_changed.connect(_on_visibility_changed)
	queue_redraw()


func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_PAUSED or what == NOTIFICATION_WM_WINDOW_FOCUS_OUT:
		reset()


func _on_visibility_changed() -> void:
	if not is_visible_in_tree():
		reset()


func _input(event: InputEvent) -> void:
	if not is_visible_in_tree():
		return
	if event is InputEventScreenTouch:
		var touch := event as InputEventScreenTouch
		if touch.pressed:
			if not _active and _contains_viewport_point(touch.position):
				_active = true
				_touch_index = touch.index
				_update_from_viewport(touch.position)
				get_viewport().set_input_as_handled()
		elif _active and touch.index == _touch_index:
			_release()
			get_viewport().set_input_as_handled()
	elif event is InputEventScreenDrag:
		var drag := event as InputEventScreenDrag
		if _active and drag.index == _touch_index:
			_update_from_viewport(drag.position)
			get_viewport().set_input_as_handled()
	elif event is InputEventMouseButton:
		var mouse := event as InputEventMouseButton
		if mouse.button_index != MOUSE_BUTTON_LEFT:
			return
		if mouse.pressed:
			if not _active and _contains_viewport_point(mouse.position):
				_active = true
				_mouse_active = true
				_update_from_viewport(mouse.position)
				get_viewport().set_input_as_handled()
		elif _active and _mouse_active:
			_release()
			get_viewport().set_input_as_handled()
	elif event is InputEventMouseMotion and _active and _mouse_active:
		var motion := event as InputEventMouseMotion
		_update_from_viewport(motion.position)
		get_viewport().set_input_as_handled()


func reset() -> void:
	_release()


func _contains_viewport_point(viewport_point: Vector2) -> bool:
	var local := get_global_transform_with_canvas().affine_inverse() * viewport_point
	var center := size * 0.5
	return local.distance_to(center) <= _base_radius() * 1.12


func _update_from_viewport(viewport_point: Vector2) -> void:
	var local := get_global_transform_with_canvas().affine_inverse() * viewport_point
	var center := size * 0.5
	var raw := (local - center) / maxf(1.0, _base_radius() * knob_limit)
	if raw.length() > 1.0:
		raw = raw.normalized()
	if raw.length() < dead_zone:
		raw = Vector2.ZERO
	elif raw != Vector2.ZERO:
		raw = raw.normalized() * inverse_lerp(dead_zone, 1.0, raw.length())
	_set_direction(raw)


func _release() -> void:
	_active = false
	_touch_index = -1
	_mouse_active = false
	_set_direction(Vector2.ZERO)


func _set_direction(value: Vector2) -> void:
	if direction.is_equal_approx(value):
		return
	direction = value
	direction_changed.emit(direction)
	queue_redraw()


func _base_radius() -> float:
	return maxf(1.0, minf(size.x, size.y) * 0.46)


func _draw() -> void:
	var center := size * 0.5
	var radius := _base_radius()
	# Warm, toy-like colors keep the control readable without looking like a
	# shooter HUD. The translucent base leaves the play area visible.
	draw_circle(center + Vector2(0.0, radius * 0.07), radius, Color(0.18, 0.08, 0.02, 0.25))
	draw_circle(center, radius, Color("#e84b45"), true)
	draw_circle(center, radius * 0.88, Color(1.0, 0.32, 0.28, 0.86), true)
	draw_arc(center, radius * 0.92, 0.0, TAU, 72, Color(1.0, 0.96, 0.82, 0.95), maxf(3.0, radius * 0.045), true)

	var arrow_color := Color(1.0, 0.96, 0.86, 0.48)
	var mark := radius * 0.54
	var mark_size := radius * 0.10
	var axes: Array[Vector2] = [Vector2.UP, Vector2.DOWN, Vector2.LEFT, Vector2.RIGHT]
	for axis in axes:
		var point: Vector2 = center + axis * mark
		draw_circle(point, mark_size, arrow_color, true)

	var knob_radius := radius * 0.38
	var knob_center := center + direction * radius * knob_limit
	draw_circle(knob_center + Vector2(0.0, knob_radius * 0.12), knob_radius, Color(0.18, 0.06, 0.02, 0.28), true)
	draw_circle(knob_center, knob_radius, Color("#fff0b8"), true)
	draw_circle(knob_center, knob_radius * 0.82, Color("#ffc94f"), true)
	draw_arc(knob_center, knob_radius * 0.90, 0.0, TAU, 56, Color.WHITE, maxf(2.0, radius * 0.032), true)
