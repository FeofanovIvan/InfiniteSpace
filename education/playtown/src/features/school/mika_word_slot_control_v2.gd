extends Control
## MIKA Build a Word v2: plain rectangular slot, no collision node.

const GAME_FONT: Font = preload("res://education/playtown/assets/ui/fonts/RobotoCondensed-Variable.ttf")

var index: int = 0
var expected_letter: String = ""
var panel: Panel
var hint_label: Label
var placed_label: Label
var _cell_size: Vector2 = Vector2(70, 70)
var _filled: bool = false

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel = Panel.new()
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(panel)
	hint_label = Label.new()
	_setup_label(hint_label)
	add_child(hint_label)
	placed_label = Label.new()
	_setup_label(placed_label)
	placed_label.visible = false
	add_child(placed_label)
	_redraw_geometry()

func _setup_label(lbl: Label) -> void:
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	lbl.add_theme_font_override("font", GAME_FONT)
	lbl.add_theme_color_override("font_color", Color("#d8f8ff"))

func setup(character: String) -> void:
	expected_letter = character.to_upper()
	if hint_label != null:
		hint_label.text = expected_letter
		placed_label.text = expected_letter
		_redraw_geometry()

func set_display_size(target_size: Vector2) -> void:
	_cell_size = Vector2(maxf(8.0, target_size.x), maxf(8.0, target_size.y))
	_redraw_geometry()

func place_letter(character: String) -> void:
	_filled = true
	placed_label.text = character.to_upper()
	placed_label.visible = true
	hint_label.hide()
	_redraw_geometry()

func contains_screen_point(point: Vector2) -> bool:
	# Node position is the SLOT CENTRE, following school_game's layout.
	var actual: Rect2 = Rect2(global_position - _cell_size * 0.5, _cell_size)
	return actual.grow(maxf(2.0, minf(_cell_size.x, _cell_size.y) * 0.12)).has_point(point)

func centre() -> Vector2:
	return global_position

func _redraw_geometry() -> void:
	if panel == null:
		return
	panel.position = -_cell_size * 0.5
	panel.size = _cell_size
	for label in [hint_label, placed_label]:
		label.position = -_cell_size * 0.5
		label.size = _cell_size
		label.add_theme_font_size_override("font_size", maxi(8, roundi(_cell_size.y * 0.62)))
	hint_label.add_theme_color_override("font_color", Color(0.83, 0.97, 1.0, 0.32))
	placed_label.add_theme_color_override("font_color", Color("#e8ffff"))
	var box := StyleBoxFlat.new()
	box.anti_aliasing = true
	box.set_corner_radius_all(maxi(4, roundi(_cell_size.y * 0.19)))
	box.set_border_width_all(maxi(2, roundi(_cell_size.y * 0.046)))
	box.bg_color = Color(0.13, 0.44, 0.60, 0.96) if _filled else Color(0.12, 0.30, 0.53, 0.86)
	box.border_color = Color("#78ffe0") if _filled else Color("#a8eeff")
	box.shadow_color = Color(0.12, 0.68, 1.0, 0.42)
	box.shadow_size = maxi(3, roundi(_cell_size.y * 0.10))
	box.shadow_offset = Vector2.ZERO
	panel.add_theme_stylebox_override("panel", box)
