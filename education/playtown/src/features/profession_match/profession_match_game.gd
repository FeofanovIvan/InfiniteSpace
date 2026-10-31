extends Node2D

const BACKGROUND_TEXTURE: Texture2D = preload("res://education/playtown/assets/background/character_select_bg.jpg")
const WHEEL_TEXTURE: Texture2D = preload("res://education/playtown/assets/profession_game/professions_wheel.webp")
const GAME_FONT: Font = preload("res://education/playtown/assets/ui/fonts/RobotoCondensed-Variable.ttf")
const HOME_SCENE := "res://education/playtown/scenes/screens/game_select_home.tscn"
const REFERENCE_SIZE := Vector2(1536.0, 768.0)
const PROFESSION_COUNT := 8
const ITEMS_PER_PROFESSION := 4
const SECTOR_ANGLE := TAU / float(PROFESSION_COUNT)
const NEUTRAL_ROTATION := SECTOR_ANGLE * 0.5
const WHEEL_SECTOR_TO_PROFESSION := [0, 1, 2, 3, 4, 7, 6, 5]

var background: TextureRect
var tint: ColorRect
var wheel: TextureRect
var arrow_shadow: Polygon2D
var arrow: Polygon2D
var item_view: TextureRect
var home_button: GameExitButton
var score_panel: GameScorePanel
var item_order: Array[int] = []
var current_profession_index := 0
var current_item_index := 0
var input_locked := false
var is_rotating := false
var pointer_last_angle := 0.0
var rotation_distance := 0.0
var score := 0
var correct_player: AudioStreamPlayer
var wrong_player: AudioStreamPlayer
var voice_player: AudioStreamPlayer
var intro_played := false


func _ready() -> void:
	randomize()
	_build_ui()
	_refill_item_order()
	get_viewport().size_changed.connect(_layout)
	_layout()
	_start_round()
	call_deferred("_play_intro_and_item")


func _build_ui() -> void:
	background = TextureRect.new()
	background.texture = BACKGROUND_TEXTURE
	background.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	background.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	background.z_index = -20
	background.material = _blur_material()
	add_child(background)

	tint = ColorRect.new()
	tint.color = Color(0.91, 0.96, 1.0, 0.28)
	tint.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tint.z_index = -10
	add_child(tint)

	wheel = TextureRect.new()
	wheel.texture = WHEEL_TEXTURE
	wheel.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	wheel.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	wheel.mouse_filter = Control.MOUSE_FILTER_STOP
	wheel.gui_input.connect(_on_wheel_gui_input)
	add_child(wheel)

	arrow_shadow = Polygon2D.new()
	arrow_shadow.color = Color("#fff2a8")
	arrow_shadow.z_index = 18
	add_child(arrow_shadow)
	arrow = Polygon2D.new()
	arrow.color = Color("#ff2d55")
	arrow.z_index = 19
	add_child(arrow)

	item_view = TextureRect.new()
	item_view.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	item_view.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	item_view.mouse_filter = Control.MOUSE_FILTER_IGNORE
	item_view.z_index = 25
	item_view.material = _item_edge_material()
	add_child(item_view)

	home_button = GameExitButton.new()
	home_button.z_index = 200
	home_button.pressed.connect(_go_home)
	add_child(home_button)
	score_panel = GameScorePanel.new()
	score_panel.z_index = 200
	score_panel.score_label.add_theme_font_override("font", GAME_FONT)
	add_child(score_panel)

	correct_player = AudioStreamPlayer.new()
	correct_player.stream = preload("res://education/playtown/audio/sfx/correct.ogg")
	correct_player.bus = "SFX"
	add_child(correct_player)
	wrong_player = AudioStreamPlayer.new()
	wrong_player.stream = preload("res://education/playtown/audio/sfx/wrong.ogg")
	wrong_player.bus = "SFX"
	add_child(wrong_player)
	voice_player = AudioStreamPlayer.new()
	voice_player.bus = "VOICE"
	add_child(voice_player)


func _start_round() -> void:
	input_locked = false
	is_rotating = false
	item_view.modulate = Color.WHITE
	item_view.scale = Vector2.ONE
	if item_order.is_empty():
		_refill_item_order()
	current_item_index = int(item_order.pop_back())
	current_profession_index = floori(float(current_item_index) / float(ITEMS_PER_PROFESSION))
	item_view.texture = load("res://education/playtown/assets/profession_game/items/item_%02d.webp" % (current_item_index + 1))
	wheel.rotation = NEUTRAL_ROTATION
	if intro_played:
		call_deferred("_play_current_item")


func _refill_item_order() -> void:
	item_order.clear()
	for index in range(PROFESSION_COUNT * ITEMS_PER_PROFESSION):
		item_order.append(index)
	item_order.shuffle()


func _on_wheel_gui_input(event: InputEvent) -> void:
	if input_locked:
		return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			_begin_rotation(get_global_mouse_position())
		else:
			_finish_rotation()
		wheel.accept_event()
	elif event is InputEventMouseMotion and is_rotating and Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		_rotate_to_pointer(get_global_mouse_position())
		wheel.accept_event()
	elif event is InputEventScreenTouch:
		if event.pressed:
			_begin_rotation(wheel.get_global_transform() * event.position)
		else:
			_finish_rotation()
		wheel.accept_event()
	elif event is InputEventScreenDrag and is_rotating:
		_rotate_to_pointer(wheel.get_global_transform() * event.position)
		wheel.accept_event()


func _begin_rotation(pointer: Vector2) -> void:
	var distance_from_center := pointer.distance_to(_wheel_center())
	var wheel_radius := wheel.size.x * 0.5
	if distance_from_center < wheel_radius * 0.34 or distance_from_center > wheel_radius * 1.02:
		return
	is_rotating = true
	rotation_distance = 0.0
	pointer_last_angle = _pointer_angle(pointer)
	var tween := create_tween()
	tween.tween_property(wheel, "scale", Vector2(1.015, 1.015), 0.09)


func _rotate_to_pointer(pointer: Vector2) -> void:
	var angle := _pointer_angle(pointer)
	var angle_step := wrapf(angle - pointer_last_angle, -PI, PI)
	wheel.rotation += angle_step
	rotation_distance += absf(angle_step)
	pointer_last_angle = angle


func _finish_rotation() -> void:
	if not is_rotating:
		return
	is_rotating = false
	var scale_tween := create_tween()
	scale_tween.tween_property(wheel, "scale", Vector2.ONE, 0.10)
	if rotation_distance < 0.035:
		return
	input_locked = true
	var selected_sector := posmod(roundi(-wheel.rotation / SECTOR_ANGLE), PROFESSION_COUNT)
	var selected_profession: int = WHEEL_SECTOR_TO_PROFESSION[selected_sector]
	var target_rotation := -float(selected_sector) * SECTOR_ANGLE
	target_rotation += TAU * roundf((wheel.rotation - target_rotation) / TAU)
	var tween := create_tween()
	tween.tween_property(wheel, "rotation", target_rotation, 0.28).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	await tween.finished
	if selected_profession == current_profession_index:
		await _handle_correct()
	else:
		await _handle_wrong()


func _pointer_angle(pointer: Vector2) -> float:
	return (pointer - _wheel_center()).angle()


func _wheel_center() -> Vector2:
	return wheel.get_global_transform() * wheel.pivot_offset


func _handle_correct() -> void:
	correct_player.play()
	var result_voice: Array = [LanguageService.get_profession_voice(current_profession_index)]
	if LanguageService.learning_locale == "ru":
		result_voice.append(LanguageService.get_profession_item_voice(current_item_index))
	await _play_voice_sequence(result_voice)
	SFX.play_praise(get_viewport_rect().size * 0.5, 1.0)
	score += 1
	score_panel.set_score(score)
	GameState.last_score = score
	GameState.add_coins(1)
	var tween := create_tween()
	tween.tween_property(item_view, "scale", Vector2(1.16, 1.16), 0.14).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(item_view, "scale", Vector2.ZERO, 0.20).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
	await tween.finished
	await get_tree().create_timer(0.45).timeout
	_start_round()


func _play_intro_and_item() -> void:
	await _play_voice_sequence([LanguageService.get_profession_action_voice()])
	intro_played = true
	_play_current_item()


func _play_current_item() -> void:
	_play_voice_sequence([LanguageService.get_profession_item_voice(current_item_index)])


func _play_voice_sequence(streams: Array) -> void:
	voice_player.stop()
	for stream in streams:
		if stream == null or not is_inside_tree():
			continue
		voice_player.stream = stream
		voice_player.play()
		await voice_player.finished


func _handle_wrong() -> void:
	wrong_player.play()
	SFX.play_retry(get_viewport_rect().size * 0.5)
	var original_position := item_view.position
	var shake := create_tween()
	shake.tween_property(item_view, "position:x", original_position.x - 10.0, 0.06)
	shake.tween_property(item_view, "position:x", original_position.x + 10.0, 0.08)
	shake.tween_property(item_view, "position:x", original_position.x, 0.06)
	await shake.finished
	input_locked = false


func _layout() -> void:
	var viewport_size := get_viewport_rect().size
	var scale_factor := minf(viewport_size.x / REFERENCE_SIZE.x, viewport_size.y / REFERENCE_SIZE.y)
	var safe_scale := clampf(scale_factor, 0.54, 1.35)
	var safe := _safe_area_insets(viewport_size)
	var edge := 18.0 * safe_scale
	var left := safe.x + edge
	var top := safe.y + edge
	var right := viewport_size.x - safe.z - edge
	var bottom := viewport_size.y - safe.w - edge
	background.position = Vector2.ZERO
	background.size = viewport_size
	tint.position = Vector2.ZERO
	tint.size = viewport_size

	var home_size := Vector2.ONE * 88.0 * safe_scale
	var score_size := Vector2(205.0, 76.0) * safe_scale
	home_button.position = Vector2(left, top)
	home_button.size = home_size
	score_panel.position = Vector2(right - score_size.x, top)
	score_panel.size = score_size

	var available_size := Vector2(right - left, bottom - top)
	var wheel_side := minf(available_size.y, available_size.x * 0.72)
	wheel_side = maxf(280.0 * safe_scale, wheel_side)
	var wheel_center := Vector2((left + right) * 0.5, (top + bottom) * 0.5)
	wheel.position = wheel_center - Vector2.ONE * wheel_side * 0.5
	wheel.size = Vector2.ONE * wheel_side
	wheel.pivot_offset = wheel.size * 0.5

	var item_side := wheel_side * 0.185
	item_view.size = Vector2(item_side, item_side * 1.08)
	item_view.pivot_offset = item_view.size * 0.5
	item_view.position = wheel_center - item_view.size * 0.5

	var inner_radius := wheel_side * 0.055
	var target_radius := wheel_side * 0.405
	var shaft_half := wheel_side * 0.015
	var head_half := wheel_side * 0.050
	var head_base_y := -target_radius + wheel_side * 0.075
	var arrow_points := PackedVector2Array([
		Vector2(-shaft_half, -inner_radius),
		Vector2(-shaft_half, head_base_y),
		Vector2(-head_half, head_base_y),
		Vector2(0.0, -target_radius),
		Vector2(head_half, head_base_y),
		Vector2(shaft_half, head_base_y),
		Vector2(shaft_half, -inner_radius)
	])
	var outline_points := PackedVector2Array([
		Vector2(-shaft_half - wheel_side * 0.007, -inner_radius + wheel_side * 0.008),
		Vector2(-shaft_half - wheel_side * 0.007, head_base_y + wheel_side * 0.008),
		Vector2(-head_half - wheel_side * 0.010, head_base_y + wheel_side * 0.008),
		Vector2(0.0, -target_radius - wheel_side * 0.012),
		Vector2(head_half + wheel_side * 0.010, head_base_y + wheel_side * 0.008),
		Vector2(shaft_half + wheel_side * 0.007, head_base_y + wheel_side * 0.008),
		Vector2(shaft_half + wheel_side * 0.007, -inner_radius + wheel_side * 0.008)
	])
	arrow.position = wheel_center
	arrow.polygon = arrow_points
	arrow_shadow.position = wheel_center + Vector2(0.0, 4.0 * safe_scale)
	arrow_shadow.polygon = outline_points


func _blur_material() -> ShaderMaterial:
	var shader := Shader.new()
	shader.code = """
shader_type canvas_item;
uniform float blur_strength = 2.4;
void fragment() {
	vec2 p = TEXTURE_PIXEL_SIZE * blur_strength;
	vec4 c = texture(TEXTURE, UV) * 0.20;
	c += texture(TEXTURE, UV + vec2(p.x, 0.0)) * 0.12;
	c += texture(TEXTURE, UV - vec2(p.x, 0.0)) * 0.12;
	c += texture(TEXTURE, UV + vec2(0.0, p.y)) * 0.12;
	c += texture(TEXTURE, UV - vec2(0.0, p.y)) * 0.12;
	c += texture(TEXTURE, UV + p) * 0.08;
	c += texture(TEXTURE, UV - p) * 0.08;
	c += texture(TEXTURE, UV + vec2(p.x, -p.y)) * 0.08;
	c += texture(TEXTURE, UV + vec2(-p.x, p.y)) * 0.08;
	COLOR = c;
}
"""
	var material := ShaderMaterial.new()
	material.shader = shader
	return material


func _item_edge_material() -> ShaderMaterial:
	var shader := Shader.new()
	shader.code = """
shader_type canvas_item;
void fragment() {
	vec4 color = texture(TEXTURE, UV);
	float edge = min(min(UV.x, 1.0 - UV.x), min(UV.y, 1.0 - UV.y));
	color.a *= smoothstep(0.0, 0.11, edge);
	COLOR = color;
}
"""
	var material := ShaderMaterial.new()
	material.shader = shader
	return material


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


func _go_home() -> void:
	SFX.transition_to_scene(HOME_SCENE)
