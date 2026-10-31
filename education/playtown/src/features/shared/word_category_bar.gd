extends Control

signal category_selected(category: String)

const ObjectCatalog := preload("res://education/playtown/src/features/shared/learning_object_catalog.gd")
const BUTTON_COLORS := {
	"objects": Color("#57bce7"),
	"body": Color("#ff9f55"),
	"animals": Color("#76c95a"),
	"products": Color("#ef6c62"),
	"shapes": Color("#ad78df"),
}

var selected_category := "objects"
var buttons: Dictionary = {}


func setup(initial_category: String = "objects") -> void:
	selected_category = initial_category if ObjectCatalog.CATEGORIES.has(initial_category) else "objects"
	for child in get_children():
		child.queue_free()
	buttons.clear()
	for category in ObjectCatalog.CATEGORIES:
		var button := Button.new()
		button.name = "Category_%s" % category
		button.focus_mode = Control.FOCUS_NONE
		button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		button.icon = load(ObjectCatalog.category_icon_path(category)) as Texture2D
		button.expand_icon = true
		button.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
		button.pressed.connect(_select_category.bind(category, true))
		add_child(button)
		buttons[category] = button
	_apply_styles()


func set_layout(rect: Rect2, vertical: bool = false) -> void:
	position = rect.position
	size = rect.size
	if vertical:
		_layout_vertical(rect.size)
	else:
		_layout_horizontal(rect.size)


func _layout_horizontal(layout_size: Vector2) -> void:
	var gap: float = clampf(layout_size.x * 0.018, 5.0, 13.0)
	var side: float = minf(layout_size.y, (layout_size.x - gap * 4.0) / 5.0)
	var total_width: float = side * 5.0 + gap * 4.0
	var start_x: float = (layout_size.x - total_width) * 0.5
	for index in range(ObjectCatalog.CATEGORIES.size()):
		var category: String = ObjectCatalog.CATEGORIES[index]
		var button: Button = buttons.get(category)
		if button == null:
			continue
		button.position = Vector2(start_x + float(index) * (side + gap), (layout_size.y - side) * 0.5)
		button.size = Vector2.ONE * side
		button.pivot_offset = button.size * 0.5


func _layout_vertical(layout_size: Vector2) -> void:
	var gap: float = clampf(layout_size.y * 0.018, 7.0, 13.0)
	var side: float = minf(layout_size.x, (layout_size.y - gap * 4.0) / 5.0)
	var total_height: float = side * 5.0 + gap * 4.0
	var start_y: float = (layout_size.y - total_height) * 0.5
	for index in range(ObjectCatalog.CATEGORIES.size()):
		var category: String = ObjectCatalog.CATEGORIES[index]
		var button: Button = buttons.get(category)
		if button == null:
			continue
		button.position = Vector2((layout_size.x - side) * 0.5, start_y + float(index) * (side + gap))
		button.size = Vector2.ONE * side
		button.pivot_offset = button.size * 0.5


func _select_category(category: String, emit_change: bool) -> void:
	if category == selected_category:
		return
	selected_category = category
	_apply_styles()
	if emit_change:
		category_selected.emit(category)


func _apply_styles() -> void:
	for category in ObjectCatalog.CATEGORIES:
		var button: Button = buttons.get(category)
		if button == null:
			continue
		var selected: bool = category == selected_category
		var base: Color = BUTTON_COLORS.get(category, Color("#57bce7"))
		button.add_theme_stylebox_override("normal", _button_style(base, selected, false))
		button.add_theme_stylebox_override("hover", _button_style(base.lightened(0.08), selected, true))
		button.add_theme_stylebox_override("pressed", _button_style(base.darkened(0.06), true, false))
		button.scale = Vector2.ONE * (1.06 if selected else 1.0)


func _button_style(color: Color, selected: bool, hover: bool) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = color.lightened(0.22 if selected else 0.34)
	style.border_color = Color("#ffb329") if selected else color.darkened(0.34)
	style.set_border_width_all(5 if selected else 3)
	style.set_corner_radius_all(17)
	style.content_margin_left = 8.0
	style.content_margin_right = 8.0
	style.content_margin_top = 8.0
	style.content_margin_bottom = 8.0
	style.shadow_color = Color(0.20, 0.12, 0.05, 0.28 if selected or hover else 0.18)
	style.shadow_size = 7 if selected else 4
	style.shadow_offset = Vector2(0.0, 4.0)
	return style
