extends Control

const MOM_ICON: Texture2D = preload("res://education/playtown/assets/world/npcs/mom.png")
const TEACHER_ICON: Texture2D = preload("res://education/playtown/assets/world/npcs/teacher.png")
const SELLER_ICON: Texture2D = preload("res://education/playtown/assets/world/npcs/seller.png")
const FRIEND_ICON: Texture2D = preload("res://education/playtown/assets/world/npcs/classmate.png")
const BEAR_ICON: Texture2D = preload("res://education/playtown/assets/ui/navigation/bear_icon.png")
const COURT_ICON: Texture2D = preload("res://education/playtown/assets/basketball/ball.png")
const ICE_CREAM_ICON: Texture2D = preload("res://education/playtown/assets/ice_cream/ice_cream_strawberry.png")

const DESTINATION_SCENES := {
	"Мама": "res://education/playtown/scenes/screens/game_select_home.tscn",
	"Учитель": "res://education/playtown/scenes/screens/game_select_school.tscn",
	"Продавец": "res://education/playtown/scenes/screens/game_select_shop.tscn",
	"Друг": "res://education/playtown/scenes/screens/game_select_playground.tscn",
	"Дом": "res://education/playtown/scenes/features/house_search/house_search_game.tscn",
	"Площадка": "res://education/playtown/scenes/features/basketball/basketball_game.tscn",
	"Мороженое": "res://education/playtown/scenes/features/ice_cream/ice_cream_game.tscn",
}

const SLOT_ORDER: Array[String] = ["Дом", "Мама", "Учитель", "Продавец", "Друг", "Площадка", "Мороженое"]
const OUTLINE := Color("#6b2f08")
const GOLD_DARK := Color("#cf7f0f")
const GOLD_MID := Color("#f0a61d")
const GOLD_LIGHT := Color("#ffca42")
const CREAM := Color("#f6e8bf")
const SHADOW := Color(0.22, 0.08, 0.00, 0.30)
const CIRCLE_LIFT_FRACTION := 0.075 # Slightly raise central circular selector

@onready var mom_target := get_node_or_null("/root/Main/MomTarget") as Node2D
@onready var teacher_target := get_node_or_null("/root/Main/TeacherTarget") as Node2D
@onready var seller_target := get_node_or_null("/root/Main/SellerTarget") as Node2D
@onready var classmate_target := get_node_or_null("/root/Main/ClassmateTarget") as Node2D

var current_target_name := "Дом"
var expanded := false
var circle_button: Button
var active_icon: TextureRect
var slot_buttons: Array[Button] = []
var slot_icons: Array[TextureRect] = []
var panel_width := 0.0
var panel_height := 0.0
var circle_diameter := 0.0
var slot_side := 0.0
var gap := 0.0
var left_margin := 0.0
var bar_start_x := 0.0
var open_rect: Rect2 = Rect2()
var slot_centers: Array[Vector2] = []


func _ready() -> void:
	set_anchors_preset(Control.PRESET_TOP_LEFT)
	top_level = true
	z_index = 50
	mouse_filter = Control.MOUSE_FILTER_PASS
	for child in get_children():
		child.queue_free()
	_build_panel()
	var restored: String = String(GameState.last_nav_target)
	if not DESTINATION_SCENES.has(restored):
		restored = "Дом"
	set_active_target(restored)
	get_viewport().size_changed.connect(_layout)
	call_deferred("_layout")
	# NavCircle is a separate top-left navigation control.
	# Keep it visible and functional; this script only owns the bottom panel.
	var upper_nav_circle: CanvasItem = get_node_or_null("../NavCircle") as CanvasItem
	if upper_nav_circle != null:
		upper_nav_circle.show()
		upper_nav_circle.set_process(true)


func _build_panel() -> void:
	circle_button = Button.new()
	circle_button.focus_mode = Control.FOCUS_NONE
	circle_button.flat = true
	circle_button.text = ""
	circle_button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	circle_button.pressed.connect(_toggle)
	circle_button.add_theme_stylebox_override("normal", StyleBoxEmpty.new())
	circle_button.add_theme_stylebox_override("hover", StyleBoxEmpty.new())
	circle_button.add_theme_stylebox_override("pressed", StyleBoxEmpty.new())
	circle_button.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	add_child(circle_button)

	active_icon = TextureRect.new()
	active_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	active_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	active_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	circle_button.add_child(active_icon)

	for label in SLOT_ORDER:
		var button := Button.new()
		button.focus_mode = Control.FOCUS_NONE
		button.flat = true
		button.text = ""
		button.visible = false
		button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		button.pressed.connect(_on_slot_pressed.bind(label))
		button.add_theme_stylebox_override("normal", StyleBoxEmpty.new())
		button.add_theme_stylebox_override("hover", StyleBoxEmpty.new())
		button.add_theme_stylebox_override("pressed", StyleBoxEmpty.new())
		button.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
		add_child(button)
		var icon := TextureRect.new()
		icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon.texture = _display_texture(label)
		button.add_child(icon)
		slot_buttons.append(button)
		slot_icons.append(icon)


func _layout() -> void:
	# Use viewport coordinates consistently. Do not cap the width at 420:
	# on retina / stretched projects that corresponds to a tiny on-screen bar.
	var view: Vector2 = get_viewport().get_visible_rect().size
	panel_width = view.x * 0.445
	circle_diameter = view.y * 0.177
	panel_height = circle_diameter
	var bar_height: float = circle_diameter * 0.75
	gap = bar_height * 0.095
	left_margin = maxf(10.0, view.x * 0.013)
	# The bar extends behind the large circle, but NO slot may overlap it.
	bar_start_x = circle_diameter * 0.43
	var first_slot_left: float = circle_diameter + gap * 0.55
	var bar_right_padding: float = gap * 1.3
	var usable_slots_width: float = maxf(1.0, panel_width - first_slot_left - bar_right_padding)
	var slot_capacity: float = (usable_slots_width - gap * 6.0) / 7.0
	slot_side = minf(bar_height * 0.69, maxf(1.0, slot_capacity))
	var total_slots_width: float = slot_side * 7.0 + gap * 6.0
	var slots_origin_x: float = first_slot_left + maxf(0.0, (usable_slots_width - total_slots_width) * 0.5)
	position = Vector2(left_margin, view.y - panel_height - maxf(8.0, view.y * 0.02))
	size = Vector2(panel_width if expanded else circle_diameter, panel_height)
	var circle_lift: float = circle_diameter * CIRCLE_LIFT_FRACTION
	circle_button.position = Vector2(0.0, -circle_lift)
	circle_button.size = Vector2.ONE * circle_diameter
	active_icon.size = Vector2.ONE * circle_diameter * 0.76
	active_icon.position = Vector2.ONE * circle_diameter * 0.12
	var bar_y: float = (panel_height - bar_height) * 0.5
	open_rect = Rect2(bar_start_x, bar_y, panel_width - bar_start_x, bar_height)
	slot_centers.clear()
	for index in slot_buttons.size():
		var cx: float = slots_origin_x + slot_side * 0.5 + index * (slot_side + gap)
		var cy: float = bar_y + bar_height * 0.5
		var center: Vector2 = Vector2(cx, cy)
		slot_centers.append(center)
		var button: Button = slot_buttons[index]
		button.visible = expanded
		button.position = center - Vector2.ONE * slot_side * 0.5
		button.size = Vector2.ONE * slot_side
		var icon: TextureRect = slot_icons[index]
		var icon_scale: float = 0.78 if SLOT_ORDER[index] != "Площадка" else 0.72
		icon.size = Vector2.ONE * slot_side * icon_scale
		icon.position = (button.size - icon.size) * 0.5
	queue_redraw()


func _draw() -> void:
	if expanded:
		_draw_bar()
	_draw_circle_base()
	if expanded:
		for i in SLOT_ORDER.size():
			_draw_slot(slot_centers[i], SLOT_ORDER[i] == current_target_name)


func _draw_bar() -> void:
	var shadow_rect: Rect2 = open_rect
	shadow_rect.position += Vector2(0.0, 2.0)
	draw_round_rect(shadow_rect, 17.0, SHADOW)
	draw_round_rect(open_rect, 17.0, OUTLINE)
	var outer := open_rect.grow(-3.0)
	draw_round_rect(outer, 15.0, GOLD_DARK)
	var inner := outer.grow(-4.0)
	draw_round_rect(inner, 12.0, GOLD_MID)
	var highlight := Rect2(inner.position + Vector2(0.0, 1.0), Vector2(inner.size.x, inner.size.y * 0.44))
	draw_round_rect(highlight, 11.0, Color(1.0, 0.86, 0.46, 0.42))


func _draw_circle_base() -> void:
	var c: Vector2 = Vector2(circle_diameter * 0.5, circle_diameter * (0.5 - CIRCLE_LIFT_FRACTION))
	draw_circle(c + Vector2(0, 2), circle_diameter * 0.50, SHADOW)
	draw_circle(c, circle_diameter * 0.50, OUTLINE)
	draw_circle(c, circle_diameter * 0.46, GOLD_DARK)
	draw_circle(c, circle_diameter * 0.41, GOLD_LIGHT)
	draw_circle(c, circle_diameter * 0.34, CREAM)
	# small gloss
	draw_circle(c + Vector2(-circle_diameter * 0.14, -circle_diameter * 0.15), circle_diameter * 0.10, Color(1,1,1,0.22))


func _draw_slot(center: Vector2, selected: bool) -> void:
	var side := slot_side
	var rect := Rect2(center - Vector2.ONE * side * 0.5, Vector2.ONE * side)
	draw_round_rect(rect, side * 0.23, OUTLINE)
	var mid := rect.grow(-2.5)
	draw_round_rect(mid, side * 0.20, GOLD_DARK)
	var inner := mid.grow(-3.0)
	var fill := Color("#f8ebc4") if not selected else Color("#fff2ce")
	draw_round_rect(inner, side * 0.18, fill)
	if selected:
		draw_round_rect(inner.grow(-1.5), side * 0.16, Color(1.0, 0.96, 0.79, 0.45))


func draw_round_rect(rect: Rect2, radius: float, color: Color) -> void:
	draw_rect(Rect2(rect.position + Vector2(radius, 0.0), Vector2(rect.size.x - radius * 2.0, rect.size.y)), color, true)
	draw_rect(Rect2(rect.position + Vector2(0.0, radius), Vector2(rect.size.x, rect.size.y - radius * 2.0)), color, true)
	draw_circle(rect.position + Vector2(radius, radius), radius, color)
	draw_circle(rect.position + Vector2(rect.size.x - radius, radius), radius, color)
	draw_circle(rect.position + Vector2(radius, rect.size.y - radius), radius, color)
	draw_circle(rect.position + Vector2(rect.size.x - radius, rect.size.y - radius), radius, color)


func _toggle() -> void:
	expanded = not expanded
	_layout()


func _on_slot_pressed(label: String) -> void:
	set_active_target(label)
	expanded = false
	_layout()
	_enter_location(label)


func _display_texture(label: String) -> Texture2D:
	var original: Texture2D = _texture_for(label)
	if original == null:
		return null
	# Portrait characters only: show head and torso instead of full-body sprites.
	# Cropping preserves the original aspect ratio; the rest of the character
	# remains available to the game and the original asset is unchanged.
	if label in ["Мама", "Учитель", "Продавец", "Друг"]:
		var source_size: Vector2 = original.get_size()
		var portrait: AtlasTexture = AtlasTexture.new()
		portrait.atlas = original
		portrait.region = Rect2(0.0, 0.0, source_size.x, source_size.y * 0.61)
		portrait.filter_clip = true
		return portrait
	return original


func _texture_for(label: String) -> Texture2D:
	match label:
		"Мама":
			return MOM_ICON
		"Учитель":
			return TEACHER_ICON
		"Продавец":
			return SELLER_ICON
		"Друг":
			return FRIEND_ICON
		"Дом":
			return BEAR_ICON
		"Площадка":
			return COURT_ICON
		"Мороженое":
			return ICE_CREAM_ICON
	return null


func _enter_location(label: String) -> void:
	var destination: String = String(DESTINATION_SCENES.get(label, ""))
	if destination.is_empty():
		return

	# Navigation launches an activity at its selected world location.
	# Remember that destination for the return journey, not the position
	# where the player happened to open the navigation bar.
	var return_position: Vector2 = get_current_target_position()
	if return_position == Vector2.ZERO:
		var player: Node2D = get_tree().get_first_node_in_group("player") as Node2D
		if player != null:
			return_position = player.global_position
	GameState.remember_main_player_position(return_position)
	SFX.transition_from_world(destination)


func set_active_target(label: String) -> void:
	if not DESTINATION_SCENES.has(label):
		return
	current_target_name = label
	active_icon.texture = _display_texture(label)
	GameState.remember_nav_target(label)
	for i in slot_icons.size():
		slot_icons[i].modulate = Color.WHITE if SLOT_ORDER[i] == label else Color(0.94, 0.94, 0.94, 0.96)
	queue_redraw()


func get_current_target_position() -> Vector2:
	match current_target_name:
		"Мама":
			return mom_target.global_position if mom_target else Vector2.ZERO
		"Учитель":
			return teacher_target.global_position if teacher_target else Vector2.ZERO
		"Друг":
			return classmate_target.global_position if classmate_target else Vector2.ZERO
		"Продавец":
			return seller_target.global_position if seller_target else Vector2.ZERO
		"Дом":
			return _node_position("/root/Main/BlueHouseEntrance/TalkArea/CollisionShape2D")
		"Площадка":
			return _node_position("/root/Main/BasketballEntrance/TalkArea/CollisionShape2D")
		"Мороженое":
			return _node_position("/root/Main/IceCreamEntrance/TalkArea/CollisionShape2D")
	return Vector2.ZERO


func _node_position(path: String) -> Vector2:
	var node := get_node_or_null(path) as Node2D
	return node.global_position if node else Vector2.ZERO


func _update_talk_button_offset() -> void:
	pass
