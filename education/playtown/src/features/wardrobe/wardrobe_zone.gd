extends Area2D
@export var category := ""
var preview := Sprite2D.new()
var collision := CollisionShape2D.new()
var error_mark := Label.new()
func setup(texture: Texture2D) -> void:
	add_to_group("wardrobe_zone")
	preview.texture = texture
	preview.modulate = Color(1.0, 1.0, 1.0, 0.52)
	preview.z_index = 1
	add_child(preview)
	var shape := RectangleShape2D.new()
	collision.shape = shape
	add_child(collision)
	error_mark.text = "×"
	error_mark.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	error_mark.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	error_mark.add_theme_color_override("font_color", Color("#e33b32"))
	error_mark.add_theme_color_override("font_outline_color", Color.WHITE)
	error_mark.add_theme_constant_override("outline_size", 5)
	error_mark.visible = false
	error_mark.z_index = 4
	add_child(error_mark)
func set_display_size(target_size: Vector2) -> void:
	var rectangle := collision.shape as RectangleShape2D
	rectangle.size = target_size
	if preview.texture:
		var texture_size := Vector2(preview.texture.get_size())
		var fit_scale: float = minf(
			target_size.x / maxf(texture_size.x, 1.0),
			target_size.y / maxf(texture_size.y, 1.0)
		)
		preview.scale = Vector2.ONE * fit_scale
	error_mark.position = -target_size * 0.5
	error_mark.size = target_size
	error_mark.add_theme_font_size_override("font_size", int(target_size.y * 0.72))
func show_error_mark() -> void:
	error_mark.visible = true
	error_mark.modulate.a = 1.0
	var tween := create_tween()
	tween.tween_property(error_mark, "modulate:a", 0.0, 0.45)
	tween.finished.connect(func() -> void: error_mark.visible = false)
