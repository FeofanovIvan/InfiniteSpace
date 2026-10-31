extends Node2D
@export var select_sound: AudioStream = preload("res://education/playtown/audio/sfx/correct.ogg")
@export var play_sound: AudioStream = preload("res://education/playtown/audio/sfx/coin.ogg")
@export var back_scene_path: String = "res://education/playtown/scenes/world/city_world.tscn"
@export var cards_data: Array[Dictionary] = []
const BG_TEXTURE := "res://education/playtown/assets/background/character_select_bg.jpg"
const TITLE_TEXTURE := "res://education/playtown/assets/ui/game_select/title_choose_game.png"
const BACK_ARROW_TEXTURE: Texture2D = preload("res://education/playtown/assets/ui/back_arrow.png")
const GRAYSCALE_SHADER := preload("res://education/playtown/assets/shaders/grayscale.gdshader")
const UNSELECTED_TINT := Color(0.92, 0.92, 0.92)
var bg_image: TextureRect
var title: TextureRect
var back_btn: Button
var back_icon: TextureRect
var play_btn: Button
var card_buttons: Array[TextureButton] = []
var base_pos: Array[Vector2] = []
var sfx: AudioStreamPlayer
var select_tween: Tween
var float_tween: Tween
var selected_index: int = 0
var grayscale_material: ShaderMaterial
func _ready() -> void:
	grayscale_material = ShaderMaterial.new()
	grayscale_material.shader = GRAYSCALE_SHADER
	sfx = AudioStreamPlayer.new()
	sfx.bus = "SFX"
	add_child(sfx)
	bg_image = TextureRect.new()
	if ResourceLoader.exists(BG_TEXTURE):
		bg_image.texture = load(BG_TEXTURE)
		bg_image.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	bg_image.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	bg_image.z_index = -10
	bg_image.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg_image)
	title = TextureRect.new()
	var localized_title := LanguageService.get_title_texture_path("choose_game")
	var title_path := localized_title if not localized_title.is_empty() else TITLE_TEXTURE
	if ResourceLoader.exists(title_path):
		title.texture = load(title_path)
	title.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	title.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(title)
	for i in range(cards_data.size()):
		var data: Dictionary = cards_data[i]
		var btn := TextureButton.new()
		btn.texture_normal = load(data["texture"])
		btn.ignore_texture_size = true
		btn.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
		btn.pressed.connect(_select.bind(i))
		add_child(btn)
		card_buttons.append(btn)
	play_btn = Button.new()
	play_btn.text = LanguageService.get_ui_text("play")
	play_btn.add_theme_font_size_override("font_size", 46)
	play_btn.add_theme_color_override("font_color", Color(1, 1, 1))
	play_btn.add_theme_color_override("font_hover_color", Color(1, 1, 1))
	play_btn.add_theme_color_override("font_pressed_color", Color(1, 1, 1))
	for state in ["normal", "hover", "pressed"]:
		var sb := StyleBoxFlat.new()
		var green := Color(0.30, 0.69, 0.35)
		sb.bg_color = green if state != "pressed" else green.darkened(0.15)
		sb.set_corner_radius_all(30)
		sb.shadow_color = Color(0, 0, 0, 0.25)
		sb.shadow_size = 10
		sb.shadow_offset = Vector2(0, 5)
		sb.border_width_bottom = 6
		sb.border_color = green.darkened(0.3)
		play_btn.add_theme_stylebox_override(state, sb)
	play_btn.pressed.connect(_on_play)
	add_child(play_btn)
	back_btn = Button.new()
	back_btn.text = LanguageService.get_ui_text("back")
	back_btn.add_theme_font_size_override("font_size", 28)
	back_btn.add_theme_color_override("font_color", Color(1, 1, 1))
	back_btn.add_theme_color_override("font_hover_color", Color(1, 1, 1))
	back_btn.add_theme_color_override("font_pressed_color", Color(1, 1, 1))
	for state in ["normal", "hover", "pressed"]:
		var sb := StyleBoxFlat.new()
		var blue := Color(0.30, 0.55, 0.85)
		sb.bg_color = blue if state != "pressed" else blue.darkened(0.15)
		sb.set_corner_radius_all(20)
		sb.shadow_color = Color(0, 0, 0, 0.25)
		sb.shadow_size = 6
		sb.shadow_offset = Vector2(0, 3)
		sb.border_width_bottom = 4
		sb.border_color = blue.darkened(0.3)
		sb.content_margin_left = 44.0
		sb.content_margin_right = 12.0
		back_btn.add_theme_stylebox_override(state, sb)
	back_icon = TextureRect.new()
	back_icon.texture = BACK_ARROW_TEXTURE
	back_icon.flip_h = true
	back_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	back_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	back_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	back_btn.add_child(back_icon)
	back_btn.pressed.connect(_on_back_pressed)
	add_child(back_btn)
	get_viewport().size_changed.connect(_layout)
	_layout()
	call_deferred("_play_voice_prompt")
func _layout() -> void:
	var vs := get_viewport_rect().size
	var cx := vs.x * 0.5
	bg_image.position = Vector2.ZERO
	bg_image.size = vs
	if title.texture:
		var t: Texture2D = title.texture
		var aspect: float = float(t.get_width()) / float(t.get_height())
		var top: float = vs.y * 0.015
		var max_th: float = vs.y * 0.32 - top
		var tw: float = minf(vs.x * 0.8, 1000.0)
		var th: float = tw / aspect
		if th > max_th:
			th = max_th
			tw = th * aspect
		title.position = Vector2(cx - tw * 0.5, top)
		title.size = Vector2(tw, th)
	var n := card_buttons.size()
	base_pos.resize(n)
	if n > 0:
		var card_h: float = vs.y * (0.48 if n <= 2 else (0.44 if n == 3 else 0.40))
		var gap: float = vs.x * 0.02
		var card_y: float = vs.y * 0.36
		var sizes: Array[Vector2] = []
		var total_w: float = 0.0
		for btn in card_buttons:
			var tex: Texture2D = btn.texture_normal
			var w: float = card_h * float(tex.get_width()) / float(tex.get_height())
			sizes.append(Vector2(w, card_h))
			total_w += w
		total_w += gap * float(n - 1)
		var avail_w: float = vs.x * 0.97
		if total_w > avail_w:
			var scale_f: float = avail_w / total_w
			for i in range(n):
				sizes[i] *= scale_f
			card_h *= scale_f
			total_w = avail_w
		var x: float = cx - total_w * 0.5
		for i in range(n):
			base_pos[i] = Vector2(x, card_y)
			var btn := card_buttons[i]
			btn.size = sizes[i]
			btn.pivot_offset = btn.size * 0.5
			x += sizes[i].x + gap
	play_btn.size = Vector2(minf(vs.x * 0.3, 340.0), 92.0)
	play_btn.position = Vector2(cx - play_btn.size.x * 0.5, vs.y - play_btn.size.y - vs.y * 0.04)
	back_btn.size = Vector2(minf(vs.x * 0.18, 180.0), 64.0)
	back_btn.position = Vector2(vs.x * 0.03, vs.y * 0.03)
	back_icon.position = Vector2(10.0, 11.0)
	back_icon.size = Vector2(42.0, 38.0)
	_apply_selection(false)
func _select(i: int) -> void:
	if i == selected_index:
		_play(select_sound)
		_apply_selection(true)
		return
	selected_index = i
	_play(select_sound)
	_apply_selection(true)
func _apply_selection(animate: bool) -> void:
	if card_buttons.is_empty():
		return
	if select_tween:
		select_tween.kill()
	if float_tween:
		float_tween.kill()
	for i in range(card_buttons.size()):
		var btn: TextureButton = card_buttons[i]
		var is_sel: bool = i == selected_index
		btn.material = null if is_sel else grayscale_material
		btn.modulate = Color(1, 1, 1) if is_sel else UNSELECTED_TINT
		btn.z_index = 1 if is_sel else 0
		btn.position = base_pos[i]
		if not (is_sel and animate):
			btn.scale = Vector2.ONE
	var sel_btn: TextureButton = card_buttons[selected_index]
	if animate:
		sel_btn.scale = Vector2.ONE
		select_tween = create_tween()
		select_tween.tween_property(sel_btn, "scale", Vector2(1.06, 1.06), 0.14) \
			.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		select_tween.tween_property(sel_btn, "scale", Vector2.ONE, 0.12) \
			.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	var y: float = base_pos[selected_index].y
	float_tween = create_tween().set_loops()
	float_tween.tween_property(sel_btn, "position:y", y - 10.0, 1.1) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	float_tween.tween_property(sel_btn, "position:y", y, 1.1) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
func _on_play() -> void:
	if cards_data.is_empty():
		return
	var scene_path: String = String(cards_data[selected_index]["scene"])
	SFX.transition_to_scene(scene_path)
func _on_back_pressed() -> void:
	SFX.transition_to_scene(back_scene_path)
func _play(stream: AudioStream) -> void:
	if stream:
		sfx.stream = stream
		sfx.play()
func _play_voice_prompt() -> void:
	var stream := LanguageService.get_ui_voice("choose_game")
	if stream:
		_play(stream)
