extends TextureRect
signal drag_started(piece)
signal drag_ended(piece)
var piece_id: int = -1
var dragging: bool = false
var locked: bool = false
var drag_offset: Vector2 = Vector2.ZERO
var tray_parent: Node = null
var tray_index: int = -1
var drag_layer: Control = null
var active_touch_index: int = -1
func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	stretch_mode = TextureRect.STRETCH_SCALE
	gui_input.connect(_on_gui_input)
func setup(id: int, tex: Texture2D, parent_node: Node, layer: Control) -> void:
	piece_id = id
	texture = tex
	tray_parent = parent_node
	drag_layer = layer
func _on_gui_input(event: InputEvent) -> void:
	if locked:
		return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			_start_drag(get_global_mouse_position())
		elif dragging:
			_end_drag()
	elif event is InputEventScreenTouch:
		if event.pressed:
			active_touch_index = event.index
			_start_drag(get_global_transform() * event.position)
		elif dragging and event.index == active_touch_index:
			_end_drag()
func _input(event: InputEvent) -> void:
	if not dragging:
		return
	if event is InputEventMouseMotion:
		_drag_to(event.position)
	elif event is InputEventScreenDrag and event.index == active_touch_index:
		_drag_to(_viewport_to_canvas(event.position))
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and not event.pressed:
		_end_drag()
	elif event is InputEventScreenTouch and not event.pressed and event.index == active_touch_index:
		_end_drag()
func _viewport_to_canvas(viewport_position: Vector2) -> Vector2:
	return get_canvas_transform().affine_inverse() * viewport_position
func _start_drag(pointer_global: Vector2) -> void:
	if locked:
		return
	dragging = true
	drag_offset = global_position - pointer_global
	if tray_parent:
		tray_index = tray_parent.get_children().find(self)
	if drag_layer:
		reparent(drag_layer, true)
	z_index = 100
	scale = Vector2(1.08, 1.08)
	pivot_offset = size * 0.5
	drag_started.emit(self)
func _drag_to(pointer_global: Vector2) -> void:
	global_position = pointer_global + drag_offset
func _end_drag() -> void:
	if not dragging:
		return
	dragging = false
	active_touch_index = -1
	z_index = 0
	scale = Vector2.ONE
	drag_ended.emit(self)
func return_to_tray() -> void:
	if locked:
		return
	if tray_parent:
		reparent(tray_parent, true)
		var idx: int = tray_index
		if idx < 0 or idx > tray_parent.get_child_count():
			idx = tray_parent.get_child_count() - 1
		tray_parent.move_child(self, idx)
	scale = Vector2.ONE
	z_index = 0
func lock_into_slot() -> void:
	locked = true
	dragging = false
	queue_free()
