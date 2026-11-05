extends Node2D

const ProductCatalog := preload("res://education/playtown/src/features/shared/product_catalog.gd")

@export var coins_per_number: int = 8
@export var sample_step: float = 8.0
@export var correct_sound: AudioStream = preload("res://education/playtown/audio/sfx/correct.ogg")
@export var coin_sound: AudioStream = preload("res://education/playtown/audio/sfx/coin.ogg")
@export var exit_scene_path: String = "res://education/playtown/scenes/screens/game_select_shop.tscn"
const ARROW_TEXTURE := "res://education/playtown/assets/ui/back_arrow.png"
const STAR_TEXTURE := "res://education/playtown/assets/ui/star.png"
const MAX_NUMBER := 10
const PRODUCTS_CENTER := Vector2(540.0, 440.0)
const PRODUCTS_AREA := Vector2(560.0, 470.0)
const EQUALS_CENTER := Vector2(905.0, 430.0)
const DIGIT_CENTER := Vector2(1120.0, 430.0)
const DIGIT_AREA_W := 330.0
const MAX_DIGIT_W := 210.0
const DIGIT_ASPECT := 1.3
const GAP_RATIO := 0.18
const OUTLINE_COLOR := Color(0.87, 0.80, 0.62)
const BODY_COLOR := Color(1.0, 1.0, 1.0)
const CARD_COLOR := Color(0.976, 0.906, 0.702)
const BG_TOP := Color(0.72, 0.82, 0.97)
const BG_BOTTOM := Color(0.97, 0.78, 0.70)
const GOLD := Color(0.901961, 0.686275, 0.286275)
const GOLD_SHADOW := Color(0.709804, 0.505882, 0.14902)
const GOLD_OUTLINE := Color(0.85098, 0.631373, 0.231373)
const FILL_COLORS: Array[Color] = [
	Color("#e2595d"), Color("#2a9d8f"), Color("#e9973f"),
	Color("#7c6bd6"), Color("#3f88c5"), Color("#57a55a"),
]
const GRID_COLS := [1, 2, 3, 2, 3, 3, 4, 4, 3, 5]
var number_index: int = 0
var strokes: Array = []
var stroke_samples: Array = []
var stroke_letter: Array = []
var cur_stroke: int = 0
var sample_idx: int = 0
var tracing: bool = false
var letter_done: bool = false
var path_tolerance: float = 70.0
var guide_width: float = 60.0
var letter_root: Node2D
var product_root: Node2D
var outline_lines: Array = []
var body_lines: Array = []
var fill_lines: Array = []
var hint_drawer: Node2D
var celebrate_tween: Tween
var products: Array[Dictionary] = []
var current_product: Dictionary = {}
var voice_player: AudioStreamPlayer
var sfx_player: AudioStreamPlayer
var intro_tween: Tween
var hud: CanvasLayer
var score_label: Label
func _ready() -> void:
	randomize()
	products = ProductCatalog.all(LanguageService.current_locale)
	number_index = clampi(GameState.numbers_traced, 0, MAX_NUMBER - 1)
	voice_player = AudioStreamPlayer.new()
	voice_player.bus = "VOICE"
	add_child(voice_player)
	sfx_player = AudioStreamPlayer.new()
	sfx_player.bus = "SFX"
	add_child(sfx_player)
	_build_background()
	product_root = Node2D.new()
	add_child(product_root)
	letter_root = Node2D.new()
	letter_root.position = DIGIT_CENTER
	add_child(letter_root)
	hint_drawer = preload("res://education/playtown/src/features/tracing/letter_trace_checkpoints.gd").new()
	hint_drawer.game = self
	letter_root.add_child(hint_drawer)
	_build_hud()
	GameState.coin_balance_changed.connect(func(balance: int): score_label.text = str(balance))
	_load_round()
	call_deferred("_play_intro")

func _play_intro() -> void:
	var stream := LanguageService.get_game_voice("write_product_count_intro")
	if stream:
		voice_player.stream = stream
		voice_player.play()
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
	score_panel.anchor_top = 1.0
	score_panel.anchor_bottom = 1.0
	score_panel.offset_left = -280.0
	score_panel.offset_right = -40.0
	score_panel.offset_top = -112.0
	score_panel.offset_bottom = -24.0
	hud.add_child(score_panel)
	score_label = score_panel.score_label
func _build_hud() -> void:
	hud = CanvasLayer.new()
	add_child(hud)
	_build_score()
	var exit_btn := GameExitButton.new()
	exit_btn.anchor_top = 1.0
	exit_btn.anchor_bottom = 1.0
	exit_btn.offset_left = 40.0
	exit_btn.offset_right = 140.0
	exit_btn.offset_top = -120.0
	exit_btn.offset_bottom = -20.0
	exit_btn.pressed.connect(_on_exit_pressed)
	hud.add_child(exit_btn)
	var arrow_tex: Texture2D = load(ARROW_TEXTURE)
	var prev_btn := TextureButton.new()
	prev_btn.texture_normal = arrow_tex
	prev_btn.ignore_texture_size = true
	prev_btn.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
	prev_btn.flip_h = true
	prev_btn.anchor_top = 0.5
	prev_btn.anchor_bottom = 0.5
	prev_btn.offset_left = 40.0
	prev_btn.offset_right = 180.0
	prev_btn.offset_top = -55.0
	prev_btn.offset_bottom = 55.0
	prev_btn.pressed.connect(_on_prev_pressed)
	hud.add_child(prev_btn)
	var next_btn := TextureButton.new()
	next_btn.texture_normal = arrow_tex
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
func _current_number() -> int:
	return number_index + 1
func _load_round() -> void:
	if celebrate_tween:
		celebrate_tween.kill()
		celebrate_tween = null
	letter_done = false
	cur_stroke = 0
	sample_idx = 0
	tracing = false
	letter_root.scale = Vector2.ONE
	for l in outline_lines: l.queue_free()
	for l in body_lines: l.queue_free()
	for l in fill_lines: l.queue_free()
	outline_lines.clear()
	body_lines.clear()
	fill_lines.clear()
	strokes.clear()
	stroke_samples.clear()
	stroke_letter.clear()
	for c in product_root.get_children():
		c.queue_free()
	var n := _current_number()
	current_product = products.pick_random()
	_build_products(n)
	_build_equals()
	_build_digits(str(n))
	_update_dot_limit()
	_update_score()
	hint_drawer.queue_redraw()
	if intro_tween:
		intro_tween.kill()
	_play_number_voice(n)
func _build_products(n: int) -> void:
	var tex: Texture2D = current_product.texture
	var cols: int = GRID_COLS[n - 1]
	var rows: int = ceili(float(n) / cols)
	var cell: float = minf(170.0, minf(PRODUCTS_AREA.x / cols, PRODUCTS_AREA.y / rows))
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
			rect.pressed.connect(func(): _play_number_voice(_current_number()))
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
func _build_digits(text: String) -> void:
	var n := text.length()
	var glyph_w: float = minf(MAX_DIGIT_W, DIGIT_AREA_W / (n + GAP_RATIO * (n - 1)))
	var glyph_h: float = glyph_w * DIGIT_ASPECT
	var gap: float = glyph_w * GAP_RATIO
	var total_w: float = n * glyph_w + (n - 1) * gap
	guide_width = clampf(glyph_w * 0.3, 34.0, 96.0)
	path_tolerance = clampf(glyph_w * 0.38, 45.0, 80.0)
	var start_x := -total_w * 0.5
	var top_y := -glyph_h * 0.5
	for gi in n:
		var origin := Vector2(start_x + gi * (glyph_w + gap), top_y)
		for stroke_norm in LetterPaths.get_strokes(text[gi]):
			var pts := PackedVector2Array()
			for p in stroke_norm:
				pts.append(origin + Vector2(p.x * glyph_w, p.y * glyph_h))
			strokes.append(pts)
			stroke_samples.append(_resample(pts, sample_step))
			stroke_letter.append(gi)
	for pts in strokes:
		outline_lines.append(_make_line(pts, guide_width + 12.0, OUTLINE_COLOR, -2))
		body_lines.append(_make_line(pts, guide_width, BODY_COLOR, -1))
	var color: Color = FILL_COLORS[number_index % FILL_COLORS.size()]
	for i in strokes.size():
		fill_lines.append(_make_line(PackedVector2Array(), maxf(guide_width - 16.0, 16.0), color, 1))
func _make_line(pts: PackedVector2Array, width: float, color: Color, z: int) -> Line2D:
	var line := Line2D.new()
	line.points = pts
	line.width = width
	line.default_color = color
	line.joint_mode = Line2D.LINE_JOINT_ROUND
	line.begin_cap_mode = Line2D.LINE_CAP_ROUND
	line.end_cap_mode = Line2D.LINE_CAP_ROUND
	line.z_index = z
	letter_root.add_child(line)
	return line
func _update_score() -> void:
	score_label.text = str(GameState.get_coin_balance())
func _update_dot_limit() -> void:
	if cur_stroke >= strokes.size():
		hint_drawer.dot_end_stroke = -1
		return
	var li: int = stroke_letter[cur_stroke]
	var endi := cur_stroke
	while endi < strokes.size() and stroke_letter[endi] == li:
		endi += 1
	hint_drawer.dot_end_stroke = endi
func _resample(pts: PackedVector2Array, step: float) -> Array:
	var out: Array = [pts[0]]
	var acc := 0.0
	for i in range(1, pts.size()):
		var a := pts[i - 1]
		var b := pts[i]
		var seg := a.distance_to(b)
		var t := 0.0
		while acc + (seg - t) >= step:
			t += step - acc
			out.append(a.lerp(b, t / seg))
			acc = 0.0
		acc += seg - t
	if out[out.size() - 1].distance_to(pts[pts.size() - 1]) > step * 0.5:
		out.append(pts[pts.size() - 1])
	return out
func _unhandled_input(event: InputEvent) -> void:
	if letter_done:
		return
	if event is InputEventScreenTouch:
		if event.pressed:
			_start_trace(event.position - letter_root.position)
		else:
			tracing = false
	elif event is InputEventScreenDrag:
		_move_trace(event.position - letter_root.position)
func _start_trace(pos: Vector2) -> void:
	var samples: Array = stroke_samples[cur_stroke]
	var front: Vector2 = samples[sample_idx]
	if pos.distance_to(front) <= path_tolerance * 1.3:
		tracing = true
		_move_trace(pos)
func _move_trace(pos: Vector2) -> void:
	if not tracing:
		return
	var samples: Array = stroke_samples[cur_stroke]
	var window := int(160.0 / sample_step)
	var best := -1
	var best_d := path_tolerance
	for i in range(sample_idx, mini(sample_idx + window + 1, samples.size())):
		var d: float = pos.distance_to(samples[i])
		if d < best_d:
			best_d = d
			best = i
	if best > sample_idx:
		sample_idx = best
		_update_fill()
	if sample_idx >= samples.size() - 1:
		_finish_stroke()
func _update_fill() -> void:
	var samples: Array = stroke_samples[cur_stroke]
	var pts := PackedVector2Array()
	for i in range(0, sample_idx + 1):
		pts.append(samples[i])
	fill_lines[cur_stroke].points = pts
	hint_drawer.queue_redraw()
func _finish_stroke() -> void:
	tracing = false
	var full := PackedVector2Array()
	for p in stroke_samples[cur_stroke]:
		full.append(p)
	fill_lines[cur_stroke].points = full
	cur_stroke += 1
	sample_idx = 0
	if cur_stroke >= strokes.size():
		_update_dot_limit()
		hint_drawer.queue_redraw()
		_finish_number()
		return
	_play_sfx(correct_sound)
	_update_dot_limit()
	hint_drawer.queue_redraw()
func _finish_number() -> void:
	letter_done = true
	SFX.play_praise(get_viewport_rect().size * 0.5, 0.9)
	if intro_tween:
		intro_tween.kill()
	GameState.add_coins(coins_per_number)
	if number_index >= GameState.numbers_traced:
		GameState.set_numbers_traced(number_index + 1)
	_play_sfx(coin_sound)
	_play_number_voice(_current_number())
	_update_score()
	celebrate_tween = create_tween()
	celebrate_tween.tween_interval(0.9)
	celebrate_tween.tween_property(letter_root, "scale", Vector2(1.15, 1.15), 0.25) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	celebrate_tween.tween_property(letter_root, "scale", Vector2.ONE, 0.25) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	celebrate_tween.tween_callback(_advance_round)
func _advance_round() -> void:
	number_index = (number_index + 1) % MAX_NUMBER
	_load_round()
func _on_prev_pressed() -> void:
	number_index = wrapi(number_index - 1, 0, MAX_NUMBER)
	_load_round()
func _on_next_pressed() -> void:
	number_index = wrapi(number_index + 1, 0, MAX_NUMBER)
	_load_round()
func _on_exit_pressed() -> void:
	SFX.transition_to_scene(exit_scene_path)
func _play_number_voice(n: int) -> void:
	var stream := LanguageService.get_number_voice(n)
	if stream:
		voice_player.stream = stream
		voice_player.play()
func _play_sfx(stream: AudioStream) -> void:
	if stream:
		sfx_player.stream = stream
		sfx_player.play()
