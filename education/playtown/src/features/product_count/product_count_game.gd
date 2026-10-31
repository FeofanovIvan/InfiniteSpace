extends Node2D

const ProductSourceScript := preload("res://education/playtown/src/features/product_count/product_source.gd")
const ProductCatalog := preload("res://education/playtown/src/features/shared/product_catalog.gd")
const GAME_FONT: Font = preload("res://education/playtown/assets/ui/fonts/RobotoCondensed-Variable.ttf")
const BACK_TEXTURE: Texture2D = preload("res://education/playtown/assets/ui/back_arrow.png")
const STAR_TEXTURE: Texture2D = preload("res://education/playtown/assets/ui/star.png")
const BACKGROUND_TEXTURE: Texture2D = preload("res://education/playtown/assets/product_count/background.webp")
const BASKET_TEXTURE: Texture2D = preload("res://education/playtown/assets/product_count/basket.webp")
const CORRECT_SOUND: AudioStream = preload("res://education/playtown/audio/sfx/correct.ogg")
const WRONG_SOUND: AudioStream = preload("res://education/playtown/audio/sfx/wrong.ogg")
const BACK_SCENE := "res://education/playtown/scenes/screens/game_select_shop.tscn"
const ROUNDS_TO_WIN := 5

var ui: Control
var background: TextureRect
var title_label: Label
var instruction_label: Label
var back_button: Button
var back_icon: TextureRect
var progress_panel: Panel
var progress_icon: TextureRect
var progress_label: Label
var list_panel: Panel
var list_title: Label
var list_rows: Array[Panel] = []
var list_icon_slots: Array[Array] = []
var list_equals: Array[Label] = []
var list_numbers: Array[Label] = []
var list_checks: Array[Label] = []
var basket: TextureRect
var basket_content: Control
var shelf: Panel
var shelf_bars: Array[Panel] = []
var source_layer: Control
var feedback_layer: Control
var win_overlay: Control
var win_panel: Panel
var voice_player: AudioStreamPlayer
var quantity_voice_player: AudioStreamPlayer
var quantity_voice_sequence := 0

var rng := RandomNumberGenerator.new()
var entries: Array[Dictionary] = []
var sources: Array[ProductCountSource] = []
var basket_products: Array[ProductCountSource] = []
var rounds_completed := 0
var input_locked := false
var last_remove_time_ms := -1000
var products: Array[Dictionary] = []


func _ready() -> void:
	products = ProductCatalog.all(LanguageService.current_locale)
	rng.randomize()
	_build_ui()
	get_viewport().size_changed.connect(_layout)
	_layout()
	_start_round()
	call_deferred("_play_intro")


func _play_intro() -> void:
	var stream := LanguageService.get_game_voice("collect_product_count_intro")
	if stream == null:
		return
	voice_player.stream = stream
	voice_player.play()


func _build_ui() -> void:
	ui = Control.new()
	ui.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(ui)
	background = TextureRect.new()
	background.texture = BACKGROUND_TEXTURE
	background.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	background.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ui.add_child(background)

	title_label = _label(LanguageService.get_ui_text("product_count_title"), 38, Color("#71421f"))
	title_label.visible = false
	ui.add_child(title_label)
	instruction_label = _label(LanguageService.get_ui_text("product_count_instruction"), 22, Color("#8b5225"))
	instruction_label.visible = false
	ui.add_child(instruction_label)

	back_button = GameExitButton.new()
	back_button.pressed.connect(_go_back)
	ui.add_child(back_button)
	back_icon = TextureRect.new()
	back_icon.texture = BACK_TEXTURE
	back_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	back_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	back_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	back_icon.visible = false
	back_button.add_child(back_icon)

	progress_panel = GameScorePanel.new()
	ui.add_child(progress_panel)
	progress_icon = (progress_panel as GameScorePanel).score_icon
	progress_label = (progress_panel as GameScorePanel).score_label
	progress_label.text = str(GameState.get_coin_balance())
	GameState.coin_balance_changed.connect(func(balance: int) -> void: progress_label.text = str(balance))

	list_panel = Panel.new()
	list_panel.add_theme_stylebox_override("panel", _style(Color("#fffaf0"), Color("#d99a42"), 4, 24))
	ui.add_child(list_panel)
	list_title = _label(LanguageService.get_ui_text("shopping_list"), 28, Color("#71421f"))
	list_panel.add_child(list_title)
	for row_index in range(3):
		var row := Panel.new()
		row.add_theme_stylebox_override("panel", _style(Color("#fffdf7"), Color("#efd39f"), 2, 16))
		list_panel.add_child(row)
		list_rows.append(row)
		var slots: Array[TextureRect] = []
		for _slot_index in range(5):
			var icon := TextureRect.new()
			icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
			row.add_child(icon)
			slots.append(icon)
		list_icon_slots.append(slots)
		var equals := _label("=", 32, Color("#815027"))
		row.add_child(equals)
		list_equals.append(equals)
		var number := _label("0", 43, Color("#e2781a"))
		row.add_child(number)
		list_numbers.append(number)
		var check := _label("✓", 42, Color("#45a83f"))
		check.add_theme_color_override("font_outline_color", Color.WHITE)
		check.add_theme_constant_override("outline_size", 5)
		check.visible = false
		row.add_child(check)
		list_checks.append(check)

	basket = TextureRect.new()
	basket.texture = BASKET_TEXTURE
	basket.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	basket.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	basket.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ui.add_child(basket)
	basket_content = Control.new()
	basket_content.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ui.add_child(basket_content)
	shelf = Panel.new()
	shelf.add_theme_stylebox_override("panel", _style(Color("#f6ca78"), Color("#a96628"), 7, 24))
	shelf.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ui.add_child(shelf)
	for _index in range(4):
		var bar := Panel.new()
		bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
		bar.add_theme_stylebox_override("panel", _style(Color("#d98a35"), Color("#9b5724"), 3, 8))
		shelf.add_child(bar)
		shelf_bars.append(bar)
	source_layer = Control.new()
	source_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ui.add_child(source_layer)
	feedback_layer = Control.new()
	feedback_layer.set_anchors_preset(Control.PRESET_FULL_RECT)
	feedback_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ui.add_child(feedback_layer)
	voice_player = AudioStreamPlayer.new()
	voice_player.bus = "VOICE"
	add_child(voice_player)
	quantity_voice_player = AudioStreamPlayer.new()
	quantity_voice_player.bus = "VOICE"
	add_child(quantity_voice_player)
	_build_win_overlay()


func _build_win_overlay() -> void:
	win_overlay = Control.new()
	win_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	win_overlay.visible = false
	win_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	ui.add_child(win_overlay)
	var dim := ColorRect.new()
	dim.color = Color(0.12, 0.07, 0.03, 0.55)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	win_overlay.add_child(dim)
	win_panel = Panel.new()
	win_panel.add_theme_stylebox_override("panel", _style(Color("#fff5cf"), Color("#f0a326"), 6, 30))
	win_overlay.add_child(win_panel)
	var heading := _label("★ ★ ★\n%s" % LanguageService.get_ui_text("well_done"), 46, Color("#db791c"))
	heading.name = "Heading"
	win_panel.add_child(heading)
	var message := _label(LanguageService.get_ui_text("all_products_correct"), 27, Color("#71421f"))
	message.name = "Message"
	win_panel.add_child(message)
	var again := Button.new()
	again.name = "Again"
	again.text = LanguageService.get_ui_text("again")
	again.focus_mode = Control.FOCUS_NONE
	_style_button(again, Color("#58b457"))
	again.pressed.connect(_restart)
	win_panel.add_child(again)
	var back := Button.new()
	back.name = "Back"
	back.text = LanguageService.get_ui_text("back")
	back.focus_mode = Control.FOCUS_NONE
	_style_button(back, Color("#4c91d0"))
	back.pressed.connect(_go_back)
	win_panel.add_child(back)


func _start_round() -> void:
	input_locked = false
	instruction_label.text = LanguageService.get_ui_text("product_count_instruction")
	_clear_sources()
	_clear_basket_products()
	entries.clear()
	var available: Array[Dictionary] = products.duplicate()
	available.shuffle()
	for index in range(3):
		var target := rng.randi_range(1, 5)
		var current := 1
		if index == 0:
			target = rng.randi_range(3, 5)
			current = maxi(1, target - rng.randi_range(1, 2))
		elif index == 1:
			target = rng.randi_range(1, 3)
			current = mini(5, target + rng.randi_range(1, 2))
		else:
			current = target + (1 if target < 5 else -1)
		entries.append({"product": available[index], "target": target, "current": current, "is_correct": current == target})
	_update_list()
	_create_sources(available)
	_refresh_basket()


func _create_sources(available: Array[Dictionary]) -> void:
	var shelf_products: Array[Dictionary] = []
	for entry in entries:
		shelf_products.append(entry.product)
	for candidate in available:
		if shelf_products.size() >= 6:
			break
		if not shelf_products.has(candidate):
			shelf_products.append(candidate)
	shelf_products.shuffle()
	for data in shelf_products:
		var source := ProductSourceScript.new() as ProductCountSource
		source.configure(data.key, data.texture, null)
		source.product_dropped.connect(_on_product_added)
		source_layer.add_child(source)
		sources.append(source)
	_layout_sources()


func _on_product_added(key: String) -> void:
	if input_locked:
		return
	var index := _entry_index(key)
	if index < 0:
		SFX.play_2d(WRONG_SOUND, get_viewport_rect().size * 0.5, -6.0)
		SFX.play_retry(get_viewport_rect().size * 0.5)
		_show_instruction(LanguageService.get_ui_text("product_not_listed"), Color("#bd4c35"))
		return
	var entry: Dictionary = entries[index]
	if int(entry.current) >= 5:
		SFX.play_2d(WRONG_SOUND, get_viewport_rect().size * 0.5, -7.0)
		SFX.play_retry(get_viewport_rect().size * 0.5)
		_show_instruction(LanguageService.get_ui_text("basket_already_five"), Color("#bd4c35"))
		return
	entry.current = int(entry.current) + 1
	entries[index] = entry
	var became_correct := _sync_entry_correct_state(index)
	_show_quantity_feedback(1)
	_refresh_basket()
	_update_list()
	if became_correct:
		_confirm_correct_quantity(index)
	_check_round()


func _on_product_removed(key: String) -> void:
	if input_locked:
		return
	var now := Time.get_ticks_msec()
	if now - last_remove_time_ms < 180:
		return
	last_remove_time_ms = now
	var index := _entry_index(key)
	if index < 0:
		return
	var entry: Dictionary = entries[index]
	if int(entry.current) <= 0:
		return
	entry.current = int(entry.current) - 1
	entries[index] = entry
	var became_correct := _sync_entry_correct_state(index)
	_show_quantity_feedback(-1)
	_refresh_basket()
	_update_list()
	if became_correct:
		_confirm_correct_quantity(index)
	_check_round()


func _sync_entry_correct_state(index: int) -> bool:
	var entry: Dictionary = entries[index]
	var was_correct := bool(entry.get("is_correct", false))
	var is_correct := int(entry.current) == int(entry.target)
	entry["is_correct"] = is_correct
	entries[index] = entry
	return is_correct and not was_correct


func _confirm_correct_quantity(index: int) -> void:
	if index < 0 or index >= entries.size():
		return
	quantity_voice_sequence += 1
	quantity_voice_player.stop()
	var target := int(entries[index].target)
	var number_stream := LanguageService.get_number_voice(target)
	if number_stream != null:
		quantity_voice_player.stream = number_stream
		quantity_voice_player.play()
	var check := list_checks[index]
	check.scale = Vector2.ONE * 0.45
	var tween := create_tween()
	tween.tween_property(check, "scale", Vector2(1.15, 1.15), 0.16).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(check, "scale", Vector2.ONE, 0.10)


func _check_round() -> void:
	for entry in entries:
		if int(entry.current) != int(entry.target):
			return
	_finish_round()


func _finish_round() -> void:
	input_locked = true
	rounds_completed += 1
	GameState.add_coins(1)
	SFX.play_2d(CORRECT_SOUND, get_viewport_rect().size * 0.5, -5.0)
	SFX.play_praise(get_viewport_rect().size * 0.5, 0.45)
	_show_instruction(LanguageService.get_ui_text("product_count_complete"), Color("#438f39"))
	var tween := create_tween()
	tween.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(basket, "scale", Vector2.ONE * 1.06, 0.15)
	tween.tween_property(basket, "scale", Vector2.ONE, 0.16)
	await get_tree().create_timer(1.15).timeout
	if not is_inside_tree():
		return
	if rounds_completed >= ROUNDS_TO_WIN:
		win_overlay.visible = true
	else:
		_start_round()


func _update_list() -> void:
	for row_index in range(3):
		if row_index >= entries.size():
			continue
		var entry: Dictionary = entries[row_index]
		var target := int(entry.target)
		for slot_index in range(5):
			var icon: TextureRect = list_icon_slots[row_index][slot_index]
			icon.texture = entry.product.texture
			icon.visible = slot_index < target
		list_numbers[row_index].text = str(target)
		var current := int(entry.current)
		var fill := Color("#fffdf7")
		var border := Color("#efd39f")
		if current == target:
			fill = Color("#e8f8d7")
			border = Color("#73b94a")
		elif current > target:
			fill = Color("#fff0dc")
			border = Color("#e89542")
		list_rows[row_index].add_theme_stylebox_override("panel", _style(fill, border, 3, 16))
		list_checks[row_index].visible = current == target


func _refresh_basket() -> void:
	_clear_basket_products()
	for entry in entries:
		for _count in range(int(entry.current)):
			var item := ProductSourceScript.new() as ProductCountSource
			item.configure(entry.product.key, entry.product.texture, null)
			item.accept_drop_inside = false
			item.product_dropped.connect(_on_product_removed)
			basket_content.add_child(item)
			basket_products.append(item)
	_layout_basket_products()


func _layout() -> void:
	var view := get_viewport_rect().size
	var scale_factor: float = minf(view.x / 1536.0, view.y / 768.0)
	var edge := maxf(18.0, 30.0 * scale_factor)
	background.position = Vector2.ZERO
	background.size = view
	var exit_side := maxf(62.0, 76.0 * scale_factor)
	back_button.size = Vector2.ONE * exit_side
	back_button.position = Vector2(view.x - edge - exit_side, edge)
	back_icon.position = Vector2.ONE * exit_side * 0.12
	back_icon.size = Vector2.ONE * exit_side * 0.76
	progress_panel.size = Vector2(maxf(130.0, 150.0 * scale_factor), exit_side)
	progress_panel.position = Vector2(back_button.position.x - progress_panel.size.x - maxf(10.0, 14.0 * scale_factor), edge)

	var content_top := edge + exit_side + maxf(10.0, 16.0 * scale_factor)
	var content_height := view.y - content_top - edge
	var list_width := minf(320.0 * scale_factor, view.x * 0.215)
	list_panel.position = Vector2(edge, content_top)
	list_panel.size = Vector2(list_width, content_height)
	list_title.position = Vector2(10, 6) * scale_factor
	list_title.size = Vector2(list_width - 20 * scale_factor, 40 * scale_factor)
	list_title.add_theme_font_size_override("font_size", maxi(16, int(23 * scale_factor)))
	var rows_top := 50.0 * scale_factor
	var row_gap := 11.0 * scale_factor
	var row_height := (content_height - rows_top - row_gap * 3.0) / 3.0
	for row_index in range(3):
		var row := list_rows[row_index]
		row.position = Vector2(11 * scale_factor, rows_top + row_index * (row_height + row_gap))
		row.size = Vector2(list_width - 22 * scale_factor, row_height)
		_layout_list_row(row_index, scale_factor)

	var right_width := minf(330.0 * scale_factor, view.x * 0.225)
	var right_x := view.x - edge - right_width
	shelf.position = Vector2(right_x, content_top)
	shelf.size = Vector2(right_width, content_height)
	_layout_shelf_bars(scale_factor)
	var center_left := edge + list_width + 16 * scale_factor
	var center_right := right_x - 14 * scale_factor
	var basket_width := center_right - center_left
	var basket_height := minf(content_height * 0.92, basket_width * 0.68)
	basket.position = Vector2(center_left, content_top + (content_height - basket_height) * 0.5)
	basket.size = Vector2(basket_width, basket_height)
	basket.pivot_offset = basket.size * 0.5
	basket_content.position = basket.position
	basket_content.size = basket.size
	_layout_sources()
	_layout_basket_products()
	_layout_win(view, scale_factor)


func _layout_list_row(row_index: int, scale_factor: float) -> void:
	var row := list_rows[row_index]
	var icon_area_width := row.size.x * 0.62
	var icon_size := minf(row.size.y * 0.43, icon_area_width / 5.4)
	var gap := (icon_area_width - icon_size * 5.0) / 4.0
	for slot_index in range(5):
		var icon: TextureRect = list_icon_slots[row_index][slot_index]
		icon.position = Vector2(10 * scale_factor + slot_index * (icon_size + gap), (row.size.y - icon_size) * 0.5)
		icon.size = Vector2.ONE * icon_size
	list_equals[row_index].position = Vector2(row.size.x * 0.64, 0)
	list_equals[row_index].size = Vector2(row.size.x * 0.10, row.size.y)
	list_equals[row_index].add_theme_font_size_override("font_size", maxi(20, int(32 * scale_factor)))
	list_numbers[row_index].position = Vector2(row.size.x * 0.73, 0)
	list_numbers[row_index].size = Vector2(row.size.x * 0.14, row.size.y)
	list_numbers[row_index].add_theme_font_size_override("font_size", maxi(25, int(43 * scale_factor)))
	list_checks[row_index].position = Vector2(row.size.x * 0.87, 0)
	list_checks[row_index].size = Vector2(row.size.x * 0.12, row.size.y)
	list_checks[row_index].pivot_offset = list_checks[row_index].size * 0.5
	list_checks[row_index].add_theme_font_size_override("font_size", maxi(24, int(42 * scale_factor)))


func _layout_shelf_bars(scale_factor: float) -> void:
	if shelf_bars.is_empty():
		return
	var padding := maxf(8.0, 14.0 * scale_factor)
	var bar_height := maxf(8.0, 13.0 * scale_factor)
	var usable_height := shelf.size.y - padding * 2.0
	for index in range(shelf_bars.size()):
		var bar := shelf_bars[index]
		var y := padding + usable_height * float(index) / 3.0 - bar_height * 0.5
		bar.position = Vector2(padding, y)
		bar.size = Vector2(shelf.size.x - padding * 2.0, bar_height)


func _layout_sources() -> void:
	if sources.is_empty() or shelf.size.x <= 0.0:
		return
	var inner := Rect2(shelf.position + shelf.size * Vector2(0.10, 0.055), shelf.size * Vector2(0.80, 0.89))
	var cell := Vector2(inner.size.x / 2.0, inner.size.y / 3.0)
	var basket_target := Rect2(basket.position + basket.size * Vector2(0.10, 0.12), basket.size * Vector2(0.80, 0.74))
	for index in range(sources.size()):
		var side := minf(cell.x * 0.66, cell.y * 0.62)
		var col := index % 2
		var row := index / 2
		var center := inner.position + Vector2((col + 0.5) * cell.x, (row + 0.5) * cell.y)
		sources[index].set_home(Rect2(center - Vector2.ONE * side * 0.5, Vector2.ONE * side))
		sources[index].basket_rect = basket_target


func _layout_basket_products() -> void:
	if basket_products.is_empty() or basket.size.x <= 0.0:
		return
	var interior := Rect2(basket.size * Vector2(0.12, 0.15), basket.size * Vector2(0.76, 0.66))
	var global_basket_rect := Rect2(basket.position, basket.size)
	var grouped: Dictionary = {}
	for item in basket_products:
		if not grouped.has(item.product_key):
			grouped[item.product_key] = []
		grouped[item.product_key].append(item)
	for row_index in range(entries.size()):
		var key: String = entries[row_index].product.key
		var items: Array = grouped.get(key, [])
		var row_height := interior.size.y / 3.0
		var side := minf(row_height * 0.82, interior.size.x / 6.2)
		var gap := side * 0.08
		var total_width := items.size() * side + maxi(0, items.size() - 1) * gap
		var start_x := interior.position.x + (interior.size.x - total_width) * 0.5
		for item_index in range(items.size()):
			var item: ProductCountSource = items[item_index]
			item.set_home(Rect2(
				Vector2(start_x + item_index * (side + gap), interior.position.y + row_index * row_height + (row_height - side) * 0.5),
				Vector2.ONE * side
			))
			item.pivot_offset = item.size * 0.5
			item.basket_rect = global_basket_rect


func _show_quantity_feedback(delta: int) -> void:
	var label := _label("+1" if delta > 0 else "−1", 58, Color("#51a93f") if delta > 0 else Color("#db5b43"))
	label.add_theme_color_override("font_outline_color", Color.WHITE)
	label.add_theme_constant_override("outline_size", 8)
	label.size = Vector2(150, 82)
	label.position = basket.position + Vector2(
		basket.size.x * 0.5 - label.size.x * 0.5,
		basket.size.y * 0.12
	)
	label.scale = Vector2.ONE * 0.7
	label.pivot_offset = label.size * 0.5
	feedback_layer.add_child(label)
	var tween := create_tween().set_parallel(true)
	tween.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(label, "scale", Vector2.ONE, 0.18)
	tween.tween_property(label, "position:y", label.position.y - 55.0, 0.72)
	tween.tween_property(label, "modulate:a", 0.0, 0.72).set_delay(0.28)
	tween.finished.connect(label.queue_free)
	_play_quantity_voice("plus" if delta > 0 else "minus")


func _play_quantity_voice(operation: String) -> void:
	quantity_voice_sequence += 1
	var sequence := quantity_voice_sequence
	var operation_stream := LanguageService.get_math_voice(operation)
	var one_stream := LanguageService.get_number_voice(1)
	quantity_voice_player.stop()
	if operation_stream == null:
		if one_stream != null:
			quantity_voice_player.stream = one_stream
			quantity_voice_player.play()
		return
	quantity_voice_player.stream = operation_stream
	quantity_voice_player.play()
	await quantity_voice_player.finished
	if sequence != quantity_voice_sequence or not is_inside_tree() or one_stream == null:
		return
	quantity_voice_player.stream = one_stream
	quantity_voice_player.play()


func _layout_win(view: Vector2, scale_factor: float) -> void:
	var panel_size := Vector2(560, 410) * scale_factor
	win_panel.position = (view - panel_size) * 0.5
	win_panel.size = panel_size
	var heading := win_panel.get_node("Heading") as Label
	heading.position = Vector2(30, 25) * scale_factor
	heading.size = Vector2(500, 130) * scale_factor
	heading.add_theme_font_size_override("font_size", maxi(30, int(46 * scale_factor)))
	var message := win_panel.get_node("Message") as Label
	message.position = Vector2(30, 155) * scale_factor
	message.size = Vector2(500, 55) * scale_factor
	message.add_theme_font_size_override("font_size", maxi(19, int(27 * scale_factor)))
	var again := win_panel.get_node("Again") as Button
	again.position = Vector2(55, 235) * scale_factor
	again.size = Vector2(450, 62) * scale_factor
	again.add_theme_font_size_override("font_size", maxi(19, int(27 * scale_factor)))
	var back := win_panel.get_node("Back") as Button
	back.position = Vector2(55, 315) * scale_factor
	back.size = Vector2(450, 62) * scale_factor
	back.add_theme_font_size_override("font_size", maxi(19, int(27 * scale_factor)))


func _show_instruction(text: String, color: Color) -> void:
	instruction_label.text = text
	instruction_label.add_theme_color_override("font_color", color)
	var tween := create_tween()
	tween.tween_interval(0.85)
	tween.tween_callback(func() -> void:
		if not input_locked:
			instruction_label.text = LanguageService.get_ui_text("product_count_instruction")
			instruction_label.add_theme_color_override("font_color", Color("#8b5225"))
	)


func _entry_index(key: String) -> int:
	for index in range(entries.size()):
		if String(entries[index].product.key) == key:
			return index
	return -1


func _clear_sources() -> void:
	for source in sources:
		source.queue_free()
	sources.clear()


func _clear_basket_products() -> void:
	for item in basket_products:
		item.queue_free()
	basket_products.clear()


func _restart() -> void:
	win_overlay.visible = false
	rounds_completed = 0
	progress_label.text = str(GameState.get_coin_balance())
	_start_round()


func _go_back() -> void:
	SFX.transition_to_scene(BACK_SCENE)


func _label(text_value: String, font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = text_value
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_override("font", GAME_FONT)
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return label


func _style(fill: Color, border: Color, width: int, radius: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.border_color = border
	style.set_border_width_all(width)
	style.set_corner_radius_all(radius)
	style.shadow_color = Color(0.25, 0.12, 0.03, 0.18)
	style.shadow_size = 6
	style.shadow_offset = Vector2(0, 4)
	return style


func _style_button(button: Button, color: Color) -> void:
	button.add_theme_font_override("font", GAME_FONT)
	button.add_theme_stylebox_override("normal", _style(color, color.darkened(0.25), 3, 18))
	button.add_theme_stylebox_override("hover", _style(color.lightened(0.06), color.darkened(0.25), 3, 18))
	button.add_theme_stylebox_override("pressed", _style(color.darkened(0.12), color.darkened(0.30), 3, 18))
	button.add_theme_color_override("font_color", Color.WHITE)
	button.add_theme_color_override("font_hover_color", Color.WHITE)
	button.add_theme_color_override("font_pressed_color", Color.WHITE)
