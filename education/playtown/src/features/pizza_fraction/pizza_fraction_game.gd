extends Node2D

const PIZZA_TEXTURE: Texture2D = preload("res://education/playtown/assets/pizza_game/pizza.webp")
const BACKGROUND_TEXTURE: Texture2D = preload("res://education/playtown/assets/product_count/background.webp")
const BASKET_TEXTURE: Texture2D = preload("res://education/playtown/assets/product_count/basket.webp")
const GAME_FONT: Font = preload("res://education/playtown/assets/ui/fonts/RobotoCondensed-Variable.ttf")
const CORRECT_SOUND: AudioStream = preload("res://education/playtown/audio/sfx/correct.ogg")
const BACK_SCENE := "res://education/playtown/scenes/screens/game_select_shop.tscn"
const REFERENCE_SIZE := Vector2(1536.0, 768.0)
const DENOMINATORS := [2, 3, 4, 5, 6, 8, 9, 10]
const MAX_SLICES := 10

var ui: Control
var background: TextureRect
var left_panel: Panel
var center_panel: Panel
var right_panel: Panel
var list_header: Panel
var list_title: Label
var target_text: Label
var mini_slices: Array[TextureRect] = []
var basket: TextureRect
var basket_slices: Array[TextureRect] = []
var basket_lines: Array[Line2D] = []
var equals_label: Label
var numerator_label: Label
var fraction_line: ColorRect
var denominator_label: Label
var source_slices: Array[TextureRect] = []
var source_lines: Array[Line2D] = []
var pizza_input: Control
var home_button: GameExitButton
var score_panel: GameScorePanel
var voice_player: AudioStreamPlayer

var rng := RandomNumberGenerator.new()
var denominator := 2
var target_count := 1
var collected_count := 0
var score := 0
var input_locked := false
var drag_index := -1
var drag_offset := Vector2.ZERO
var source_home_position := Vector2.ZERO
var source_pizza_rect := Rect2()
var basket_drop_rect := Rect2()
var taken: Array[bool] = []


func _ready() -> void:
	rng.randomize()
	_build_ui()
	get_viewport().size_changed.connect(_layout)
	_layout()
	_start_round()


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

	left_panel = _panel(Color("#fffaf0"), Color("#d99a42"))
	center_panel = _transparent_panel()
	right_panel = _transparent_panel()
	ui.add_child(left_panel)
	ui.add_child(center_panel)
	ui.add_child(right_panel)

	list_header = _panel(Color("#ffc34d"), Color("#cb7b20"))
	left_panel.add_child(list_header)
	list_title = _label(LanguageService.get_ui_text("shopping_list"), 30, Color("#74451f"))
	list_title.add_theme_color_override("font_outline_color", Color(1.0, 0.97, 0.82, 0.95))
	list_title.add_theme_constant_override("outline_size", 4)
	list_header.add_child(list_title)
	target_text = _label("", 31, Color("#71421f"))
	target_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	left_panel.add_child(target_text)
	for index in range(MAX_SLICES):
		var mini := _pizza_view()
		mini.mouse_filter = Control.MOUSE_FILTER_IGNORE
		left_panel.add_child(mini)
		mini_slices.append(mini)

	basket = TextureRect.new()
	basket.texture = BASKET_TEXTURE
	basket.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	basket.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	basket.mouse_filter = Control.MOUSE_FILTER_IGNORE
	center_panel.add_child(basket)
	for _index in range(MAX_SLICES):
		var slice := _pizza_view()
		center_panel.add_child(slice)
		basket_slices.append(slice)
	for _index in range(MAX_SLICES):
		var line := Line2D.new()
		line.default_color = Color(1.0, 1.0, 1.0, 0.86)
		line.width = 4.0
		line.z_index = 5
		center_panel.add_child(line)
		basket_lines.append(line)

	var fraction_color := Color("#4f9d45")
	var fraction_outline := Color("#6d3f20")
	equals_label = _label("=", 52, fraction_color)
	equals_label.add_theme_color_override("font_outline_color", fraction_outline)
	equals_label.add_theme_constant_override("outline_size", 4)
	equals_label.visible = false
	center_panel.add_child(equals_label)
	numerator_label = _label("0", 48, fraction_color)
	numerator_label.add_theme_color_override("font_outline_color", fraction_outline)
	numerator_label.add_theme_constant_override("outline_size", 4)
	numerator_label.visible = false
	center_panel.add_child(numerator_label)
	fraction_line = ColorRect.new()
	fraction_line.color = fraction_color
	fraction_line.visible = false
	fraction_line.mouse_filter = Control.MOUSE_FILTER_IGNORE
	center_panel.add_child(fraction_line)
	denominator_label = _label("0", 48, fraction_color)
	denominator_label.add_theme_color_override("font_outline_color", fraction_outline)
	denominator_label.add_theme_constant_override("outline_size", 4)
	denominator_label.visible = false
	center_panel.add_child(denominator_label)

	for _index in range(MAX_SLICES):
		var source := _pizza_view()
		source.z_index = 2
		ui.add_child(source)
		source_slices.append(source)
	pizza_input = Control.new()
	pizza_input.mouse_filter = Control.MOUSE_FILTER_STOP
	pizza_input.z_index = 20
	pizza_input.gui_input.connect(_on_pizza_gui_input)
	ui.add_child(pizza_input)

	home_button = GameExitButton.new()
	home_button.z_index = 100
	home_button.pressed.connect(_go_back)
	ui.add_child(home_button)
	score_panel = GameScorePanel.new()
	score_panel.z_index = 100
	score_panel.score_label.add_theme_font_override("font", GAME_FONT)
	score_panel.set_score(score)
	ui.add_child(score_panel)
	voice_player = AudioStreamPlayer.new()
	voice_player.bus = "VOICE"
	add_child(voice_player)


func _start_round() -> void:
	input_locked = false
	drag_index = -1
	collected_count = 0
	denominator = int(DENOMINATORS[rng.randi_range(0, DENOMINATORS.size() - 1)])
	target_count = rng.randi_range(1, denominator - 1)
	taken.clear()
	for index in range(MAX_SLICES):
		taken.append(false)
	_configure_round_visuals()
	_layout()
	call_deferred("_play_round_instruction")


func _configure_round_visuals() -> void:
	target_text.text = _target_sentence(target_count, denominator)
	for index in range(MAX_SLICES):
		var active := index < denominator
		source_slices[index].visible = active
		basket_slices[index].visible = false
		mini_slices[index].visible = index < target_count
		if active:
			source_slices[index].material = _slice_material(index, denominator)
		if index < target_count:
			mini_slices[index].stretch_mode = TextureRect.STRETCH_SCALE
			mini_slices[index].material = _canonical_slice_material(denominator)
	equals_label.visible = false
	numerator_label.visible = false
	fraction_line.visible = false
	denominator_label.visible = false
	_update_cut_lines()


func _on_pizza_gui_input(event: InputEvent) -> void:
	if input_locked or drag_index >= 0:
		return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		_begin_slice_drag(get_global_mouse_position())
		pizza_input.accept_event()
	elif event is InputEventScreenTouch and event.pressed:
		_begin_slice_drag(pizza_input.get_global_transform() * event.position)
		pizza_input.accept_event()


func _input(event: InputEvent) -> void:
	if drag_index < 0:
		return
	if event is InputEventMouseMotion and Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		_move_slice_drag(event.position)
		get_viewport().set_input_as_handled()
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and not event.pressed:
		_finish_slice_drag(event.position)
		get_viewport().set_input_as_handled()
	elif event is InputEventScreenDrag:
		_move_slice_drag(event.position)
		get_viewport().set_input_as_handled()
	elif event is InputEventScreenTouch and not event.pressed:
		_finish_slice_drag(event.position)
		get_viewport().set_input_as_handled()


func _begin_slice_drag(pointer: Vector2) -> void:
	var center := source_pizza_rect.get_center()
	var relative := pointer - center
	var radius := source_pizza_rect.size.x * 0.5
	if relative.length() > radius * 0.94:
		return
	var angle := atan2(relative.y, relative.x) + PI * 0.5
	angle = fposmod(angle, TAU)
	var index := clampi(floori(angle / (TAU / float(denominator))), 0, denominator - 1)
	if taken[index]:
		return
	drag_index = index
	var slice := source_slices[index]
	source_home_position = slice.position
	drag_offset = slice.global_position - pointer
	slice.z_index = 60
	var tween := create_tween()
	tween.tween_property(slice, "scale", Vector2(1.07, 1.07), 0.10).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func _move_slice_drag(pointer: Vector2) -> void:
	if drag_index < 0:
		return
	source_slices[drag_index].global_position = pointer + drag_offset


func _finish_slice_drag(pointer: Vector2) -> void:
	if drag_index < 0:
		return
	var index := drag_index
	drag_index = -1
	var source := source_slices[index]
	source.scale = Vector2.ONE
	source.z_index = 2
	if basket_drop_rect.has_point(pointer):
		taken[index] = true
		source.visible = false
		basket_slices[collected_count].stretch_mode = TextureRect.STRETCH_SCALE
		basket_slices[collected_count].material = _canonical_slice_material(denominator)
		basket_slices[collected_count].visible = true
		collected_count += 1
		if collected_count >= target_count:
			_finish_round()
	else:
		var tween := create_tween()
		tween.tween_property(source, "position", source_home_position, 0.20).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func _finish_round() -> void:
	input_locked = true
	equals_label.visible = true
	numerator_label.text = str(target_count)
	numerator_label.visible = true
	fraction_line.visible = true
	denominator_label.text = str(denominator)
	denominator_label.visible = true
	score += 1
	score_panel.set_score(score)
	GameState.last_score = score
	GameState.add_coins(1)
	SFX.play_2d(CORRECT_SOUND, get_viewport_rect().size * 0.5, -5.0)
	var tween := create_tween()
	tween.tween_property(center_panel, "scale", Vector2(1.025, 1.025), 0.14).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(center_panel, "scale", Vector2.ONE, 0.12)
	await _play_fraction_result()
	SFX.play_praise(get_viewport_rect().size * 0.5, 0.55)
	await get_tree().create_timer(1.2).timeout
	if is_inside_tree():
		_start_round()


func _play_round_instruction() -> void:
	var action := LanguageService.get_pizza_voice("PIZZA_ACTION_001")
	if action == null:
		return
	var piece_form := 1 if target_count == 1 else (2 if target_count <= 4 else 3)
	var quantity_stream := LanguageService.get_pizza_voice("PIZZA_NUM_%03d" % target_count)
	if quantity_stream == null:
		quantity_stream = LanguageService.get_number_voice(target_count)
	await _play_voice_sequence([
		action,
		quantity_stream,
		LanguageService.get_pizza_voice("PIZZA_PIECES_%03d" % piece_form),
		LanguageService.get_pizza_voice("PIZZA_TOTAL_%03d" % denominator),
	])


func _play_fraction_result() -> void:
	var denominator_stream := LanguageService.get_pizza_voice(
		"FRACTION_DEN_%s_%03d" % ["S" if target_count == 1 else "P", denominator]
	)
	if denominator_stream == null:
		await _play_voice_sequence([LanguageService.get_number_voice(target_count)])
		return
	var numerator_stream: AudioStream
	if target_count <= 2:
		numerator_stream = LanguageService.get_pizza_voice("FRACTION_NUM_%03d" % target_count)
	else:
		numerator_stream = LanguageService.get_number_voice(target_count)
	await _play_voice_sequence([numerator_stream, denominator_stream])


func _play_voice_sequence(streams: Array) -> void:
	voice_player.stop()
	for stream in streams:
		if stream == null or not is_inside_tree():
			continue
		voice_player.stream = stream
		voice_player.play()
		await voice_player.finished


func _layout() -> void:
	if ui == null:
		return
	var view := get_viewport_rect().size
	var scale_factor := minf(view.x / REFERENCE_SIZE.x, view.y / REFERENCE_SIZE.y)
	var safe_scale := clampf(scale_factor, 0.54, 1.35)
	var safe := _safe_area_insets(view)
	var edge := 22.0 * safe_scale
	var left := safe.x + edge
	var top := safe.y + edge
	var right := view.x - safe.z - edge
	var bottom := view.y - safe.w - edge
	background.position = Vector2.ZERO
	background.size = view
	var exit_side := 78.0 * safe_scale
	var score_size := Vector2(185.0, 72.0) * safe_scale
	home_button.position = Vector2(right - exit_side, top)
	home_button.size = Vector2.ONE * exit_side
	score_panel.position = Vector2(home_button.position.x - score_size.x - 12.0 * safe_scale, top)
	score_panel.size = score_size
	var content_top := top + exit_side + 14.0 * safe_scale
	var content_height := bottom - content_top
	var total_width := right - left
	var gap := 16.0 * safe_scale
	var left_width := total_width * 0.25
	var center_width := total_width * 0.40
	var right_width := total_width - left_width - center_width - gap * 2.0
	left_panel.position = Vector2(left, content_top)
	left_panel.size = Vector2(left_width, content_height)
	center_panel.position = Vector2(left + left_width + gap, content_top)
	center_panel.size = Vector2(center_width, content_height)
	center_panel.pivot_offset = center_panel.size * 0.5
	right_panel.position = Vector2(center_panel.position.x + center_width + gap, content_top)
	right_panel.size = Vector2(right_width, content_height)

	var header_margin := 14.0 * safe_scale
	var header_height := minf(62.0 * safe_scale, content_height * 0.15)
	list_header.position = Vector2(header_margin, header_margin)
	list_header.size = Vector2(left_width - header_margin * 2.0, header_height)
	list_title.position = Vector2(8.0, 0.0) * safe_scale
	list_title.size = Vector2(list_header.size.x - 16.0 * safe_scale, header_height)
	list_title.add_theme_font_size_override("font_size", maxi(18, int(29 * safe_scale)))
	var mini_area := Rect2(
		Vector2(header_margin, header_margin + header_height + 12.0 * safe_scale),
		Vector2(left_width - header_margin * 2.0, content_height * 0.48)
	)
	var columns := mini(target_count, 5)
	var rows := ceili(float(target_count) / float(maxi(columns, 1)))
	var piece_gap := 5.0 * safe_scale
	var slice_aspect := _slice_aspect(denominator)
	var mini_cell_width := (mini_area.size.x - piece_gap * float(maxi(columns - 1, 0))) / float(maxi(columns, 1))
	var mini_cell_height := (mini_area.size.y - piece_gap * float(maxi(rows - 1, 0))) / float(maxi(rows, 1))
	var mini_height := minf(82.0 * safe_scale, minf(mini_cell_height, mini_cell_width / slice_aspect))
	var mini_width := mini_height * slice_aspect
	var grid_width := mini_width * float(columns) + piece_gap * float(maxi(columns - 1, 0))
	var grid_height := mini_height * float(rows) + piece_gap * float(maxi(rows - 1, 0))
	var mini_start := mini_area.position + (mini_area.size - Vector2(grid_width, grid_height)) * 0.5
	for index in range(MAX_SLICES):
		var column := index % maxi(columns, 1)
		var row := index / maxi(columns, 1)
		mini_slices[index].position = mini_start + Vector2(
			float(column) * (mini_width + piece_gap),
			float(row) * (mini_height + piece_gap)
		)
		mini_slices[index].size = Vector2(mini_width, mini_height)
		mini_slices[index].z_index = 0
	target_text.position = Vector2(header_margin, content_height * 0.72)
	target_text.size = Vector2(left_width - header_margin * 2.0, content_height * 0.22)
	target_text.add_theme_font_size_override("font_size", maxi(18, int(28 * safe_scale)))

	var basket_center := Vector2(center_width * 0.50, content_height * 0.39)
	var basket_visible_size := Vector2(center_width * 0.94, content_height * 0.55)
	basket.size = basket_visible_size
	basket.pivot_offset = basket.size * 0.5
	basket.position = basket_center - basket.size * 0.5
	basket.rotation = 0.0
	var basket_columns := mini(target_count, 5)
	var basket_rows := ceili(float(target_count) / float(maxi(basket_columns, 1)))
	var basket_inner := Vector2(basket_visible_size.x * 0.62, basket_visible_size.y * 0.48)
	var basket_gap := 4.0 * safe_scale
	var basket_cell_width := (basket_inner.x - basket_gap * float(maxi(basket_columns - 1, 0))) / float(maxi(basket_columns, 1))
	var basket_cell_height := (basket_inner.y - basket_gap * float(maxi(basket_rows - 1, 0))) / float(maxi(basket_rows, 1))
	var piece_height := minf(76.0 * safe_scale, minf(basket_cell_height, basket_cell_width / slice_aspect))
	var piece_width := piece_height * slice_aspect
	var basket_grid_size := Vector2(
		piece_width * float(basket_columns) + basket_gap * float(maxi(basket_columns - 1, 0)),
		piece_height * float(basket_rows) + basket_gap * float(maxi(basket_rows - 1, 0))
	)
	var basket_grid_start := basket_center - basket_grid_size * 0.5
	for index in range(MAX_SLICES):
		var basket_column := index % maxi(basket_columns, 1)
		var basket_row := index / maxi(basket_columns, 1)
		basket_slices[index].position = basket_grid_start + Vector2(
			float(basket_column) * (piece_width + basket_gap),
			float(basket_row) * (piece_height + basket_gap)
		)
		basket_slices[index].size = Vector2(piece_width, piece_height)
	for line in basket_lines:
		line.visible = false
	basket_drop_rect = Rect2(center_panel.position + basket_center - basket_visible_size * 0.5, basket_visible_size)

	var fraction_y := content_height * 0.76
	equals_label.position = Vector2(center_width * 0.28, fraction_y)
	equals_label.size = Vector2(center_width * 0.16, content_height * 0.16)
	var fraction_x := center_width * 0.48
	var fraction_width := center_width * 0.22
	numerator_label.position = Vector2(fraction_x, fraction_y - content_height * 0.035)
	numerator_label.size = Vector2(fraction_width, content_height * 0.10)
	fraction_line.position = Vector2(fraction_x + fraction_width * 0.10, fraction_y + content_height * 0.067)
	fraction_line.size = Vector2(fraction_width * 0.80, maxf(3.0, 5.0 * safe_scale))
	denominator_label.position = Vector2(fraction_x, fraction_y + content_height * 0.07)
	denominator_label.size = Vector2(fraction_width, content_height * 0.10)

	var source_side := minf(right_width * 0.92, content_height * 0.88)
	var source_center := right_panel.position + Vector2(right_width * 0.5, content_height * 0.52)
	source_pizza_rect = Rect2(source_center - Vector2.ONE * source_side * 0.5, Vector2.ONE * source_side)
	for index in range(MAX_SLICES):
		if drag_index != index:
			source_slices[index].position = source_pizza_rect.position
		source_slices[index].size = source_pizza_rect.size
	pizza_input.position = source_pizza_rect.position
	pizza_input.size = source_pizza_rect.size


func _layout_lines(lines: Array[Line2D], center: Vector2, radius: float, count: int, parent_offset: Vector2) -> void:
	for index in range(lines.size()):
		var line := lines[index]
		line.visible = index < count
		if not line.visible:
			continue
		var angle := -PI * 0.5 + TAU * float(index) / float(count)
		var local_center := center - parent_offset
		line.points = PackedVector2Array([local_center, local_center + Vector2(cos(angle), sin(angle)) * radius])


func _update_cut_lines() -> void:
	if source_pizza_rect.size.x > 0.0:
		_layout()


func _pizza_view() -> TextureRect:
	var view := TextureRect.new()
	view.texture = PIZZA_TEXTURE
	view.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	view.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	view.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return view


func _slice_material(index: int, count: int) -> ShaderMaterial:
	var shader := Shader.new()
	shader.code = """
shader_type canvas_item;
uniform float slice_start = 0.0;
uniform float slice_end = 1.0;
uniform float edge_gap = 0.012;
void fragment() {
	vec2 point = UV - vec2(0.5);
	float angle = atan(point.y, point.x) + 1.57079632679;
	if (angle < 0.0) { angle += 6.28318530718; }
	if (angle >= 6.28318530718) { angle -= 6.28318530718; }
	float mask = step(slice_start + edge_gap, angle) * step(angle, slice_end - edge_gap);
	vec4 color = texture(TEXTURE, UV);
	color.a *= mask;
	COLOR = color;
}
"""
	var material := ShaderMaterial.new()
	material.shader = shader
	var step_angle := TAU / float(count)
	material.set_shader_parameter("slice_start", float(index) * step_angle)
	material.set_shader_parameter("slice_end", float(index + 1) * step_angle)
	material.set_shader_parameter("edge_gap", minf(0.012, step_angle * 0.08))
	return material


func _canonical_slice_material(count: int) -> ShaderMaterial:
	var shader := Shader.new()
	shader.code = """
shader_type canvas_item;
uniform float half_angle = 0.31415926535;
uniform float sample_width = 0.30901699437;
void fragment() {
	vec2 sample_uv = vec2(
		0.5 + (UV.x - 0.5) * sample_width,
		UV.y * 0.5
	);
	vec2 point = sample_uv - vec2(0.5);
	float angle = atan(point.y, point.x) + 1.57079632679;
	if (angle < 0.0) { angle += 6.28318530718; }
	if (angle >= 6.28318530718) { angle -= 6.28318530718; }
	float mask = max(
		step(angle, half_angle),
		step(6.28318530718 - half_angle, angle)
	);
	vec4 color = texture(TEXTURE, sample_uv);
	color.a *= mask;
	COLOR = color;
}
"""
	var material := ShaderMaterial.new()
	material.shader = shader
	var half_angle := PI / float(count)
	material.set_shader_parameter("half_angle", half_angle)
	material.set_shader_parameter("sample_width", maxf(0.08, sin(half_angle)))
	return material


func _slice_aspect(count: int) -> float:
	return maxf(0.20, 2.0 * sin(PI / float(maxi(count, 2))))


func _target_sentence(amount: int, whole: int) -> String:
	match LanguageService.current_locale:
		"ru":
			var noun := "кусок" if amount == 1 else ("куска" if amount >= 2 and amount <= 4 else "кусков")
			return "%d %s пиццы из %d" % [amount, noun, whole]
		"pt": return "%d pedaços de pizza de %d" % [amount, whole]
		"es": return "%d porciones de pizza de %d" % [amount, whole]
		"fr": return "%d parts de pizza sur %d" % [amount, whole]
		"de": return "%d Pizzastücke von %d" % [amount, whole]
		_: return "%d pizza slices out of %d" % [amount, whole]


func _panel(fill: Color, border: Color) -> Panel:
	var panel := Panel.new()
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.border_color = border
	style.set_border_width_all(5)
	style.set_corner_radius_all(25)
	style.shadow_color = Color(0.18, 0.09, 0.02, 0.24)
	style.shadow_size = 8
	style.shadow_offset = Vector2(0, 5)
	panel.add_theme_stylebox_override("panel", style)
	return panel


func _transparent_panel() -> Panel:
	var panel := Panel.new()
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_theme_stylebox_override("panel", StyleBoxEmpty.new())
	return panel


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


func _safe_area_insets(viewport_size: Vector2) -> Vector4:
	if OS.get_name() not in ["iOS", "Android"]:
		return Vector4.ZERO
	var window_size := Vector2(DisplayServer.window_get_size())
	var safe_rect := DisplayServer.get_display_safe_area()
	if window_size.x <= 0.0 or window_size.y <= 0.0 or safe_rect.size.x <= 0 or safe_rect.size.y <= 0:
		return Vector4.ZERO
	var scale_to_view := viewport_size / window_size
	var right_px := maxf(0.0, window_size.x - float(safe_rect.position.x + safe_rect.size.x))
	var bottom_px := maxf(0.0, window_size.y - float(safe_rect.position.y + safe_rect.size.y))
	return Vector4(
		float(safe_rect.position.x) * scale_to_view.x,
		float(safe_rect.position.y) * scale_to_view.y,
		right_px * scale_to_view.x,
		bottom_px * scale_to_view.y
	)


func _go_back() -> void:
	SFX.transition_to_scene(BACK_SCENE)
