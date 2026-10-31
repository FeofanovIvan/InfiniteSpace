extends Area2D
signal dropped(item)
@export var category: String = ""
@export var voice: AudioStream = null
@onready var sprite: Sprite2D = $Sprite2D
@onready var voice_player: AudioStreamPlayer2D = AudioStreamPlayer2D.new()
var dragging: bool = false
var drag_offset: Vector2 = Vector2.ZERO
var start_position: Vector2 = Vector2.ZERO
func _ready() -> void:
	start_position = global_position
	visible = true
	sprite.visible = true
	z_index = 10
	sprite.z_index = 10
	add_child(voice_player)
	voice_player.bus = "VOICE"
	input_event.connect(_on_input_event)
func _on_input_event(_viewport, event: InputEvent, _shape_idx: int) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			_start_drag(get_global_mouse_position())
		else:
			_end_drag()
	elif event is InputEventMouseMotion and dragging:
		_drag_to(get_global_mouse_position())
	elif event is InputEventScreenTouch:
		if event.pressed:
			_start_drag(event.position)
		else:
			_end_drag()
	elif event is InputEventScreenDrag and dragging:
		_drag_to(event.position)
func _start_drag(pointer_global: Vector2) -> void:
	dragging = true
	drag_offset = global_position - pointer_global
	if voice:
		voice_player.stop()
		voice_player.stream = voice
		voice_player.play()
func _drag_to(pointer_global: Vector2) -> void:
	global_position = pointer_global + drag_offset
func _end_drag() -> void:
	if not dragging:
		return
	dragging = false
	dropped.emit(self)
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
	var rectangle := $CollisionShape2D.shape as RectangleShape2D
	if rectangle:
		rectangle.size = Vector2(
			min(target_size.x, texture_size.x * fit_scale),
			min(target_size.y, texture_size.y * fit_scale)
		)
