extends Node2D

const STAR_TEXTURE: Texture2D = preload("res://education/playtown/assets/ui/star.png")
const BACKGROUND_TEXTURE: Texture2D = preload("res://education/playtown/assets/animal_habitat/ui/background.webp")
const SEA_HABITAT_SCRIPT := preload("res://education/playtown/src/features/animal_habitat/sea_habitat.gd")
const ROUNDED_MASK_SCRIPT := preload("res://education/playtown/src/features/animal_habitat/rounded_corner_mask.gd")
const GAME_FONT: Font = preload("res://education/playtown/assets/ui/fonts/RobotoCondensed-Variable.ttf")
const HOME_SCENE := "res://education/playtown/scenes/screens/game_select_home.tscn"
const REFERENCE_SIZE := Vector2(1536.0, 768.0)
const HABITATS := ["wild", "farm", "sky", "sea"]
const HABITAT_COLORS := {
	"wild": Color("#4d923e"),
	"farm": Color("#d28a32"),
	"sky": Color("#489ad1"),
	"sea": Color("#167db9")
}
const HABITAT_BACKGROUNDS := {
	"wild": "res://education/playtown/assets/animal_habitat/backgrounds/forest.webp",
	"farm": "res://education/playtown/assets/animal_habitat/backgrounds/farm.webp",
	"sky": "res://education/playtown/assets/animal_habitat/backgrounds/sky.webp"
}
const ANIMALS := [
	{"name": "Рыба", "habitat": "sea", "texture": "sea_fish"},
	{"name": "Дельфин", "habitat": "sea", "texture": "sea_dolphin"},
	{"name": "Кит", "habitat": "sea", "texture": "sea_whale"},
	{"name": "Акула", "habitat": "sea", "texture": "sea_shark"},
	{"name": "Осьминог", "habitat": "sea", "texture": "sea_octopus"},
	{"name": "Медуза", "habitat": "sea", "texture": "sea_jellyfish"},
	{"name": "Краб", "habitat": "sea", "texture": "sea_crab"},
	{"name": "Морская звезда", "habitat": "sea", "texture": "sea_starfish"},
	{"name": "Морской конёк", "habitat": "sea", "texture": "sea_seahorse"},
	{"name": "Морская черепаха", "habitat": "sea", "texture": "sea_turtle"},
	{"name": "Корова", "habitat": "farm", "texture": "farm_cow"},
	{"name": "Свинья", "habitat": "farm", "texture": "farm_pig"},
	{"name": "Лошадь", "habitat": "farm", "texture": "farm_horse"},
	{"name": "Овца", "habitat": "farm", "texture": "farm_sheep"},
	{"name": "Коза", "habitat": "farm", "texture": "farm_goat"},
	{"name": "Курица", "habitat": "farm", "texture": "farm_chicken"},
	{"name": "Утка", "habitat": "farm", "texture": "farm_duck"},
	{"name": "Кролик", "habitat": "farm", "texture": "farm_rabbit"},
	{"name": "Кошка", "habitat": "farm", "texture": "farm_cat"},
	{"name": "Собака", "habitat": "farm", "texture": "farm_dog"},
	{"name": "Орёл", "habitat": "sky", "texture": "sky_eagle"},
	{"name": "Сова", "habitat": "sky", "texture": "sky_owl"},
	{"name": "Попугай", "habitat": "sky", "texture": "sky_parrot"},
	{"name": "Голубь", "habitat": "sky", "texture": "sky_pigeon"},
	{"name": "Воробей", "habitat": "sky", "texture": "sky_sparrow"},
	{"name": "Ворона", "habitat": "sky", "texture": "sky_crow"},
	{"name": "Чайка", "habitat": "sky", "texture": "sky_seagull"},
	{"name": "Бабочка", "habitat": "sky", "texture": "sky_butterfly"},
	{"name": "Пчела", "habitat": "sky", "texture": "sky_bee"},
	{"name": "Летучая мышь", "habitat": "sky", "texture": "sky_bat"},
	{"name": "Медведь", "habitat": "wild", "texture": "wild_bear"},
	{"name": "Волк", "habitat": "wild", "texture": "wild_wolf"},
	{"name": "Лиса", "habitat": "wild", "texture": "wild_fox"},
	{"name": "Олень", "habitat": "wild", "texture": "wild_deer"},
	{"name": "Белка", "habitat": "wild", "texture": "wild_squirrel"},
	{"name": "Ёж", "habitat": "wild", "texture": "wild_hedgehog"},
	{"name": "Заяц", "habitat": "wild", "texture": "wild_hare"},
	{"name": "Лось", "habitat": "wild", "texture": "wild_moose"},
	{"name": "Кабан", "habitat": "wild", "texture": "wild_boar"},
	{"name": "Енот", "habitat": "wild", "texture": "wild_raccoon"}
]

var background: TextureRect
var ui_layer: CanvasLayer
var home_button: Button
var score_back: Panel
var score_icon: TextureRect
var score_label: Label
var animal_view: TextureRect
var habitat_buttons: Dictionary = {}
var habitat_displays: Dictionary = {}
var habitat_masks: Dictionary = {}
var current_animal: Dictionary
var previous_index := -1
var animal_order: Array[int] = []
var input_locked := false
var is_dragging := false
var animal_drag_offset := Vector2.ZERO
var animal_home_position := Vector2.ZERO
var correct_player: AudioStreamPlayer
var wrong_player: AudioStreamPlayer
var voice_player: AudioStreamPlayer
var placed_animal: TextureRect
var placed_habitat := ""
var placed_motion: Tween
var score := 0
var intro_pending := true

func _ready() -> void:
	randomize()
	_build_ui()
	get_viewport().size_changed.connect(_layout)
	_layout()
	_start_round()
	call_deferred("_play_intro_and_current_animal")

func _build_ui() -> void:
	background = TextureRect.new()
	background.texture = BACKGROUND_TEXTURE
	background.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	background.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	background.z_index = -10
	add_child(background)

	ui_layer = CanvasLayer.new()
	ui_layer.layer = 20
	add_child(ui_layer)
	home_button = GameExitButton.new()
	home_button.pressed.connect(func() -> void: SFX.transition_to_scene(HOME_SCENE))
	ui_layer.add_child(home_button)
	score_back = GameScorePanel.new()
	ui_layer.add_child(score_back)
	score_icon = (score_back as GameScorePanel).score_icon
	score_label = (score_back as GameScorePanel).score_label
	score_label.add_theme_font_override("font", GAME_FONT)

	for habitat in HABITATS:
		var button := Button.new()
		button.clip_contents = false
		button.focus_mode = Control.FOCUS_NONE
		button.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var frame_color: Color = HABITAT_COLORS[habitat]
		var frame_fill := frame_color.lightened(0.12)
		var frame_style := _panel_style(frame_fill, frame_color.darkened(0.22), 7, 28)
		frame_style.shadow_size = 10
		frame_style.shadow_offset = Vector2(0, 6)
		for state in ["normal", "hover", "pressed", "disabled"]:
			button.add_theme_stylebox_override(state, frame_style)
		add_child(button)
		habitat_buttons[habitat] = button
		var display := Control.new()
		display.name = "Display"
		display.clip_contents = true
		display.mouse_filter = Control.MOUSE_FILTER_IGNORE
		button.add_child(display)
		habitat_displays[habitat] = display
		if habitat == "sea":
			var sea_view := Control.new()
			sea_view.name = "SeaBackground"
			sea_view.set_script(SEA_HABITAT_SCRIPT)
			sea_view.mouse_filter = Control.MOUSE_FILTER_IGNORE
			display.add_child(sea_view)
			var sea_foreground := Control.new()
			sea_foreground.name = "SeaForeground"
			sea_foreground.set_script(SEA_HABITAT_SCRIPT)
			sea_foreground.set("foreground_only", true)
			sea_foreground.mouse_filter = Control.MOUSE_FILTER_IGNORE
			sea_foreground.z_index = 2
			display.add_child(sea_foreground)
		else:
			var habitat_view := TextureRect.new()
			habitat_view.name = "HabitatBackground"
			habitat_view.texture = load(HABITAT_BACKGROUNDS[habitat])
			habitat_view.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			habitat_view.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
			habitat_view.mouse_filter = Control.MOUSE_FILTER_IGNORE
			display.add_child(habitat_view)
		var corner_mask := Control.new()
		corner_mask.name = "RoundedCornerMask"
		corner_mask.set_script(ROUNDED_MASK_SCRIPT)
		corner_mask.set("mask_color", frame_fill)
		corner_mask.mouse_filter = Control.MOUSE_FILTER_IGNORE
		corner_mask.z_index = 50
		display.add_child(corner_mask)
		habitat_masks[habitat] = corner_mask

	animal_view = TextureRect.new()
	animal_view.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	animal_view.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	animal_view.mouse_filter = Control.MOUSE_FILTER_STOP
	animal_view.z_index = 100
	animal_view.gui_input.connect(_on_animal_gui_input)
	add_child(animal_view)

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

func _layout() -> void:
	var viewport_size := get_viewport_rect().size
	var scale_factor: float = minf(viewport_size.x / REFERENCE_SIZE.x, viewport_size.y / REFERENCE_SIZE.y)
	var safe_scale := clampf(scale_factor, 0.62, 1.35)
	var edge: float = 18.0 * safe_scale
	var safe := _safe_area_insets(viewport_size)
	var top_edge := edge + safe.y
	var bottom_edge := edge + safe.w
	background.position = Vector2.ZERO
	background.size = viewport_size
	var button_size: float = 106.0 * safe_scale
	home_button.size = Vector2.ONE * button_size
	var score_size := Vector2(225.0, 88.0) * safe_scale
	score_back.size = score_size
	score_icon.position = Vector2(9.0, 7.0) * safe_scale
	score_icon.size = Vector2.ONE * 72.0 * safe_scale
	score_label.position = Vector2(82.0, 4.0) * safe_scale
	score_label.size = Vector2(132.0, 80.0) * safe_scale
	score_label.add_theme_font_size_override("font_size", int(42.0 * safe_scale))
	var side_width: float = minf(viewport_size.x * 0.29, 430.0 * scale_factor)
	var window_height: float = minf(viewport_size.y * 0.385, 288.0 * scale_factor)
	var top_y: float = maxf(edge, safe.y + edge)
	var bottom_y: float = viewport_size.y - edge - window_height
	var left_x := edge
	var right_x: float = viewport_size.x - edge - side_width
	_set_habitat_rect("wild", Rect2(left_x, top_y, side_width, window_height), scale_factor)
	_set_habitat_rect("farm", Rect2(left_x, bottom_y, side_width, window_height), scale_factor)
	_set_habitat_rect("sky", Rect2(right_x, top_y, side_width, window_height), scale_factor)
	_set_habitat_rect("sea", Rect2(right_x, bottom_y, side_width, window_height), scale_factor)
	var center_left: float = left_x + side_width + edge
	var center_right: float = right_x - edge
	var center_width: float = maxf(220.0 * scale_factor, center_right - center_left)
	var hud_gap: float = maxf(10.0, 18.0 * safe_scale)
	var hud_width := button_size + score_size.x + hud_gap
	var hud_scale := minf(1.0, center_width / hud_width)
	if hud_scale < 1.0:
		button_size *= hud_scale
		score_size *= hud_scale
		home_button.size = Vector2.ONE * button_size
		score_back.size = score_size
		score_icon.position = Vector2(9.0, 7.0) * safe_scale * hud_scale
		score_icon.size = Vector2.ONE * 72.0 * safe_scale * hud_scale
		score_label.position = Vector2(82.0, 4.0) * safe_scale * hud_scale
		score_label.size = Vector2(132.0, 80.0) * safe_scale * hud_scale
		score_label.add_theme_font_size_override("font_size", int(42.0 * safe_scale * hud_scale))
	var hud_bottom := viewport_size.y - bottom_edge
	home_button.position = Vector2(center_left, hud_bottom - button_size)
	score_back.position = Vector2(center_right - score_size.x, hud_bottom - score_size.y)
	var hud_top := minf(home_button.position.y, score_back.position.y)
	var animal_top := maxf(top_edge, viewport_size.y * 0.11)
	var available_animal_height := maxf(120.0 * safe_scale, hud_top - animal_top - 14.0 * safe_scale)
	var animal_side: float = minf(minf(center_width * 0.94, viewport_size.y * 0.61), available_animal_height)
	animal_view.size = Vector2.ONE * animal_side
	animal_home_position = Vector2((viewport_size.x - animal_side) * 0.5, animal_top)
	if not is_dragging:
		animal_view.position = animal_home_position
	animal_view.pivot_offset = animal_view.size * 0.5
	if is_instance_valid(placed_animal):
		_layout_placed_animal()

func _set_habitat_rect(habitat: String, rect: Rect2, scale_factor: float) -> void:
	var button: Button = habitat_buttons[habitat]
	button.position = rect.position
	button.size = rect.size
	var inset: float = maxf(8.0, 12.0 * scale_factor)
	var display: Control = habitat_displays[habitat]
	display.position = Vector2.ONE * inset
	display.size = rect.size - Vector2.ONE * inset * 2.0
	for child in display.get_children():
		if child is Control and child != placed_animal:
			child.position = Vector2.ZERO
			child.size = display.size
	var mask: Control = habitat_masks[habitat]
	mask.set("corner_radius", maxf(14.0, 22.0 * scale_factor))
	mask.queue_redraw()

func _start_round() -> void:
	input_locked = false
	is_dragging = false
	_reset_habitat_tints()
	if animal_order.is_empty():
		_refill_animal_order()
	var index: int = animal_order.pop_back()
	previous_index = index
	current_animal = ANIMALS[index]
	var texture_path := "res://education/playtown/assets/animal_habitat/animals/%s.webp" % current_animal["texture"]
	animal_view.texture = load(texture_path)
	animal_view.position = animal_home_position
	animal_view.modulate = Color(1, 1, 1, 0)
	animal_view.scale = Vector2(0.78, 0.78)
	animal_view.pivot_offset = animal_view.size * 0.5
	var tween := create_tween().set_parallel(true)
	tween.tween_property(animal_view, "modulate:a", 1.0, 0.22)
	tween.tween_property(animal_view, "scale", Vector2.ONE, 0.30).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	if not intro_pending:
		call_deferred("_play_current_animal_voice")

func _refill_animal_order() -> void:
	animal_order.clear()
	for index in range(ANIMALS.size()):
		animal_order.append(index)
	animal_order.shuffle()
	if previous_index >= 0 and animal_order.back() == previous_index:
		var first_index: int = animal_order[0]
		animal_order[0] = animal_order[animal_order.size() - 1]
		animal_order[animal_order.size() - 1] = first_index

func _on_animal_gui_input(event: InputEvent) -> void:
	if input_locked:
		return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			_begin_drag(get_global_mouse_position())
		else:
			_finish_drag()
	elif event is InputEventMouseMotion and is_dragging and Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		_move_animal(get_global_mouse_position())
	elif event is InputEventScreenTouch:
		if event.pressed:
			_begin_drag(animal_view.get_global_transform() * event.position)
		else:
			_finish_drag()
	elif event is InputEventScreenDrag and is_dragging:
		_move_animal(animal_view.get_global_transform() * event.position)

func _begin_drag(pointer_global: Vector2) -> void:
	is_dragging = true
	animal_drag_offset = animal_view.global_position - pointer_global
	animal_view.z_index = 200
	animal_view.scale = Vector2(1.06, 1.06)

func _move_animal(pointer_global: Vector2) -> void:
	animal_view.global_position = pointer_global + animal_drag_offset

func _finish_drag() -> void:
	if not is_dragging:
		return
	is_dragging = false
	animal_view.z_index = 100
	var animal_center := animal_view.get_global_rect().get_center()
	for habitat in HABITATS:
		var target: Button = habitat_buttons[habitat]
		if target.get_global_rect().has_point(animal_center):
			_resolve_drop(habitat)
			return
	_return_animal()

func _resolve_drop(habitat: String) -> void:
	if habitat == current_animal["habitat"]:
		input_locked = true
		correct_player.play()
		_play_current_animal_voice()
		SFX.play_praise(get_viewport_rect().size * 0.5, 1.7)
		_flash_habitat(habitat, Color("#b8f5a5"))
		score += 1
		GameState.last_score = score
		GameState.add_coins(1)
		_remove_placed_animal()
		var display: Control = habitat_displays[habitat]
		var placed_rect := _placed_animal_rect(habitat, display.size)
		var destination_center: Vector2 = display.global_position + placed_rect.get_center()
		var destination_position: Vector2 = destination_center - animal_view.size * 0.5
		var destination_scale: float = minf(placed_rect.size.x / animal_view.size.x, placed_rect.size.y / animal_view.size.y)
		var settle := create_tween().set_parallel(true)
		settle.tween_property(animal_view, "position", destination_position, 0.36).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		settle.tween_property(animal_view, "scale", Vector2.ONE * destination_scale, 0.36).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		await settle.finished
		_install_placed_animal(habitat)
		animal_view.modulate.a = 0.0
		if voice_player.playing:
			await voice_player.finished
		await _play_voice(LanguageService.get_habitat_voice(habitat))
		_start_round()
	else:
		wrong_player.play()
		SFX.play_retry(get_viewport_rect().size * 0.5)
		_flash_habitat(habitat, Color("#ffb2a8"))
		var start_x := animal_view.position.x
		var shake := create_tween()
		shake.tween_property(animal_view, "position:x", start_x - 13.0, 0.06)
		shake.tween_property(animal_view, "position:x", start_x + 13.0, 0.08)
		shake.tween_property(animal_view, "position:x", start_x, 0.06)
		await shake.finished
		_return_animal()

func _return_animal() -> void:
	var tween := create_tween().set_parallel(true)
	tween.tween_property(animal_view, "position", animal_home_position, 0.28).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(animal_view, "scale", Vector2.ONE, 0.22)

func _reset_habitat_tints() -> void:
	for habitat in HABITATS:
		habitat_buttons[habitat].modulate = Color.WHITE

func _flash_habitat(habitat: String, color: Color) -> void:
	var button: Button = habitat_buttons[habitat]
	button.modulate = color
	var tween := create_tween()
	tween.tween_property(button, "modulate", Color.WHITE, 0.42)

func _remove_placed_animal() -> void:
	if not is_instance_valid(placed_animal):
		return
	if placed_motion and placed_motion.is_valid():
		placed_motion.kill()
	var old_animal := placed_animal
	placed_animal = null
	placed_habitat = ""
	var fade := create_tween().set_parallel(true)
	fade.tween_property(old_animal, "modulate:a", 0.0, 0.18)
	fade.tween_property(old_animal, "scale", Vector2(0.72, 0.72), 0.18)
	fade.finished.connect(old_animal.queue_free)

func _install_placed_animal(habitat: String) -> void:
	var display: Control = habitat_displays[habitat]
	placed_animal = TextureRect.new()
	placed_animal.texture = animal_view.texture
	placed_animal.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	placed_animal.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	placed_animal.mouse_filter = Control.MOUSE_FILTER_IGNORE
	placed_animal.z_index = 1
	display.add_child(placed_animal)
	placed_habitat = habitat
	_layout_placed_animal()
	placed_animal.modulate.a = 0.0
	placed_animal.scale = Vector2(0.82, 0.82)
	var appear := create_tween().set_parallel(true)
	appear.tween_property(placed_animal, "modulate:a", 1.0, 0.18)
	appear.tween_property(placed_animal, "scale", Vector2.ONE, 0.24).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_start_placed_motion()

func _layout_placed_animal() -> void:
	if not is_instance_valid(placed_animal) or placed_habitat.is_empty():
		return
	var display: Control = habitat_displays[placed_habitat]
	var rect := _placed_animal_rect(placed_habitat, display.size)
	placed_animal.position = rect.position
	placed_animal.size = rect.size
	placed_animal.pivot_offset = rect.size * 0.5
	_start_placed_motion()

func _placed_animal_rect(habitat: String, display_size: Vector2) -> Rect2:
	var width_factor := 0.39
	var height_factor := 0.52
	var center := Vector2(0.52, 0.57)
	if habitat == "wild":
		center = Vector2(0.53, 0.59)
	elif habitat == "farm":
		center = Vector2(0.52, 0.58)
	elif habitat == "sky":
		width_factor = 0.34
		height_factor = 0.43
		center = Vector2(0.50, 0.38)
	elif habitat == "sea":
		width_factor = 0.34
		height_factor = 0.42
		center = Vector2(0.50, 0.61)
	var animal_size := Vector2(display_size.x * width_factor, display_size.y * height_factor)
	return Rect2(display_size * center - animal_size * 0.5, animal_size)

func _start_placed_motion() -> void:
	if not is_instance_valid(placed_animal):
		return
	if placed_motion and placed_motion.is_valid():
		placed_motion.kill()
	if placed_habitat != "sea" and placed_habitat != "sky":
		return
	var base_y := placed_animal.position.y
	var amount := 5.0 if placed_habitat == "sea" else 7.0
	placed_motion = create_tween().set_loops()
	placed_motion.tween_property(placed_animal, "position:y", base_y - amount, 0.85).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	placed_motion.tween_property(placed_animal, "position:y", base_y + amount, 1.70).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	placed_motion.tween_property(placed_animal, "position:y", base_y, 0.85).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

func _play_intro_and_current_animal() -> void:
	await _play_voice(LanguageService.get_game_voice("animal_habitat_intro"))
	intro_pending = false
	_play_current_animal_voice()

func _play_current_animal_voice() -> void:
	if current_animal.is_empty():
		return
	var stream := LanguageService.get_animal_voice(String(current_animal.get("texture", "")))
	if stream == null:
		return
	voice_player.stop()
	voice_player.stream = stream
	voice_player.play()

func _play_voice(stream: AudioStream) -> void:
	if stream == null:
		return
	voice_player.stop()
	voice_player.stream = stream
	voice_player.play()
	await voice_player.finished

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

func _panel_style(fill: Color, border: Color, border_width: int, radius: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.border_color = border
	style.set_border_width_all(border_width)
	style.set_corner_radius_all(radius)
	style.shadow_color = Color(0, 0, 0, 0.20)
	style.shadow_size = 8
	style.shadow_offset = Vector2(0, 4)
	return style
