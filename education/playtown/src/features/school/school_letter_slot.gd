extends Area2D
@export var index := 0
@export var expected_letter := ""
var panel := Panel.new()
var collision := CollisionShape2D.new()
const GAME_FONT: Font = preload("res://education/playtown/assets/ui/fonts/RobotoCondensed-Variable.ttf")
var hint_label := Label.new()
var placed_label := Label.new()
func setup(character: String) -> void:
	add_to_group("letter_slot")
	var style := StyleBoxFlat.new()
	style.bg_color = Color("#fffdf7")
	style.border_color = Color("#d79a47")
	style.set_border_width_all(4)
	style.set_corner_radius_all(18)
	style.shadow_color = Color(0.32, 0.18, 0.08, 0.2)
	style.shadow_size = 6
	style.shadow_offset = Vector2(0.0, 4.0)
	panel.add_theme_stylebox_override("panel", style)
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(panel)
	var shape := RectangleShape2D.new()
	collision.shape = shape
	add_child(collision)
	_configure_label(hint_label, character, Color(0.45, 0.25, 0.10, 0.18))
	hint_label.z_index = 2
	add_child(hint_label)
	_configure_label(placed_label, character, Color("#6d3f20"))
	placed_label.z_index = 4
	placed_label.visible = false
	add_child(placed_label)
func set_display_size(target_size: Vector2) -> void:
	panel.position = -target_size * 0.5
	panel.size = target_size
	var rectangle := collision.shape as RectangleShape2D
	rectangle.size = target_size
	_fit_label(hint_label, target_size)
	_fit_label(placed_label, target_size)
func place_letter(character: String) -> void:
	placed_label.text = character.to_upper()
	placed_label.visible = true
	hint_label.visible = false
	_fit_label(placed_label, (collision.shape as RectangleShape2D).size)
	var style := panel.get_theme_stylebox("panel").duplicate() as StyleBoxFlat
	style.bg_color = Color("#e8f7d9")
	style.border_color = Color("#69ad51")
	panel.add_theme_stylebox_override("panel", style)
func _configure_label(label: Label, character: String, color: Color) -> void:
	label.text = character.to_upper()
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_override("font", GAME_FONT)
	label.add_theme_color_override("font_color", color)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
func _fit_label(label: Label, target_size: Vector2) -> void:
	label.position = -target_size * 0.5
	label.size = target_size
	label.add_theme_font_size_override("font_size", int(target_size.y * 0.63))
