extends Control

signal drag_started(tool: Control)
signal drag_finished(tool: Control, drop_position: Vector2)

const GAME_FONT: Font = preload("res://education/playtown/assets/ui/fonts/RobotoCondensed-Variable.ttf")
const BRIDGE_TEXTURE: Texture2D = preload("res://education/playtown/assets/path_builder/bridge.webp")

@export_enum("bridge", "stop") var tool_type := "bridge"
@export var tool_index := 0
var dragging := false
var enabled := true
var placed := false
var home_position := Vector2.ZERO
var drag_offset := Vector2.ZERO

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	clip_contents = false
	queue_redraw()

func set_home(value: Vector2) -> void:
	home_position = value
	if not dragging and not placed:
		position = value

func return_home() -> void:
	dragging = false
	placed = false
	z_index = 12
	var tween := create_tween()
	tween.tween_property(self, "position", home_position, 0.22).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

func _gui_input(event: InputEvent) -> void:
	if not enabled:
		return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			_begin_drag(get_global_mouse_position())
		else:
			_finish_drag()
	elif event is InputEventMouseMotion and dragging and Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		_move_to(get_global_mouse_position())
	elif event is InputEventScreenTouch:
		if event.pressed:
			_begin_drag(get_global_transform() * event.position)
		else:
			_finish_drag()
	elif event is InputEventScreenDrag and dragging:
		_move_to(get_global_transform() * event.position)

func _begin_drag(pointer_global: Vector2) -> void:
	if dragging:
		return
	dragging = true
	drag_offset = global_position - pointer_global
	z_index = 40
	drag_started.emit(self)
	accept_event()

func _move_to(pointer_global: Vector2) -> void:
	global_position = pointer_global + drag_offset

func _finish_drag() -> void:
	if not dragging:
		return
	dragging = false
	drag_finished.emit(self, get_global_rect().get_center())
	accept_event()

func _draw() -> void:
	if tool_type == "stop":
		_draw_stop()
	else:
		_draw_bridge()

func _draw_bridge() -> void:
	var texture_size := BRIDGE_TEXTURE.get_size()
	var fit_scale := minf(size.x / texture_size.x, size.y / texture_size.y)
	var draw_size := texture_size * fit_scale
	var rect := Rect2((size - draw_size) * 0.5, draw_size)
	draw_texture_rect(BRIDGE_TEXTURE, rect, false)

func _draw_stop() -> void:
	var radius: float = minf(size.x, size.y) * 0.31
	var center := size * 0.5
	draw_circle(center + Vector2(2.0, 4.0), radius + 5.0, Color(0, 0, 0, 0.20))
	draw_circle(center, radius + 4.0, Color.WHITE)
	draw_circle(center, radius, Color("#e3483f"))
	draw_line(center + Vector2(-radius * 0.48, -radius * 0.48), center + Vector2(radius * 0.48, radius * 0.48), Color.WHITE, radius * 0.28, true)
	draw_line(center + Vector2(radius * 0.48, -radius * 0.48), center + Vector2(-radius * 0.48, radius * 0.48), Color.WHITE, radius * 0.28, true)
