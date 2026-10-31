extends Node2D
const ObjectCatalog := preload("res://education/playtown/src/features/shared/learning_object_catalog.gd")
@export var letter_scene: PackedScene
@export var wrong_sound: AudioStream = preload("res://education/playtown/audio/sfx/wrong.ogg")
@export var correct_sound: AudioStream = preload("res://education/playtown/audio/sfx/correct.ogg")
@export var round_words_count := 5
@export var results_scene_path := "res://education/playtown/scenes/screens/game_select_school.tscn"
@export var after_word_delay_sec := 1.15
var words: Array[String] = []
var word_icons: Array[Dictionary] = []
const STAR_TEXTURE: Texture2D = preload("res://education/playtown/assets/ui/star.png")
const SLOT_SCRIPT: Script = preload("res://education/playtown/src/features/school/school_letter_slot.gd")
const CATEGORY_BAR_SCRIPT: Script = preload("res://education/playtown/src/features/shared/word_category_bar.gd")
const REFERENCE_SIZE := Vector2(1536.0, 768.0)
var rng := RandomNumberGenerator.new()
var game_words: Array[String] = []
var current_word_index := 0
var current_word := ""
var slot_letters: Array[String] = []
var letters_placed := 0
var score := 0
var game_over := false
var waiting_next_word := false
var background_layer: CanvasLayer
var wall: ColorRect
var floor: ColorRect
var category_panel: Panel
var activity_card: Panel
var letters_tray: Panel
var icon_rect: TextureRect
var slots_root: Node2D
var letters_root: Node2D
var slot_nodes: Array = []
var letter_items: Array = []
var ui_layer: CanvasLayer
var home_button: Button
var score_back: Panel
var score_icon: TextureRect
var score_label: Label
var error_flash: ColorRect
var success_mark: Label
var category_bar: Control
var selected_category := "objects"
var wrong_player := AudioStreamPlayer.new()
var correct_player := AudioStreamPlayer.new()
var word_voice_player := AudioStreamPlayer.new()
func _ready() -> void:
	_reload_word_pool()
	if letter_scene == null:
		return
	if words.is_empty():
		return
	rng.randomize()
	_build_scene()
	_setup_audio()
	get_viewport().size_changed.connect(_layout_for_viewport)
	_start_game()
	_play_intro()
func _build_scene() -> void:
	background_layer = CanvasLayer.new()
	background_layer.layer = -10
	add_child(background_layer)
	wall = ColorRect.new()
	wall.color = Color("#f6e8cf")
	wall.mouse_filter = Control.MOUSE_FILTER_IGNORE
	background_layer.add_child(wall)
	floor = ColorRect.new()
	floor.color = Color("#d9a86c")
	floor.mouse_filter = Control.MOUSE_FILTER_IGNORE
	background_layer.add_child(floor)
	category_panel = Panel.new()
	category_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	category_panel.add_theme_stylebox_override("panel", _panel_style(
		Color("#fff4d5"), Color("#d79a47"), 4, 28
	))
	background_layer.add_child(category_panel)
	activity_card = Panel.new()
	activity_card.mouse_filter = Control.MOUSE_FILTER_IGNORE
	activity_card.add_theme_stylebox_override("panel", _panel_style(
		Color("#fffaf0"), Color("#d79a47"), 4, 28
	))
	background_layer.add_child(activity_card)
	letters_tray = Panel.new()
	letters_tray.mouse_filter = Control.MOUSE_FILTER_IGNORE
	letters_tray.add_theme_stylebox_override("panel", _panel_style(
		Color("#f2c77e"), Color("#b97935"), 4, 24
	))
	background_layer.add_child(letters_tray)
	icon_rect = TextureRect.new()
	icon_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	background_layer.add_child(icon_rect)
	slots_root = Node2D.new()
	slots_root.name = "LetterSlots"
	add_child(slots_root)
	letters_root = Node2D.new()
	letters_root.name = "LetterChoices"
	letters_root.z_index = 20
	add_child(letters_root)
	ui_layer = CanvasLayer.new()
	ui_layer.layer = 20
	add_child(ui_layer)
	category_bar = CATEGORY_BAR_SCRIPT.new()
	category_bar.setup(selected_category)
	category_bar.category_selected.connect(_on_category_selected)
	ui_layer.add_child(category_bar)
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
	success_mark = Label.new()
	success_mark.text = "✓"
	success_mark.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	success_mark.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	success_mark.add_theme_color_override("font_color", Color("#54b957"))
	success_mark.add_theme_color_override("font_outline_color", Color.WHITE)
	success_mark.add_theme_constant_override("outline_size", 8)
	success_mark.visible = false
	success_mark.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ui_layer.add_child(success_mark)
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
func _setup_audio() -> void:
	add_child(wrong_player)
	add_child(correct_player)
	add_child(word_voice_player)
	wrong_player.bus = "SFX"
	correct_player.bus = "SFX"
	word_voice_player.bus = "VOICE"

func _play_intro() -> void:
	var intro := LanguageService.get_game_voice("word_build_intro")
	if intro:
		word_voice_player.stop()
		word_voice_player.stream = intro
		word_voice_player.play()
func _start_game() -> void:
	game_words.clear()
	var pool: Array[String] = words.duplicate()
	pool.shuffle()
	var take: int = mini(round_words_count, pool.size())
	for index in range(take):
		game_words.append(pool[index].to_upper())
	score = 0
	current_word_index = 0
	game_over = false
	waiting_next_word = false
	_update_score()
	_load_current_word()
func _load_current_word() -> void:
	if current_word_index >= game_words.size():
		_finish_game()
		return
	current_word = game_words[current_word_index]
	letters_placed = 0
	waiting_next_word = false
	slot_letters.clear()
	slot_letters.resize(current_word.length())
	for index in range(slot_letters.size()):
		slot_letters[index] = ""
	icon_rect.texture = _get_icon_for_word(current_word)
	_create_slots()
	_create_letter_choices()
	_layout_for_viewport()
func _create_slots() -> void:
	for child in slots_root.get_children():
		slots_root.remove_child(child)
		child.queue_free()
	slot_nodes.clear()
	for index in range(current_word.length()):
		var slot = Area2D.new()
		slot.set_script(SLOT_SCRIPT)
		slot.index = index
		slot.expected_letter = current_word[index]
		slots_root.add_child(slot)
		slot.setup(slot.expected_letter)
		slot_nodes.append(slot)
func _create_letter_choices() -> void:
	for child in letters_root.get_children():
		letters_root.remove_child(child)
		child.queue_free()
	letter_items.clear()
	var choices: Array[String] = []
	for index in range(current_word.length()):
		choices.append(current_word[index])
	var alphabet: Array[String] = LanguageService.get_alphabet()
	var desired_count: int = maxi(8, current_word.length() + 2)
	while choices.size() < desired_count:
		var candidate: String = alphabet[rng.randi_range(0, alphabet.size() - 1)]
		if not choices.has(candidate):
			choices.append(candidate)
	choices.shuffle()
	for character in choices:
		var item = letter_scene.instantiate()
		letters_root.add_child(item)
		item.configure_letter(character, LanguageService.get_letter_voice(character))
		item.dropped_on_slot.connect(_on_letter_dropped_on_slot)
		item.dropped_wrong.connect(_on_letter_dropped_wrong)
		letter_items.append(item)
func _layout_for_viewport() -> void:
	var viewport_size: Vector2 = get_viewport_rect().size
	if viewport_size.x <= 0.0 or viewport_size.y <= 0.0:
		return
	var safe_scale: float = minf(viewport_size.x / REFERENCE_SIZE.x, viewport_size.y / REFERENCE_SIZE.y)
	safe_scale = clampf(safe_scale, 0.62, 1.4)
	var safe := _safe_area_insets(viewport_size)
	var edge: float = clampf(20.0 * safe_scale, 14.0, 30.0)
	var left_edge: float = safe.x + edge
	var right_edge: float = viewport_size.x - safe.z - edge
	var top_edge: float = safe.y + edge
	var bottom_edge: float = viewport_size.y - safe.w - edge
	var available_height: float = maxf(520.0, bottom_edge - top_edge)
	var floor_top: float = viewport_size.y * 0.73
	wall.position = Vector2.ZERO
	wall.size = Vector2(viewport_size.x, floor_top)
	floor.position = Vector2(0.0, floor_top)
	floor.size = Vector2(viewport_size.x, viewport_size.y - floor_top)
	var side_width: float = clampf(viewport_size.x * 0.105, 150.0, 176.0)
	var panel_gap: float = clampf(viewport_size.x * 0.016, 20.0, 30.0)
	var content_left: float = left_edge + side_width + panel_gap
	var content_width: float = maxf(720.0, right_edge - content_left)
	var tray_height: float = clampf(available_height * 0.245, 160.0, 205.0)
	var vertical_gap: float = clampf(available_height * 0.032, 18.0, 28.0)
	var card_height: float = available_height - tray_height - vertical_gap
	var category_rect := Rect2(left_edge, top_edge, side_width, available_height)
	var card_rect := Rect2(content_left, top_edge, content_width, card_height)
	var tray_rect := Rect2(content_left, card_rect.end.y + vertical_gap, content_width, tray_height)
	category_panel.position = category_rect.position
	category_panel.size = category_rect.size
	activity_card.position = card_rect.position
	activity_card.size = card_rect.size
	letters_tray.position = tray_rect.position
	letters_tray.size = tray_rect.size
	var content_center_x: float = card_rect.position.x + card_rect.size.x * 0.5
	var icon_size: float = minf(card_rect.size.y * 0.43, card_rect.size.x * 0.2)
	icon_rect.size = Vector2(icon_size * 1.35, icon_size)
	icon_rect.position = Vector2(
		content_center_x - icon_rect.size.x * 0.5,
		card_rect.position.y + clampf(card_rect.size.y * 0.10, 36.0, 58.0)
	)
	var word_length: int = maxi(current_word.length(), 1)
	var slot_gap: float = 13.0 * safe_scale
	var max_slots_width: float = card_rect.size.x * 0.78
	var slot_size: float = minf(
		96.0 * safe_scale,
		(max_slots_width - slot_gap * float(word_length - 1)) / float(word_length)
	)
	slot_size = maxf(slot_size, 52.0 * safe_scale)
	var slots_width: float = slot_size * float(word_length) + slot_gap * float(word_length - 1)
	var slots_y: float = card_rect.end.y - slot_size * 0.68
	for index in range(slot_nodes.size()):
		slot_nodes[index].position = Vector2(
			content_center_x - slots_width * 0.5 + slot_size * 0.5 + float(index) * (slot_size + slot_gap),
			slots_y
		)
		slot_nodes[index].set_display_size(Vector2.ONE * slot_size)
	var choice_count: int = maxi(letter_items.size(), 1)
	var letter_gap: float = 10.0 * safe_scale
	var available_width: float = tray_rect.size.x - 34.0 * safe_scale
	var letter_size: float = minf(
		82.0 * safe_scale,
		(available_width - letter_gap * float(choice_count - 1)) / float(choice_count)
	)
	letter_size = maxf(letter_size, 48.0 * safe_scale)
	var row_width: float = letter_size * float(choice_count) + letter_gap * float(choice_count - 1)
	var letter_y: float = tray_rect.position.y + tray_rect.size.y * 0.5
	for index in range(letter_items.size()):
		var item = letter_items[index]
		var start := Vector2(
			content_center_x - row_width * 0.5 + letter_size * 0.5 + float(index) * (letter_size + letter_gap),
			letter_y
		)
		item.set_display_size(Vector2.ONE * letter_size)
		if not item.dragging:
			item.set_start_position(start)
	var button_size: float = minf(clampf(side_width * 0.68, 102.0, 118.0), available_height * 0.16)
	var home_bottom: float = category_rect.end.y - clampf(18.0 * safe_scale, 14.0, 22.0)
	home_button.position = Vector2(category_rect.position.x + (side_width - button_size) * 0.5, home_bottom - button_size)
	home_button.size = Vector2.ONE * button_size
	var category_padding: float = clampf(side_width * 0.11, 15.0, 20.0)
	category_bar.set_layout(Rect2(
		Vector2(category_rect.position.x + category_padding, category_rect.position.y + 22.0),
		Vector2(side_width - category_padding * 2.0, home_button.position.y - category_rect.position.y - 38.0)
	), true)
	var score_size: Vector2 = Vector2(225.0, 88.0) * safe_scale
	score_size.x = minf(score_size.x, card_rect.size.x * 0.23)
	score_back.position = Vector2(card_rect.end.x - score_size.x - 18.0 * safe_scale, card_rect.position.y + 16.0 * safe_scale)
	score_back.size = score_size
	score_icon.position = Vector2(9.0, 7.0) * safe_scale
	score_icon.size = Vector2.ONE * 72.0 * safe_scale
	score_label.position = Vector2(82.0, 4.0) * safe_scale
	score_label.size = Vector2(132.0, 80.0) * safe_scale
	score_label.add_theme_font_size_override("font_size", int(42.0 * safe_scale))
	error_flash.position = Vector2.ZERO
	error_flash.size = viewport_size
	success_mark.position = Vector2(content_center_x - 80.0 * safe_scale, icon_rect.position.y)
	success_mark.size = Vector2.ONE * 160.0 * safe_scale
	success_mark.add_theme_font_size_override("font_size", int(120.0 * safe_scale))

func _safe_area_insets(viewport_size: Vector2) -> Vector4:
	if OS.get_name() not in ["iOS", "Android"]:
		return Vector4.ZERO
	var window_size := Vector2(DisplayServer.window_get_size())
	var safe_rect := DisplayServer.get_display_safe_area()
	if window_size.x <= 0.0 or window_size.y <= 0.0 or safe_rect.size.x <= 0 or safe_rect.size.y <= 0:
		return Vector4.ZERO
	var scale_to_viewport := viewport_size / window_size
	var right_px := maxf(0.0, window_size.x - float(safe_rect.position.x + safe_rect.size.x))
	var bottom_px := maxf(0.0, window_size.y - float(safe_rect.position.y + safe_rect.size.y))
	return Vector4(
		clampf(float(safe_rect.position.x) * scale_to_viewport.x, 0.0, viewport_size.x * 0.2),
		clampf(float(safe_rect.position.y) * scale_to_viewport.y, 0.0, viewport_size.y * 0.2),
		clampf(right_px * scale_to_viewport.x, 0.0, viewport_size.x * 0.2),
		clampf(bottom_px * scale_to_viewport.y, 0.0, viewport_size.y * 0.2)
	)
func _get_icon_for_word(word: String) -> Texture2D:
	for data in word_icons:
		if String(data.get("word", "")).to_upper() == word.to_upper():
			return data.get("texture") as Texture2D
	return null
func _get_voice_for_word(word: String) -> AudioStream:
	for data in word_icons:
		if String(data.get("word", "")).to_upper() == word.to_upper():
			return data.get("voice") as AudioStream
	return null
func _on_letter_dropped_on_slot(item, slot) -> void:
	if game_over or waiting_next_word:
		item.reset_to_start()
		return
	var index: int = slot.index
	if index < 0 or index >= current_word.length() or slot_letters[index] != "":
		item.reset_to_start()
		return
	if item.letter.to_upper() != current_word[index]:
		_show_error()
		item.reset_to_start()
		return
	slot_letters[index] = item.letter.to_upper()
	letters_placed += 1
	score += 1
	_update_score()
	GameState.last_score = score
	GameState.add_coins(1)
	slot.place_letter(item.letter)
	item.set_enabled(false)
	if correct_sound:
		correct_player.stop()
		correct_player.stream = correct_sound
		correct_player.play()
	if letters_placed >= current_word.length():
		_complete_word()
func _on_letter_dropped_wrong(item) -> void:
	if game_over or waiting_next_word:
		item.reset_to_start()
		return
	_show_error()
	item.reset_to_start()
func _show_error() -> void:
	SFX.play_retry(get_viewport_rect().size * 0.5)
	if wrong_sound:
		wrong_player.stop()
		wrong_player.stream = wrong_sound
		wrong_player.play()
	error_flash.visible = true
	error_flash.color.a = 0.42
	var tween := create_tween()
	tween.tween_property(error_flash, "color:a", 0.0, 0.42)
	tween.finished.connect(func() -> void: error_flash.visible = false)
func _complete_word() -> void:
	if waiting_next_word:
		return
	waiting_next_word = true
	SFX.play_praise(get_viewport_rect().size * 0.5, 1.0)
	success_mark.visible = true
	success_mark.modulate.a = 1.0
	var word_voice := _get_voice_for_word(current_word)
	if word_voice:
		word_voice_player.stop()
		word_voice_player.stream = word_voice
		word_voice_player.play()
	var tween := create_tween()
	tween.tween_property(success_mark, "scale", Vector2(1.12, 1.12), 0.18)
	tween.tween_property(success_mark, "scale", Vector2.ONE, 0.18)
	var timer := get_tree().create_timer(after_word_delay_sec)
	timer.timeout.connect(func() -> void:
		success_mark.visible = false
		current_word_index += 1
		_load_current_word()
	)
func _update_score() -> void:
	score_label.text = str(GameState.get_coin_balance())
func _go_home() -> void:
	SFX.transition_to_scene(results_scene_path)

func _reload_word_pool() -> void:
	words.clear()
	word_icons.clear()
	for entry in ObjectCatalog.all(LanguageService.current_locale, selected_category):
		words.append(String(entry.text))
		word_icons.append({"word": entry.text, "texture": entry.texture, "voice": entry.voice})

func _on_category_selected(category: String) -> void:
	selected_category = category
	_reload_word_pool()
	if words.is_empty():
		return
	_start_game()
func _finish_game() -> void:
	if game_over:
		return
	game_over = true
	GameState.last_score = score
	SFX.transition_to_scene(results_scene_path)
