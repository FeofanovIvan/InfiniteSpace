extends Node2D

const BACKGROUND := preload("res://education/playtown/assets/background/character_select_bg.jpg")
const FONT := preload("res://education/playtown/assets/ui/fonts/RobotoCondensed-Variable.ttf")
const CHARACTER_SELECT_SCENE := "res://education/playtown/scenes/screens/character_select.tscn"
const SELECT_SOUND := preload("res://education/playtown/audio/sfx/correct.ogg")
const LOCALES: Array[String] = ["ru", "en", "pt", "es", "de", "fr"]

var background: TextureRect
var title_texture: TextureRect
var title_label: Label
var card: Panel
var selector: OptionButton
var confirm_button: Button
var voice_player: AudioStreamPlayer
var sfx_player: AudioStreamPlayer
var pending_locale := "en"
var selection_locked := false


func _ready() -> void:
	if LanguageService.should_skip_language_picker():
		get_tree().call_deferred("change_scene_to_file", CHARACTER_SELECT_SCENE)
		return
	pending_locale = LanguageService.suggested_locale()
	_create_background()
	_create_title()
	_create_selection_card()
	_create_audio()
	get_viewport().size_changed.connect(_layout)
	_layout()
	call_deferred("_play_prompt")


func _create_background() -> void:
	background = TextureRect.new()
	background.texture = BACKGROUND
	background.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	background.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	background.z_index = -10
	add_child(background)


func _create_title() -> void:
	title_texture = TextureRect.new()
	title_texture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	title_texture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	title_texture.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(title_texture)
	title_label = Label.new()
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	title_label.add_theme_font_override("font", FONT)
	title_label.add_theme_font_size_override("font_size", 76)
	title_label.add_theme_color_override("font_color", Color("#ffd92f"))
	title_label.add_theme_color_override("font_outline_color", Color("#163b96"))
	title_label.add_theme_constant_override("outline_size", 12)
	title_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(title_label)
	_refresh_title()


func _create_selection_card() -> void:
	card = Panel.new()
	card.add_theme_stylebox_override("panel", _make_card_style())
	add_child(card)
	selector = OptionButton.new()
	selector.focus_mode = Control.FOCUS_NONE
	selector.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	selector.add_theme_font_override("font", FONT)
	selector.add_theme_font_size_override("font_size", 42)
	selector.add_theme_color_override("font_color", Color("#603815"))
	selector.add_theme_color_override("font_hover_color", Color("#603815"))
	selector.add_theme_color_override("font_pressed_color", Color("#603815"))
	selector.add_theme_stylebox_override("normal", _make_selector_style(Color("#fff9e6"), Color("#d99022")))
	selector.add_theme_stylebox_override("hover", _make_selector_style(Color("#fffdf4"), Color("#f1aa2b")))
	selector.add_theme_stylebox_override("pressed", _make_selector_style(Color("#fff0bd"), Color("#cf7918")))
	selector.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	for index in range(LOCALES.size()):
		var locale := LOCALES[index]
		selector.add_item(LanguageService.language_name(locale), index)
	selector.select(maxi(0, LOCALES.find(pending_locale)))
	selector.item_selected.connect(_on_language_previewed)
	card.add_child(selector)
	_style_popup(selector.get_popup())
	confirm_button = Button.new()
	confirm_button.focus_mode = Control.FOCUS_NONE
	confirm_button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	confirm_button.add_theme_font_override("font", FONT)
	confirm_button.add_theme_font_size_override("font_size", 40)
	confirm_button.add_theme_color_override("font_color", Color.WHITE)
	confirm_button.add_theme_color_override("font_hover_color", Color.WHITE)
	confirm_button.add_theme_color_override("font_pressed_color", Color.WHITE)
	confirm_button.add_theme_color_override("font_disabled_color", Color(1, 1, 1, 0.72))
	confirm_button.add_theme_stylebox_override("normal", _make_confirm_style(Color("#55b747"), Color("#277e31")))
	confirm_button.add_theme_stylebox_override("hover", _make_confirm_style(Color("#67c958"), Color("#277e31")))
	confirm_button.add_theme_stylebox_override("pressed", _make_confirm_style(Color("#3e9e3b"), Color("#216a2c"), 3.0))
	confirm_button.add_theme_stylebox_override("disabled", _make_confirm_style(Color("#91b58a"), Color("#668161")))
	confirm_button.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	confirm_button.pressed.connect(_confirm_language)
	card.add_child(confirm_button)
	_refresh_confirm_text()


func _create_audio() -> void:
	voice_player = AudioStreamPlayer.new()
	voice_player.bus = "VOICE"
	add_child(voice_player)
	sfx_player = AudioStreamPlayer.new()
	sfx_player.bus = "SFX"
	add_child(sfx_player)


func _layout() -> void:
	if not is_instance_valid(background):
		return
	var size := get_viewport_rect().size
	background.position = Vector2.ZERO
	background.size = size
	var title_width := minf(size.x * 0.68, 900.0)
	var title_height := minf(size.y * 0.29, 205.0)
	title_texture.position = Vector2((size.x - title_width) * 0.5, size.y * 0.035)
	title_texture.size = Vector2(title_width, title_height)
	title_label.position = title_texture.position
	title_label.size = title_texture.size
	var card_width := minf(size.x * 0.58, 720.0)
	var card_height := clampf(size.y * 0.42, 270.0, 330.0)
	card.position = Vector2((size.x - card_width) * 0.5, size.y * 0.42)
	card.size = Vector2(card_width, card_height)
	var inner_width := card_width * 0.78
	var control_height := clampf(card_height * 0.29, 78.0, 96.0)
	selector.position = Vector2((card_width - inner_width) * 0.5, card_height * 0.16)
	selector.size = Vector2(inner_width, control_height)
	confirm_button.position = Vector2((card_width - inner_width * 0.78) * 0.5, card_height * 0.58)
	confirm_button.size = Vector2(inner_width * 0.78, control_height)
	confirm_button.pivot_offset = confirm_button.size * 0.5


func _on_language_previewed(index: int) -> void:
	if index < 0 or index >= LOCALES.size():
		return
	pending_locale = LOCALES[index]
	_refresh_title()
	_refresh_confirm_text()
	_play_prompt()


func _confirm_language() -> void:
	if selection_locked:
		return
	selection_locked = true
	selector.disabled = true
	confirm_button.disabled = true
	LanguageService.set_locale(pending_locale)
	sfx_player.stream = SELECT_SOUND
	sfx_player.play()
	var tween := create_tween()
	tween.tween_property(confirm_button, "scale", Vector2(1.035, 1.035), 0.11).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(confirm_button, "scale", Vector2.ONE, 0.10)
	await get_tree().create_timer(0.35).timeout
	SFX.transition_to_scene(LanguageService.finish_language_picker())


func _refresh_title() -> void:
	var title_path := LanguageService.get_title_texture_path("choose_language", pending_locale)
	if not title_path.is_empty() and ResourceLoader.exists(title_path):
		title_texture.texture = load(title_path)
		title_texture.visible = true
		title_label.visible = false
	else:
		title_texture.visible = false
		title_label.visible = true
		title_label.text = LanguageService.get_ui_text("choose_language", pending_locale)


func _refresh_confirm_text() -> void:
	confirm_button.text = LanguageService.get_ui_text("confirm", pending_locale)


func _play_prompt() -> void:
	if not is_instance_valid(voice_player):
		return
	voice_player.stop()
	var stream := LanguageService.get_ui_voice("choose_language", pending_locale)
	if stream:
		voice_player.stream = stream
		voice_player.play()


func _style_popup(popup: PopupMenu) -> void:
	popup.add_theme_font_override("font", FONT)
	popup.add_theme_font_size_override("font_size", 34)
	popup.add_theme_color_override("font_color", Color("#603815"))
	popup.add_theme_color_override("font_hover_color", Color("#603815"))
	var panel := StyleBoxFlat.new()
	panel.bg_color = Color("#fffaf0")
	panel.set_corner_radius_all(20)
	panel.border_width_left = 4
	panel.border_width_top = 4
	panel.border_width_right = 4
	panel.border_width_bottom = 4
	panel.border_color = Color("#e3a43f")
	panel.content_margin_left = 18.0
	panel.content_margin_right = 18.0
	panel.content_margin_top = 14.0
	panel.content_margin_bottom = 14.0
	popup.add_theme_stylebox_override("panel", panel)
	var hover := StyleBoxFlat.new()
	hover.bg_color = Color("#ffe7a0")
	hover.set_corner_radius_all(12)
	popup.add_theme_stylebox_override("hover", hover)


func _make_card_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(1.0, 0.97, 0.82, 0.94)
	style.set_corner_radius_all(38)
	style.border_width_left = 6
	style.border_width_top = 6
	style.border_width_right = 6
	style.border_width_bottom = 8
	style.border_color = Color("#f0a524")
	style.shadow_color = Color(0.21, 0.10, 0.02, 0.30)
	style.shadow_size = 14
	style.shadow_offset = Vector2(0, 8)
	return style


func _make_selector_style(color: Color, border: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.set_corner_radius_all(24)
	style.border_width_left = 5
	style.border_width_top = 5
	style.border_width_right = 5
	style.border_width_bottom = 6
	style.border_color = border
	style.content_margin_left = 30.0
	style.content_margin_right = 62.0
	style.shadow_color = Color(0.27, 0.14, 0.03, 0.18)
	style.shadow_size = 7
	style.shadow_offset = Vector2(0, 4)
	return style


func _make_confirm_style(color: Color, border: Color, pressed_offset: float = 0.0) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.set_corner_radius_all(25)
	style.border_width_left = 5
	style.border_width_top = 5
	style.border_width_right = 5
	style.border_width_bottom = 8
	style.border_color = border
	style.shadow_color = Color(0.12, 0.22, 0.08, 0.32)
	style.shadow_size = 8
	style.shadow_offset = Vector2(0, 6 - pressed_offset)
	return style
