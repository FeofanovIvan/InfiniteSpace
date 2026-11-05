extends Node2D

const ProductCatalog := preload("res://education/playtown/src/features/shared/product_catalog.gd")

@export var product_scene: PackedScene
@export var list_size := 6
@export var results_scene_path := "res://education/playtown/scenes/screens/game_select_shop.tscn"
@export var correct_sound: AudioStream = preload("res://education/playtown/audio/sfx/correct.ogg")
@export var wrong_sound: AudioStream = preload("res://education/playtown/audio/sfx/wrong.ogg")
var products_data: Array[Dictionary] = []
const SHELF_TEXTURE: Texture2D = preload("res://education/playtown/assets/grocery/shelf.png")
const BASKET_TEXTURE: Texture2D = preload("res://education/playtown/assets/grocery/basket.png")
const STAR_TEXTURE: Texture2D = preload("res://education/playtown/assets/ui/star.png")
const SHELF_VISIBLE_RECT := Rect2(206.0, 79.0, 1125.0, 729.0)
const REFERENCE_SIZE := Vector2(1536.0, 768.0)
const PRODUCT_POSITIONS := [
	Vector2(0.16, 0.23), Vector2(0.33, 0.23), Vector2(0.50, 0.23), Vector2(0.67, 0.23), Vector2(0.84, 0.23),
	Vector2(0.16, 0.43), Vector2(0.33, 0.43), Vector2(0.50, 0.43), Vector2(0.67, 0.43), Vector2(0.84, 0.43),
	Vector2(0.16, 0.63), Vector2(0.33, 0.63), Vector2(0.50, 0.63), Vector2(0.67, 0.63), Vector2(0.84, 0.63)
]
var rng := RandomNumberGenerator.new()
var target_products: Array[Dictionary] = []
var collected_names: Array[String] = []
var product_items: Array = []
var score := 0
var game_over := false
var background_layer: CanvasLayer
var wall: ColorRect
var floor: ColorRect
var shelf_sprite: Sprite2D
var items_root: Node2D
var basket_sprite: Sprite2D
var basket_area: Area2D
var basket_collision: CollisionShape2D
var list_card: Panel
var list_title: Label
var list_rows: Array[Panel] = []
var list_icons: Array[TextureRect] = []
var list_labels: Array[Label] = []
var list_checks: Array[Label] = []
var ui_layer: CanvasLayer
var home_button: Button
var score_back: Panel
var score_icon: TextureRect
var score_label: Label
var error_flash: ColorRect
var basket_error_mark: Label
var win_overlay: Control
var win_panel: Panel
var win_title: Label
var win_message: Label
var again_button: Button
var back_button: Button
var voice_player: AudioStreamPlayer
func _ready() -> void:
	products_data = ProductCatalog.all(LanguageService.current_locale)
	if product_scene == null:
		return
	if products_data.is_empty():
		return
	rng.randomize()
	_build_scene()
	_create_shopping_list()
	_spawn_products()
	get_viewport().size_changed.connect(_layout_for_viewport)
	_layout_for_viewport()
	call_deferred("_play_intro")

func _play_intro() -> void:
	var stream := LanguageService.get_game_voice("collect_basket_intro")
	if stream == null:
		return
	voice_player.stream = stream
	voice_player.play()

func _build_scene() -> void:
	background_layer = CanvasLayer.new()
	background_layer.layer = -10
	add_child(background_layer)
	wall = ColorRect.new()
	wall.color = Color("#f7ecd8")
	wall.mouse_filter = Control.MOUSE_FILTER_IGNORE
	background_layer.add_child(wall)
	floor = ColorRect.new()
	floor.color = Color("#d6ad7a")
	floor.mouse_filter = Control.MOUSE_FILTER_IGNORE
	background_layer.add_child(floor)
	list_card = Panel.new()
	list_card.mouse_filter = Control.MOUSE_FILTER_IGNORE
	list_card.add_theme_stylebox_override("panel", _panel_style(
		Color("#fffaf0"), Color("#d79a47"), 4, 26
	))
	background_layer.add_child(list_card)
	list_title = Label.new()
	list_title.text = LanguageService.get_ui_text("shopping_list")
	list_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	list_title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	list_title.add_theme_color_override("font_color", Color("#74451f"))
	list_title.add_theme_color_override("font_outline_color", Color.WHITE)
	list_title.add_theme_constant_override("outline_size", 4)
	list_title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	background_layer.add_child(list_title)
	_build_list_rows()
	shelf_sprite = Sprite2D.new()
	shelf_sprite.texture = SHELF_TEXTURE
	shelf_sprite.region_enabled = true
	shelf_sprite.region_rect = SHELF_VISIBLE_RECT
	shelf_sprite.z_index = 0
	add_child(shelf_sprite)
	items_root = Node2D.new()
	items_root.name = "Products"
	items_root.z_index = 5
	add_child(items_root)
	basket_sprite = Sprite2D.new()
	basket_sprite.texture = BASKET_TEXTURE
	basket_sprite.z_index = 12
	add_child(basket_sprite)
	basket_area = Area2D.new()
	basket_area.add_to_group("basket")
	basket_area.z_index = 12
	add_child(basket_area)
	basket_collision = CollisionShape2D.new()
	basket_collision.shape = RectangleShape2D.new()
	basket_area.add_child(basket_collision)
	ui_layer = CanvasLayer.new()
	ui_layer.layer = 20
	add_child(ui_layer)
	voice_player = AudioStreamPlayer.new()
	voice_player.bus = "VOICE"
	add_child(voice_player)
	home_button = GameExitButton.new()
	home_button.pressed.connect(_go_home)
	ui_layer.add_child(home_button)
	score_back = GameScorePanel.new()
	ui_layer.add_child(score_back)
	score_icon = (score_back as GameScorePanel).score_icon
	score_label = (score_back as GameScorePanel).score_label
	error_flash = ColorRect.new()
	error_flash.color = Color(0.92, 0.16, 0.14, 0.0)
	error_flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	error_flash.visible = false
	ui_layer.add_child(error_flash)
	basket_error_mark = Label.new()
	basket_error_mark.text = "×"
	basket_error_mark.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	basket_error_mark.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	basket_error_mark.add_theme_color_override("font_color", Color("#e33b32"))
	basket_error_mark.add_theme_color_override("font_outline_color", Color.WHITE)
	basket_error_mark.add_theme_constant_override("outline_size", 8)
	basket_error_mark.visible = false
	basket_error_mark.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ui_layer.add_child(basket_error_mark)
	_build_win_overlay()
func _build_win_overlay() -> void:
	win_overlay = Control.new()
	win_overlay.visible = false
	win_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	ui_layer.add_child(win_overlay)
	var dim := ColorRect.new()
	dim.color = Color(0.16, 0.09, 0.03, 0.48)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	win_overlay.add_child(dim)
	win_panel = Panel.new()
	win_panel.add_theme_stylebox_override("panel", _panel_style(
		Color(1.0, 0.96, 0.78, 0.99), Color("#e39a28"), 6, 32
	))
	win_overlay.add_child(win_panel)
	win_title = Label.new()
	win_title.text = "★ ★ ★\n%s" % LanguageService.get_ui_text("well_done")
	win_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	win_title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	win_title.add_theme_color_override("font_color", Color("#d97816"))
	win_title.add_theme_color_override("font_outline_color", Color.WHITE)
	win_title.add_theme_constant_override("outline_size", 4)
	win_panel.add_child(win_title)
	win_message = Label.new()
	win_message.text = LanguageService.get_ui_text("bought_everything")
	win_message.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	win_message.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	win_message.add_theme_color_override("font_color", Color("#74451f"))
	win_panel.add_child(win_message)
	again_button = Button.new()
	again_button.text = LanguageService.get_ui_text("again")
	again_button.focus_mode = Control.FOCUS_NONE
	_apply_result_button_style(again_button, Color("#59b653"))
	again_button.pressed.connect(_restart_game)
	win_panel.add_child(again_button)
	back_button = Button.new()
	back_button.text = LanguageService.get_ui_text("back")
	back_button.focus_mode = Control.FOCUS_NONE
	_apply_result_button_style(back_button, Color("#4f91d1"))
	back_button.pressed.connect(_go_home)
	win_panel.add_child(back_button)
func _apply_result_button_style(button: Button, color: Color) -> void:
	for state in ["normal", "hover", "pressed"]:
		var style := StyleBoxFlat.new()
		style.bg_color = color.darkened(0.14) if state == "pressed" else color
		style.set_corner_radius_all(18)
		style.border_width_bottom = 5
		style.border_color = color.darkened(0.28)
		style.shadow_color = Color(0, 0, 0, 0.20)
		style.shadow_size = 6
		style.shadow_offset = Vector2(0, 3)
		button.add_theme_stylebox_override(state, style)
	button.add_theme_color_override("font_color", Color.WHITE)
	button.add_theme_color_override("font_hover_color", Color.WHITE)
	button.add_theme_color_override("font_pressed_color", Color.WHITE)
func _panel_style(fill: Color, border: Color, border_width: int, radius: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.border_color = border
	style.set_border_width_all(border_width)
	style.set_corner_radius_all(radius)
	style.shadow_color = Color(0.32, 0.18, 0.08, 0.18)
	style.shadow_size = 8
	style.shadow_offset = Vector2(0.0, 5.0)
	return style
func _build_list_rows() -> void:
	for _index in range(list_size):
		var row := Panel.new()
		row.mouse_filter = Control.MOUSE_FILTER_IGNORE
		row.add_theme_stylebox_override("panel", _panel_style(
			Color("#fffdf8"), Color("#ecd19e"), 2, 14
		))
		background_layer.add_child(row)
		list_rows.append(row)
		var icon := TextureRect.new()
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
		row.add_child(icon)
		list_icons.append(icon)
		var label := Label.new()
		label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		label.add_theme_color_override("font_color", Color("#65401f"))
		label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		row.add_child(label)
		list_labels.append(label)
		var check := Label.new()
		check.text = "✓"
		check.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		check.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		check.add_theme_color_override("font_color", Color("#53aa4e"))
		check.visible = false
		check.mouse_filter = Control.MOUSE_FILTER_IGNORE
		row.add_child(check)
		list_checks.append(check)
func _create_shopping_list() -> void:
	target_products.clear()
	collected_names.clear()
	score = 0
	var indices: Array[int] = []
	for index in range(products_data.size()):
		indices.append(index)
	indices.shuffle()
	var count: int = mini(list_size, products_data.size())
	for index in range(count):
		target_products.append(products_data[indices[index]])
	for index in range(list_rows.size()):
		var active := index < target_products.size()
		list_rows[index].visible = active
		if active:
			var data: Dictionary = target_products[index]
			list_icons[index].texture = data.get("texture") as Texture2D
			list_labels[index].text = String(data.get("name", ""))
			list_checks[index].visible = false
			list_rows[index].modulate = Color.WHITE
	_update_score()
func _spawn_products() -> void:
	for child in items_root.get_children():
		items_root.remove_child(child)
		child.queue_free()
	product_items.clear()
	var pool: Array[Dictionary] = target_products.duplicate()
	var others: Array[Dictionary] = []
	for data in products_data:
		var product_name := String(data.get("name", ""))
		var is_target := false
		for target in target_products:
			if String(target.get("name", "")) == product_name:
				is_target = true
				break
		if not is_target:
			others.append(data)
	others.shuffle()
	var desired_count: int = mini(PRODUCT_POSITIONS.size(), products_data.size())
	while pool.size() < desired_count and not others.is_empty():
		pool.append(others.pop_back())
	pool.shuffle()
	for data in pool:
		var item = product_scene.instantiate()
		items_root.add_child(item)
		item.product_name = String(data.get("name", ""))
		item.sprite.texture = data.get("texture") as Texture2D
		item.product_voice = data.get("voice") as AudioStream
		item.dropped_in_basket.connect(_on_item_dropped_in_basket)
		item.dropped_wrong.connect(_on_item_dropped_wrong)
		product_items.append(item)
func _layout_for_viewport() -> void:
	var viewport_size: Vector2 = get_viewport_rect().size
	if viewport_size.x <= 0.0 or viewport_size.y <= 0.0:
		return
	var safe_scale: float = minf(viewport_size.x / REFERENCE_SIZE.x, viewport_size.y / REFERENCE_SIZE.y)
	safe_scale = clampf(safe_scale, 0.62, 1.4)
	var floor_top: float = viewport_size.y * 0.78
	wall.position = Vector2.ZERO
	wall.size = Vector2(viewport_size.x, floor_top)
	floor.position = Vector2(0.0, floor_top)
	floor.size = Vector2(viewport_size.x, viewport_size.y - floor_top)
	var shelf_scale: float = minf(
		viewport_size.x * 0.66 / SHELF_VISIBLE_RECT.size.x,
		viewport_size.y * 0.86 / SHELF_VISIBLE_RECT.size.y
	)
	var shelf_size: Vector2 = SHELF_VISIBLE_RECT.size * shelf_scale
	shelf_sprite.scale = Vector2.ONE * shelf_scale
	shelf_sprite.position = Vector2(viewport_size.x * 0.655, viewport_size.y * 0.48)
	var shelf_top_left: Vector2 = shelf_sprite.position - shelf_size * 0.5
	var product_size: float = minf(shelf_size.x * 0.105, shelf_size.y * 0.165)
	for index in range(product_items.size()):
		var item = product_items[index]
		if not is_instance_valid(item):
			continue
		var start: Vector2 = shelf_top_left + shelf_size * PRODUCT_POSITIONS[index]
		item.set_display_size(Vector2.ONE * product_size)
		if not item.dragging:
			item.set_start_position(start)
	var basket_width: float = minf(viewport_size.x * 0.19, shelf_size.x * 0.25)
	var basket_scale: float = basket_width / float(BASKET_TEXTURE.get_width())
	basket_sprite.scale = Vector2.ONE * basket_scale
	basket_sprite.position = Vector2(shelf_sprite.position.x, viewport_size.y * 0.86)
	basket_area.position = basket_sprite.position
	var basket_size := Vector2(
		basket_width * 0.78,
		float(BASKET_TEXTURE.get_height()) * basket_scale * 0.55
	)
	(basket_collision.shape as RectangleShape2D).size = basket_size
	var list_rect := Rect2(
		viewport_size.x * 0.025,
		viewport_size.y * 0.20,
		viewport_size.x * 0.255,
		viewport_size.y * 0.70
	)
	list_card.position = list_rect.position
	list_card.size = list_rect.size
	var list_padding: float = 13.0 * safe_scale
	var title_height: float = 54.0 * safe_scale
	list_title.position = Vector2(list_rect.position.x, list_rect.position.y + 5.0 * safe_scale)
	list_title.size = Vector2(list_rect.size.x, title_height)
	list_title.add_theme_font_size_override("font_size", int(29.0 * safe_scale))
	var rows_top: float = list_rect.position.y + title_height + 7.0 * safe_scale
	var rows_height: float = list_rect.end.y - rows_top - list_padding
	var row_gap: float = 7.0 * safe_scale
	var row_height: float = (rows_height - row_gap * float(list_rows.size() - 1)) / float(maxi(list_rows.size(), 1))
	for index in range(list_rows.size()):
		var row := list_rows[index]
		row.position = Vector2(
			list_rect.position.x + list_padding,
			rows_top + float(index) * (row_height + row_gap)
		)
		row.size = Vector2(list_rect.size.x - list_padding * 2.0, row_height)
		var icon_size: float = row_height * 0.82
		list_icons[index].position = Vector2(5.0 * safe_scale, row_height * 0.09)
		list_icons[index].size = Vector2.ONE * icon_size
		list_labels[index].position = Vector2(icon_size + 11.0 * safe_scale, 0.0)
		list_labels[index].size = Vector2(row.size.x - icon_size - 43.0 * safe_scale, row_height)
		list_labels[index].add_theme_font_size_override("font_size", int(24.0 * safe_scale))
		list_checks[index].position = Vector2(row.size.x - 35.0 * safe_scale, 0.0)
		list_checks[index].size = Vector2(32.0, row_height) * safe_scale
		list_checks[index].add_theme_font_size_override("font_size", int(28.0 * safe_scale))
	var button_size: float = 106.0 * safe_scale
	var edge: float = 18.0 * safe_scale
	home_button.position = Vector2(edge, edge)
	home_button.size = Vector2.ONE * button_size
	var score_size: Vector2 = Vector2(225.0, 88.0) * safe_scale
	score_back.position = Vector2(viewport_size.x - score_size.x - edge, edge)
	score_back.size = score_size
	score_icon.position = Vector2(9.0, 7.0) * safe_scale
	score_icon.size = Vector2.ONE * 72.0 * safe_scale
	score_label.position = Vector2(82.0, 4.0) * safe_scale
	score_label.size = Vector2(132.0, 80.0) * safe_scale
	score_label.add_theme_font_size_override("font_size", int(42.0 * safe_scale))
	error_flash.position = Vector2.ZERO
	error_flash.size = viewport_size
	basket_error_mark.position = basket_sprite.position - Vector2.ONE * 65.0 * safe_scale
	basket_error_mark.size = Vector2.ONE * 130.0 * safe_scale
	basket_error_mark.add_theme_font_size_override("font_size", int(100.0 * safe_scale))
	win_overlay.position = Vector2.ZERO
	win_overlay.size = viewport_size
	var panel_size := Vector2(
		minf(viewport_size.x * 0.76, 680.0 * safe_scale),
		minf(viewport_size.y * 0.74, 390.0 * safe_scale)
	)
	panel_size.x = maxf(panel_size.x, 400.0 * safe_scale)
	panel_size.y = maxf(panel_size.y, 230.0 * safe_scale)
	win_panel.position = (viewport_size - panel_size) * 0.5
	win_panel.size = panel_size
	win_title.position = Vector2(panel_size.x * 0.06, panel_size.y * 0.04)
	win_title.size = Vector2(panel_size.x * 0.88, panel_size.y * 0.35)
	win_title.add_theme_font_size_override("font_size", int(clampf(panel_size.y * 0.115, 28.0, 48.0)))
	win_message.position = Vector2(panel_size.x * 0.06, panel_size.y * 0.40)
	win_message.size = Vector2(panel_size.x * 0.88, panel_size.y * 0.16)
	win_message.add_theme_font_size_override("font_size", int(clampf(panel_size.y * 0.070, 18.0, 29.0)))
	var result_button_size := Vector2(panel_size.x * 0.36, panel_size.y * 0.22)
	var result_button_y := panel_size.y * 0.66
	again_button.position = Vector2(panel_size.x * 0.10, result_button_y)
	again_button.size = result_button_size
	back_button.position = Vector2(panel_size.x * 0.54, result_button_y)
	back_button.size = result_button_size
	var result_font_size := int(clampf(panel_size.y * 0.075, 20.0, 30.0))
	again_button.add_theme_font_size_override("font_size", result_font_size)
	back_button.add_theme_font_size_override("font_size", result_font_size)
func _on_item_dropped_in_basket(item) -> void:
	if game_over:
		return
	var is_target := false
	for data in target_products:
		if String(data.get("name", "")) == item.product_name:
			is_target = true
			break
	if is_target and not collected_names.has(item.product_name):
		collected_names.append(item.product_name)
		score += 1
		_update_score()
		GameState.last_score = score
		GameState.add_coins(1)
		_mark_collected(item.product_name)
		if correct_sound:
			SFX.play_2d(correct_sound, basket_area.global_position, -6.0)
		SFX.play_praise(basket_area.global_position, 0.45)
		item.queue_free()
		if collected_names.size() >= target_products.size():
			_end_game()
	else:
		_show_error()
		item.reset_to_start()
func _on_item_dropped_wrong(item) -> void:
	if not game_over:
		item.reset_to_start()
func _mark_collected(product_name: String) -> void:
	for index in range(target_products.size()):
		if String(target_products[index].get("name", "")) == product_name:
			list_checks[index].visible = true
			list_rows[index].modulate = Color(0.72, 0.72, 0.72, 1.0)
			return
func _show_error() -> void:
	SFX.play_retry(basket_area.global_position)
	if wrong_sound:
		SFX.play_2d(wrong_sound, basket_area.global_position, -4.0)
	error_flash.visible = true
	error_flash.color.a = 0.42
	basket_error_mark.visible = true
	basket_error_mark.modulate.a = 1.0
	var flash_tween := create_tween()
	flash_tween.tween_property(error_flash, "color:a", 0.0, 0.42)
	flash_tween.finished.connect(func() -> void: error_flash.visible = false)
	var mark_tween := create_tween()
	mark_tween.tween_property(basket_error_mark, "modulate:a", 0.0, 0.55)
	mark_tween.finished.connect(func() -> void: basket_error_mark.visible = false)
func _update_score() -> void:
	score_label.text = str(GameState.get_coin_balance())
func _go_home() -> void:
	SFX.transition_to_scene(results_scene_path)
func _restart_game() -> void:
	get_tree().reload_current_scene()
func _end_game() -> void:
	if game_over:
		return
	game_over = true
	GameState.last_score = score
	await get_tree().create_timer(0.45).timeout
	if is_inside_tree():
		win_overlay.visible = true
