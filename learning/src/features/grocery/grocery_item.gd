extends Area2D
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
func _ready() -> void:
	z_index = 20
	input_event.connect(_on_input_event)
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
func _on_input_event(_viewport: Node, event: InputEvent, _shape_index: int) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		_start_drag(get_global_mouse_position())
	elif event is InputEventScreenTouch and event.pressed:
		_start_drag(event.position)
func _input(event: InputEvent) -> void:
	if not dragging:
		return
	if event is InputEventMouseMotion:
		_drag_to(get_global_mouse_position())
	elif event is InputEventScreenDrag:
		_drag_to(event.position)
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and not event.pressed:
		_finish_drag()
	elif event is InputEventScreenTouch and not event.pressed:
		_finish_drag()
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
	if not moved:
		reset_to_start()
		return
	for area in get_overlapping_areas():
		if area.is_in_group("basket"):
			dropped_in_basket.emit(self)
			return
	dropped_wrong.emit(self)
