extends Control
## Return from free camera inspection to the ship. Appears only when detached.
signal return_requested()

const DIAMETER: float = 72.0
const CENTER: Vector2 = Vector2(36.0, 36.0)
const HIT_RADIUS: float = 34.0
var _touch_id: int = -1
var _mouse_down: bool = false


func _ready() -> void:
	size = Vector2(DIAMETER, DIAMETER)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	visible = false


func _input(event: InputEvent) -> void:
	if not visible:
		return
	if event is InputEventScreenTouch:
		if event.pressed and _touch_id < 0 and _inside(event.position):
			_touch_id = event.index
			get_viewport().set_input_as_handled()
		elif not event.pressed and _touch_id == event.index:
			_touch_id = -1
			if _inside(event.position):
				return_requested.emit()
			get_viewport().set_input_as_handled()
	elif event is InputEventScreenDrag and event.index == _touch_id:
		get_viewport().set_input_as_handled()
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed and _inside(event.position):
			_mouse_down = true
			get_viewport().set_input_as_handled()
		elif not event.pressed and _mouse_down:
			_mouse_down = false
			if _inside(event.position):
				return_requested.emit()
			get_viewport().set_input_as_handled()
	elif event is InputEventMouseMotion and _mouse_down:
		get_viewport().set_input_as_handled()


func _inside(screen_point: Vector2) -> bool:
	var local: Vector2 = get_global_transform_with_canvas().affine_inverse() * screen_point
	return local.distance_to(CENTER) <= HIT_RADIUS


func _draw() -> void:
	var c := CENTER
	draw_circle(c, 34.0, Color(0.015, 0.075, 0.13, 0.79))
	draw_arc(c, 32.0, 0.0, TAU, 48, Color(0.42, 0.88, 1.0, 0.82), 2.0, true)
	var white := Color(0.75, 0.96, 1.0, 1.0)
	draw_arc(c, 12.0, 0.0, TAU, 40, white, 2.0, true)
	draw_circle(c, 3.0, white)
	for dir in [Vector2.UP, Vector2.DOWN, Vector2.LEFT, Vector2.RIGHT]:
		draw_line(c + dir * 15.0, c + dir * 23.0, white, 2.0, true)
