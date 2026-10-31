extends Area2D
signal dropped_on_slot(item, slot)
signal dropped_wrong(item)
@export var letter := ""
@onready var sprite: Sprite2D = $Sprite2D
@onready var collision: CollisionShape2D = $CollisionShape2D
const GAME_FONT: Font = preload("res://education/playtown/assets/ui/fonts/RobotoCondensed-Variable.ttf")
const LETTER_COLORS: Array[Color] = [
	Color("#ff604f"),
	Color("#28a9ef"),
	Color("#ffc72e"),
	Color("#62c94f"),
	Color("#a86be8"),
	Color("#ff8a35"),
	Color("#ed58a5"),
	Color("#25c6ae")
]
var letter_label := Label.new()
var letter_depth_label := Label.new()
var letter_highlight_label := Label.new()
var letter_voice: AudioStream
var voice_player := AudioStreamPlayer.new()
var uses_image_letter := false
var dragging := false
var drag_offset := Vector2.ZERO
var start_position := Vector2.ZERO
var press_position := Vector2.ZERO
var moved := false
var enabled := true
var drag_threshold := 14.0
func _ready() -> void:
	sprite.visible = false
	_prepare_letter_label(letter_depth_label)
	_prepare_letter_label(letter_label)
	_prepare_letter_label(letter_highlight_label)
	add_child(letter_depth_label)
	add_child(letter_label)
	add_child(letter_highlight_label)
	add_child(voice_player)
	voice_player.bus = "VOICE"
	z_index = 30
	input_event.connect(_on_input_event)
func configure_letter(value: String, voice: AudioStream) -> void:
	letter = value.to_upper()
	letter_voice = voice
	uses_image_letter = _try_use_english_letter_image()
	letter_depth_label.visible = not uses_image_letter
	letter_label.visible = not uses_image_letter
	letter_highlight_label.visible = not uses_image_letter
	if uses_image_letter:
		return
	var base_color: Color = LETTER_COLORS[posmod(letter.hash(), LETTER_COLORS.size())]
	letter_depth_label.text = letter
	letter_label.text = letter
	letter_highlight_label.text = letter
	letter_depth_label.add_theme_color_override("font_color", base_color.darkened(0.38))
	letter_depth_label.add_theme_color_override("font_outline_color", base_color.darkened(0.62))
	letter_label.add_theme_color_override("font_color", base_color)
	letter_label.add_theme_color_override("font_outline_color", base_color.darkened(0.5))
	letter_highlight_label.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0, 0.2))
	letter_highlight_label.add_theme_color_override("font_outline_color", Color(1.0, 1.0, 1.0, 0.0))
func set_start_position(value: Vector2) -> void:
	start_position = value
	global_position = value
func reset_to_start() -> void:
	scale = Vector2.ONE
	rotation = 0.0
	global_position = start_position
func set_display_size(target_size: Vector2) -> void:
	if uses_image_letter and sprite.texture:
		var texture_size: Vector2 = sprite.texture.get_size()
		var image_scale: float = minf(target_size.x / texture_size.x, target_size.y / texture_size.y) * 0.94
		sprite.scale = Vector2.ONE * image_scale
	else:
		var font_size: int = int(target_size.y * 0.8)
		var depth_offset: float = maxf(3.0, target_size.y * 0.075)
		letter_depth_label.position = -target_size * 0.5 + Vector2(0.0, depth_offset)
		letter_depth_label.size = target_size
		letter_depth_label.add_theme_font_size_override("font_size", font_size)
		letter_label.position = -target_size * 0.5
		letter_label.size = target_size
		letter_label.add_theme_font_size_override("font_size", font_size)
		letter_highlight_label.position = -target_size * 0.5 + Vector2(0.0, -maxf(1.0, target_size.y * 0.025))
		letter_highlight_label.size = target_size
		letter_highlight_label.add_theme_font_size_override("font_size", font_size)
	var rectangle := collision.shape as RectangleShape2D
	rectangle.size = target_size * 0.9
func set_enabled(value: bool) -> void:
	scale = Vector2.ONE
	rotation = 0.0
	enabled = value
	input_pickable = value
	monitoring = value
	visible = value
func _on_input_event(_viewport: Node, event: InputEvent, _shape_index: int) -> void:
	if not enabled:
		return
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
	scale = Vector2.ONE * 1.08
	rotation = deg_to_rad(-2.0 if posmod(letter.hash(), 2) == 0 else 2.0)
	if letter_voice:
		voice_player.stop()
		voice_player.stream = letter_voice
		voice_player.play()
func _drag_to(pointer: Vector2) -> void:
	if pointer.distance_to(press_position) > drag_threshold:
		moved = true
	global_position = pointer + drag_offset
func _finish_drag() -> void:
	if not dragging:
		return
	dragging = false
	scale = Vector2.ONE
	rotation = 0.0
	if not moved:
		reset_to_start()
		return
	var target_slot
	for area in get_overlapping_areas():
		if area.is_in_group("letter_slot"):
			target_slot = area
			break
	if target_slot:
		dropped_on_slot.emit(self, target_slot)
	else:
		dropped_wrong.emit(self)

func _prepare_letter_label(label: Label) -> void:
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_override("font", GAME_FONT)
	label.add_theme_constant_override("outline_size", 5)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE

func _try_use_english_letter_image() -> bool:
	if LanguageService.learning_locale != "en" or letter.length() != 1:
		sprite.visible = false
		return false
	var texture_path := "res://education/playtown/assets/alphabet/%s.png" % letter.to_lower()
	if not ResourceLoader.exists(texture_path):
		sprite.visible = false
		return false
	sprite.texture = load(texture_path) as Texture2D
	sprite.visible = sprite.texture != null
	return sprite.visible
