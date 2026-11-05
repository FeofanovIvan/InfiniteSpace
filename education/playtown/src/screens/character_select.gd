extends Node2D
@export var select_sound: AudioStream = preload("res://education/playtown/audio/sfx/correct.ogg")
@export var play_sound: AudioStream = preload("res://education/playtown/audio/sfx/coin.ogg")
@export var main_scene_path: String = "res://education/playtown/scenes/world/city_world.tscn"
const BG_TEXTURE := "res://education/playtown/assets/background/character_select_bg.jpg"
const GRAYSCALE_SHADER := preload("res://education/playtown/assets/shaders/grayscale.gdshader")
const CARDS := {
	"girl": "res://education/playtown/assets/ui/select/girl_card.png",
	"boy": "res://education/playtown/assets/ui/select/boy_card.png",
}
const UNSELECTED_SCALE := 0.9
const UNSELECTED_TINT := Color(0.92, 0.92, 0.92)
var bg_image: TextureRect
var title: TextureRect
var cards: Dictionary = {}
var base_pos: Dictionary = {}
var play_btn: Button
var sfx: AudioStreamPlayer
var voice: AudioStreamPlayer
var select_tween: Tween
var float_tween: Tween
var grayscale_material: ShaderMaterial
func _ready() -> void:
	grayscale_material = ShaderMaterial.new()
	grayscale_material.shader = GRAYSCALE_SHADER
	sfx = AudioStreamPlayer.new()
	sfx.bus = "SFX"
	add_child(sfx)
	voice = AudioStreamPlayer.new()
	voice.bus = "VOICE"
	add_child(voice)
	var bg_tex: Texture2D = load(BG_TEXTURE) if ResourceLoader.exists(BG_TEXTURE) else null
	bg_image = TextureRect.new()
	if bg_tex:
		bg_image.texture = bg_tex
		bg_image.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	else:
		var grad := Gradient.new()
		grad.colors = PackedColorArray([Color(0.44, 0.75, 0.98), Color(0.72, 0.90, 1.0)])
		var gtex := GradientTexture2D.new()
		gtex.gradient = grad
		gtex.fill_from = Vector2(0, 0)
		gtex.fill_to = Vector2(0, 1)
		bg_image.texture = gtex
	bg_image.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	bg_image.z_index = -10
	bg_image.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg_image)
	title = TextureRect.new()
	var title_path := LanguageService.get_title_texture_path("choose_character")
	title.texture = load(title_path) if ResourceLoader.exists(title_path) else null
	title.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	title.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(title)
	for who in CARDS:
		var btn := TextureButton.new()
		btn.texture_normal = load(CARDS[who])
		btn.ignore_texture_size = true
		btn.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
		btn.pressed.connect(_select.bind(who))
		add_child(btn)
		cards[who] = btn
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
	get_viewport().size_changed.connect(_layout)
	_layout()
	call_deferred("_play_voice_prompt")
func _layout() -> void:
	var vs := get_viewport_rect().size
	var cx := vs.x * 0.5
	bg_image.position = Vector2.ZERO
	bg_image.size = vs
	var t: Texture2D = title.texture
	var aspect: float = float(t.get_width()) / float(t.get_height())
	var top: float = vs.y * 0.02
	var max_th: float = vs.y * 0.32 - top
	var tw: float = minf(vs.x * 0.72, 900.0)
	var th: float = tw / aspect
	if th > max_th:
		th = max_th
		tw = th * aspect
	title.position = Vector2(cx - tw * 0.5, top)
	title.size = Vector2(tw, th)
	var card_h: float = vs.y * 0.50
	var gap: float = vs.x * 0.03
	var card_y: float = vs.y * 0.34
	var widths: Dictionary = {}
	for who in cards:
		var tex: Texture2D = load(CARDS[who])
		widths[who] = card_h * float(tex.get_width()) / float(tex.get_height())
	base_pos["girl"] = Vector2(cx - gap * 0.5 - widths["girl"], card_y)
	base_pos["boy"] = Vector2(cx + gap * 0.5, card_y)
	for who in cards:
		var btn: TextureButton = cards[who]
		btn.position = base_pos[who]
		btn.size = Vector2(widths[who], card_h)
		btn.pivot_offset = btn.size * 0.5
	play_btn.size = Vector2(minf(vs.x * 0.3, 340.0), 92.0)
	play_btn.position = Vector2(cx - play_btn.size.x * 0.5, vs.y - play_btn.size.y - vs.y * 0.04)
	_apply_selection(false)
func _select(who: String) -> void:
	if who == GameState.selected_character:
		_play(select_sound)
		_apply_selection(true)
		return
	GameState.set_selected_character(who)
	_play(select_sound)
	_apply_selection(true)
func _apply_selection(animate: bool) -> void:
	var selected: String = GameState.selected_character
	if select_tween:
		select_tween.kill()
	if float_tween:
		float_tween.kill()
	for who in cards:
		var btn: TextureButton = cards[who]
		var is_sel: bool = who == selected
		btn.material = null if is_sel else grayscale_material
		btn.modulate = Color(1, 1, 1) if is_sel else UNSELECTED_TINT
		btn.z_index = 1 if is_sel else 0
		btn.position = base_pos[who]
		if not (is_sel and animate):
			btn.scale = Vector2.ONE if is_sel else Vector2.ONE * UNSELECTED_SCALE
	var sel_btn: TextureButton = cards[selected]
	if animate:
		sel_btn.scale = Vector2.ONE * UNSELECTED_SCALE
		select_tween = create_tween()
		select_tween.tween_property(sel_btn, "scale", Vector2(1.06, 1.06), 0.14) \
			.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		select_tween.tween_property(sel_btn, "scale", Vector2.ONE, 0.12) \
			.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	var y: float = base_pos[selected].y
	float_tween = create_tween().set_loops()
	float_tween.tween_property(sel_btn, "position:y", y - 10.0, 1.1) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	float_tween.tween_property(sel_btn, "position:y", y, 1.1) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
func _on_play() -> void:
	SFX.transition_to_scene(main_scene_path)
func _play(stream: AudioStream) -> void:
	if stream:
		sfx.stream = stream
		sfx.play()
func _play_voice_prompt() -> void:
	var stream := LanguageService.get_ui_voice("choose_character")
	if stream:
		voice.stream = stream
		voice.play()
