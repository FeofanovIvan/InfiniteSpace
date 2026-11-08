class_name ProductCountSource
extends TextureRect

signal product_dropped(product_key: String)

var product_key := ""
var product_voice: AudioStream
var basket_rect := Rect2()
var accept_drop_inside := true
var home_position := Vector2.ZERO
var dragging := false
var drag_offset := Vector2.ZERO


func _ready() -> void:
	expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	mouse_filter = Control.MOUSE_FILTER_STOP
	gui_input.connect(_on_gui_input)


func configure(key: String, image: Texture2D, voice: AudioStream) -> void:
	product_key = key
	texture = image
	product_voice = voice


func set_home(rect: Rect2) -> void:
	position = rect.position
	size = rect.size
	home_position = rect.position
	pivot_offset = rect.size * 0.5


func _on_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			_start_drag(get_global_mouse_position())
		else:
			_finish_drag(get_global_mouse_position())
	elif event is InputEventScreenTouch:
		var pointer_global: Vector2 = get_global_transform() * event.position
		if event.pressed:
			_start_drag(pointer_global)
		else:
			_finish_drag(pointer_global)


func _input(event: InputEvent) -> void:
	if not dragging:
		return
	if event is InputEventMouseMotion:
		_drag_to(get_global_mouse_position())
	elif event is InputEventScreenDrag:
		_drag_to(event.position)
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and not event.pressed:
		_finish_drag(get_global_mouse_position())
	elif event is InputEventScreenTouch and not event.pressed:
		_finish_drag(event.position)


func _start_drag(pointer: Vector2) -> void:
	dragging = true
	drag_offset = global_position - pointer
	z_index = 80
	if product_voice:
		SFX.play_voice_2d(product_voice, global_position + size * 0.5)
	var tween := create_tween()
	tween.tween_property(self, "scale", Vector2.ONE * 1.12, 0.10)


func _drag_to(pointer: Vector2) -> void:
	global_position = pointer + drag_offset


func _finish_drag(pointer: Vector2) -> void:
	if not dragging:
		return
	dragging = false
	var released_inside := basket_rect.has_point(pointer)
	if released_inside == accept_drop_inside:
		product_dropped.emit(product_key)
	if is_inside_tree():
		_return_home()


func _return_home() -> void:
	var tween := create_tween().set_parallel(true)
	tween.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "position", home_position, 0.20)
	tween.tween_property(self, "scale", Vector2.ONE, 0.14)
	tween.finished.connect(func() -> void: z_index = 20)
