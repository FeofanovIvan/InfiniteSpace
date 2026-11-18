extends Area2D
# MIKA_SHOPPING_LIST_DRAG_FIX_V1
# MIKA_SHOPPING_BASKET_NODE_LOOKUP_V1_1
signal dropped_in_basket(item)
signal dropped_wrong(item)
@export var product_name := ""
@onready var sprite: Sprite2D = $Sprite2D
@onready var collision: CollisionShape2D = $CollisionShape2D
var product_voice: AudioStream
var dragging := false
var drag_offset := Vector2.ZERO
var start_position := Vector2.ZERO
var press_position := Vector2.ZERO
var moved := false
var drag_threshold := 14.0
var drag_touch_index: int = -1
func _ready() -> void:
	z_index = 20
	# _input receives touch and mouse motion reliably across scaled shelves.
	# Area2D.input_event can miss a press under overlapping UI Controls.
func set_start_position(value: Vector2) -> void:
	start_position = value
	global_position = value
func reset_to_start() -> void:
	global_position = start_position
func set_display_size(target_size: Vector2) -> void:
	if sprite.texture == null:
		return
	var texture_size := Vector2(sprite.texture.get_size())
	var fit_scale: float = minf(
		target_size.x / maxf(texture_size.x, 1.0),
		target_size.y / maxf(texture_size.y, 1.0)
	)
	sprite.scale = Vector2.ONE * fit_scale
	var rectangle := collision.shape as RectangleShape2D
	rectangle.size = target_size * 0.88
func _input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		var touch: InputEventScreenTouch = event
		var world: Vector2 = _screen_to_world(touch.position)
		if touch.pressed:
			_try_start_drag(world, touch.index)
		elif dragging and (drag_touch_index == touch.index or drag_touch_index == -1):
			_finish_drag()
	elif event is InputEventScreenDrag:
		var motion: InputEventScreenDrag = event
		if dragging and (drag_touch_index == motion.index or drag_touch_index == -1):
			drag_touch_index = motion.index
			_drag_to(_screen_to_world(motion.position))
	elif event is InputEventMouseButton:
		var button: InputEventMouseButton = event
		if button.button_index != MOUSE_BUTTON_LEFT:
			return
		if button.pressed:
			_try_start_drag(_screen_to_world(button.position), -1)
		elif dragging and drag_touch_index == -1:
			_finish_drag()
	elif event is InputEventMouseMotion and dragging and drag_touch_index == -1:
		_drag_to(_screen_to_world(event.position))

func _screen_to_world(screen_position: Vector2) -> Vector2:
	# Screen/touch pixels must not be mistaken for world coordinates.
	return to_global(get_global_transform_with_canvas().affine_inverse() * screen_position)

func _try_start_drag(pointer: Vector2, touch_index: int) -> void:
	if dragging or not visible:
		return
	var box: RectangleShape2D = collision.shape as RectangleShape2D
	if box == null:
		return
	var local_pointer: Vector2 = to_local(pointer) - collision.position
	var half: Vector2 = box.size * 0.5 + Vector2.ONE * 5.0
	if absf(local_pointer.x) > half.x or absf(local_pointer.y) > half.y:
		return
	_start_drag(pointer)
	drag_touch_index = touch_index

func _start_drag(pointer: Vector2) -> void:
	dragging = true
	moved = false
	press_position = pointer
	drag_offset = global_position - pointer
	move_to_front()
	if product_voice:
		SFX.play_voice_2d(product_voice, global_position)
func _drag_to(pointer: Vector2) -> void:
	if pointer.distance_to(press_position) > drag_threshold:
		moved = true
	global_position = pointer + drag_offset
func _finish_drag() -> void:
	if not dragging:
		return
	dragging = false
	drag_touch_index = -1
	if not moved:
		reset_to_start()
		return
	# Physics overlap lists can be a frame behind the last drag event.
	# Check the real basket shape in the same coordinate space as the item.
	for basket in get_tree().get_nodes_in_group("basket"):
		if not basket is Area2D:
			continue
		# GroceryGame creates this child at runtime WITHOUT assigning a name.
		var basket_shape: CollisionShape2D = null
		for basket_child in basket.get_children():
			if basket_child is CollisionShape2D:
				basket_shape = basket_child as CollisionShape2D
				break
		if basket_shape == null:
			continue
		var rectangle: RectangleShape2D = basket_shape.shape as RectangleShape2D
		if rectangle == null:
			continue
		var basket_local: Vector2 = basket_shape.to_local(global_position)
		var bounds: Rect2 = Rect2(-rectangle.size * 0.5, rectangle.size)
		if bounds.grow(8.0).has_point(basket_local):
			dropped_in_basket.emit(self)
			return
	dropped_wrong.emit(self)
