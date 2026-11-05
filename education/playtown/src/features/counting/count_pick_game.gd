extends Node2D

const ProductCatalog := preload("res://education/playtown/src/features/shared/product_catalog.gd")

@export var coins_per_round: int = 5
@export var max_number: int = 10
@export var options_count: int = 3
@export var correct_sound: AudioStream = preload("res://education/playtown/audio/sfx/correct.ogg")
@export var wrong_sound: AudioStream = preload("res://education/playtown/audio/sfx/wrong.ogg")
@export var coin_sound: AudioStream = preload("res://education/playtown/audio/sfx/coin.ogg")
@export var exit_scene_path: String = "res://education/playtown/scenes/screens/game_select_shop.tscn"
const ARROW_TEXTURE := "res://education/playtown/assets/ui/back_arrow.png"
const STAR_TEXTURE := "res://education/playtown/assets/ui/star.png"
const PRODUCTS_CENTER := Vector2(560.0, 400.0)
const PRODUCTS_AREA := Vector2(580.0, 480.0)
const EQUALS_CENTER := Vector2(925.0, 390.0)
const OPTIONS_X := 1120.0
const OPTION_SIZE := 150.0
const OPTION_GAP := 40.0
const OUTLINE_COLOR := Color(0.87, 0.80, 0.62)
const BODY_COLOR := Color(1.0, 1.0, 1.0)
const CARD_COLOR := Color(0.976, 0.906, 0.702)
const BG_TOP := Color(0.80, 0.72, 0.95)
const BG_BOTTOM := Color(0.66, 0.90, 0.85)
const GOLD := Color(0.901961, 0.686275, 0.286275)
const GOLD_SHADOW := Color(0.709804, 0.505882, 0.14902)
const GOLD_OUTLINE := Color(0.85098, 0.631373, 0.231373)
const GRID_COLS := [1, 2, 3, 2, 3, 3, 4, 4, 3, 5]
const GREEN := Color(0.30, 0.69, 0.35)
const RED := Color(0.85, 0.35, 0.32)
var current_number: int = 0
var previous_number: int = 0
var products: Array[Dictionary] = []
var current_product: Dictionary = {}
var round_over: bool = false
var product_root: Node2D
var option_buttons: Array = []
var next_round_tween: Tween
var voice_player: AudioStreamPlayer
var sfx_player: AudioStreamPlayer
var hud: CanvasLayer
var score_label: Label
func _ready() -> void:
	randomize()
	products = ProductCatalog.all(LanguageService.current_locale)
	voice_player = AudioStreamPlayer.new()
	voice_player.bus = "VOICE"
	add_child(voice_player)
	sfx_player = AudioStreamPlayer.new()
	sfx_player.bus = "SFX"
	add_child(sfx_player)
	_build_background()
	product_root = Node2D.new()
	add_child(product_root)
	_build_hud()
	GameState.coin_balance_changed.connect(func(balance: int): score_label.text = str(balance))
	_load_round()
	call_deferred("_play_intro")
func _build_background() -> void:
	var grad := Gradient.new()
	grad.colors = PackedColorArray([BG_TOP, BG_BOTTOM])
	var gtex := GradientTexture2D.new()
	gtex.gradient = grad
	gtex.fill_from = Vector2(0, 0)
	gtex.fill_to = Vector2(0.15, 1.0)
	var bg := TextureRect.new()
	bg.texture = gtex
	bg.size = get_viewport_rect().size
	bg.z_index = -10
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)
	get_viewport().size_changed.connect(func(): bg.size = get_viewport_rect().size)
	var card := Panel.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = CARD_COLOR
	sb.set_corner_radius_all(48)
	sb.shadow_color = Color(0, 0, 0, 0.18)
	sb.shadow_size = 18
	sb.shadow_offset = Vector2(0, 8)
	card.add_theme_stylebox_override("panel", sb)
	card.position = Vector2(218, 40)
	card.size = Vector2(1100, 688)
	card.z_index = -9
	card.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(card)
func _build_score() -> void:
	var score_panel := GameScorePanel.new()
	score_panel.anchor_left = 1.0
	score_panel.anchor_right = 1.0
	score_panel.anchor_top = 0.0
	score_panel.anchor_bottom = 0.0
	score_panel.offset_left = -280.0
	score_panel.offset_right = -40.0
	score_panel.offset_top = 24.0
	score_panel.offset_bottom = 112.0
	hud.add_child(score_panel)
	score_label = score_panel.score_label

func _play_intro() -> void:
	var stream := LanguageService.get_game_voice("count_products_intro")
	if stream:
		voice_player.stream = stream
		voice_player.play()
func _build_hud() -> void:
	hud = CanvasLayer.new()
	add_child(hud)
	_build_score()
	var exit_btn := GameExitButton.new()
	exit_btn.anchor_top = 0.0
	exit_btn.anchor_bottom = 0.0
	exit_btn.offset_left = 40.0
	exit_btn.offset_right = 140.0
	exit_btn.offset_top = 24.0
	exit_btn.offset_bottom = 124.0
	exit_btn.pressed.connect(_on_exit_pressed)
	hud.add_child(exit_btn)
	var next_btn := TextureButton.new()
	next_btn.texture_normal = load(ARROW_TEXTURE)
	next_btn.ignore_texture_size = true
	next_btn.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
	next_btn.anchor_left = 1.0
	next_btn.anchor_right = 1.0
	next_btn.anchor_top = 0.5
	next_btn.anchor_bottom = 0.5
	next_btn.offset_left = -180.0
	next_btn.offset_right = -40.0
	next_btn.offset_top = -55.0
	next_btn.offset_bottom = 55.0
	next_btn.pressed.connect(_on_next_pressed)
	hud.add_child(next_btn)
func _load_round() -> void:
	if next_round_tween:
		next_round_tween.kill()
		next_round_tween = null
	round_over = false
	option_buttons.clear()
	for c in product_root.get_children():
		c.queue_free()
	previous_number = current_number
	current_number = randi_range(1, max_number)
	while current_number == previous_number:
		current_number = randi_range(1, max_number)
	current_product = products.pick_random()
	_build_products(current_number)
	_build_equals()
	_build_options()
	_update_score()
func _build_products(n: int) -> void:
	var tex: Texture2D = current_product.texture
	var cols: int = GRID_COLS[n - 1]
	var rows: int = ceili(float(n) / cols)
	var cell: float = minf(175.0, minf(PRODUCTS_AREA.x / cols, PRODUCTS_AREA.y / rows))
	var icon: float = cell * 0.92
	var placed := 0
	for r in rows:
		var in_row: int = mini(cols, n - placed)
		var row_w: float = in_row * cell
		for c in in_row:
			var rect := TextureButton.new()
			rect.texture_normal = tex
			rect.ignore_texture_size = true
			rect.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
			rect.position = PRODUCTS_CENTER + Vector2(
				-row_w * 0.5 + c * cell + (cell - icon) * 0.5,
				-rows * cell * 0.5 + r * cell + (cell - icon) * 0.5
			)
			rect.size = Vector2(icon, icon)
			product_root.add_child(rect)
			placed += 1
func _build_equals() -> void:
	for dy in [-38.0, 38.0]:
		var pts := PackedVector2Array([
			EQUALS_CENTER + Vector2(-55, dy),
			EQUALS_CENTER + Vector2(55, dy),
		])
		var outline := Line2D.new()
		outline.points = pts
		outline.width = 46.0
		outline.default_color = OUTLINE_COLOR
		outline.begin_cap_mode = Line2D.LINE_CAP_ROUND
		outline.end_cap_mode = Line2D.LINE_CAP_ROUND
		product_root.add_child(outline)
		var body := Line2D.new()
		body.points = pts
		body.width = 34.0
		body.default_color = BODY_COLOR
		body.begin_cap_mode = Line2D.LINE_CAP_ROUND
		body.end_cap_mode = Line2D.LINE_CAP_ROUND
		product_root.add_child(body)
func _build_options() -> void:
	var numbers: Array[int] = [current_number]
	while numbers.size() < options_count:
		var d := randi_range(1, max_number)
		if not numbers.has(d):
			numbers.append(d)
	numbers.shuffle()
	var total_h: float = options_count * OPTION_SIZE + (options_count - 1) * OPTION_GAP
	var top_y: float = 384.0 - total_h * 0.5
	for i in numbers.size():
		var btn := Button.new()
		btn.text = str(numbers[i])
		btn.position = Vector2(OPTIONS_X, top_y + i * (OPTION_SIZE + OPTION_GAP))
		btn.size = Vector2(OPTION_SIZE, OPTION_SIZE)
		btn.add_theme_font_size_override("font_size", 84)
		btn.add_theme_color_override("font_color", GOLD)
		btn.add_theme_color_override("font_hover_color", GOLD)
		btn.add_theme_color_override("font_pressed_color", GOLD)
		btn.add_theme_color_override("font_shadow_color", GOLD_SHADOW)
		btn.add_theme_color_override("font_outline_color", GOLD_OUTLINE)
		btn.add_theme_constant_override("outline_size", 5)
		_style_option(btn, BODY_COLOR)
		btn.pressed.connect(_on_option_pressed.bind(btn, numbers[i]))
		product_root.add_child(btn)
		option_buttons.append(btn)
func _style_option(btn: Button, color: Color) -> void:
	for state in ["normal", "hover", "pressed", "disabled"]:
		var sb := StyleBoxFlat.new()
		sb.bg_color = color if state != "pressed" else color.darkened(0.1)
		sb.set_corner_radius_all(34)
		sb.shadow_color = Color(0, 0, 0, 0.18)
		sb.shadow_size = 10
		sb.shadow_offset = Vector2(0, 5)
		sb.border_width_bottom = 6
		sb.border_color = OUTLINE_COLOR
		btn.add_theme_stylebox_override(state, sb)
func _on_option_pressed(btn: Button, value: int) -> void:
	if round_over:
		return
	if value == current_number:
		round_over = true
		_style_option(btn, GREEN)
		btn.add_theme_color_override("font_color", Color(1, 1, 1))
		btn.add_theme_color_override("font_outline_color", GREEN.darkened(0.3))
		GameState.add_coins(coins_per_round)
		_update_score()
		_play_sfx(coin_sound)
		_play_number_voice(current_number)
		SFX.play_praise(get_viewport_rect().size * 0.5, 0.8)
		btn.pivot_offset = btn.size * 0.5
		next_round_tween = create_tween()
		next_round_tween.tween_property(btn, "scale", Vector2(1.2, 1.2), 0.2) \
			.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		next_round_tween.tween_property(btn, "scale", Vector2.ONE, 0.2) \
			.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
		next_round_tween.tween_interval(0.6)
		next_round_tween.tween_callback(_load_round)
	else:
		_play_sfx(wrong_sound)
		SFX.play_retry(get_viewport_rect().size * 0.5)
		_style_option(btn, RED)
		btn.add_theme_color_override("font_color", Color(1, 1, 1))
		btn.disabled = true
		btn.pivot_offset = btn.size * 0.5
		var x := btn.position.x
		var shake := create_tween()
		shake.tween_property(btn, "position:x", x - 12.0, 0.05)
		shake.tween_property(btn, "position:x", x + 12.0, 0.1)
		shake.tween_property(btn, "position:x", x - 8.0, 0.08)
		shake.tween_property(btn, "position:x", x, 0.06)
func _on_next_pressed() -> void:
	_load_round()
func _on_exit_pressed() -> void:
	SFX.transition_to_scene(exit_scene_path)
func _update_score() -> void:
	score_label.text = str(GameState.get_coin_balance())
func _play_number_voice(n: int) -> void:
	var stream := LanguageService.get_number_voice(n)
	if stream:
		voice_player.stream = stream
		voice_player.play()
func _play_sfx(stream: AudioStream) -> void:
	if stream:
		sfx_player.stream = stream
		sfx_player.play()
