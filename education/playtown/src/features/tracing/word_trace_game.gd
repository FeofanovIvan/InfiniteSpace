extends Node2D
const ObjectCatalog := preload("res://education/playtown/src/features/shared/learning_object_catalog.gd")
const CATEGORY_BAR_SCRIPT: Script = preload("res://education/playtown/src/features/shared/word_category_bar.gd")
@export var coins_per_word: int = 10
@export var sample_step: float = 8.0
@export var correct_sound: AudioStream = preload("res://education/playtown/audio/sfx/correct.ogg")
@export var coin_sound: AudioStream = preload("res://education/playtown/audio/sfx/coin.ogg")
@export var exit_scene_path: String = "res://education/playtown/scenes/screens/game_select_school.tscn"
const ARROW_TEXTURE := "res://education/playtown/assets/ui/back_arrow.png"
const STAR_TEXTURE := "res://education/playtown/assets/ui/star.png"
const MAX_LETTER_W := 230.0
const LETTER_ASPECT := 1.3
const GAP_RATIO := 0.22
const OUTLINE_COLOR := Color(0.87, 0.80, 0.62)
const BODY_COLOR := Color(1.0, 1.0, 1.0)
const CARD_COLOR := Color(0.976, 0.906, 0.702)
const BG_TOP := Color(0.62, 0.86, 0.80)
const BG_BOTTOM := Color(0.97, 0.85, 0.60)
const GOLD := Color(0.901961, 0.686275, 0.286275)
const GOLD_SHADOW := Color(0.709804, 0.505882, 0.14902)
const GOLD_OUTLINE := Color(0.85098, 0.631373, 0.231373)
const FILL_COLORS: Array[Color] = [
	Color("#e2595d"), Color("#2a9d8f"), Color("#e9973f"),
	Color("#7c6bd6"), Color("#3f88c5"), Color("#57a55a"),
]
var word_index: int = 0
var word_objects: Array[Dictionary] = []
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
var outline_lines: Array = []
var body_lines: Array = []
var fill_lines: Array = []
var hint_drawer: Node2D
var celebrate_tween: Tween
var voice_player: AudioStreamPlayer
var sfx_player: AudioStreamPlayer
var hud: CanvasLayer
var score_panel: GameScorePanel
var score_label: Label
var score_star: TextureRect
var word_icon: TextureButton
var category_bar: Control
var prev_button: TextureButton
var next_button: TextureButton
var exit_button: Button
var main_card: Panel
var category_card: Panel
var trace_area_size := Vector2(1000.0, 340.0)
var selected_category := "objects"
func _ready() -> void:
	_reload_word_pool()
	if word_objects.is_empty():
		return
	word_index = 0
	voice_player = AudioStreamPlayer.new()
	voice_player.bus = "VOICE"
	add_child(voice_player)
	sfx_player = AudioStreamPlayer.new()
	sfx_player.bus = "SFX"
	add_child(sfx_player)
	_build_background()
	letter_root = Node2D.new()
	letter_root.position = Vector2(768.0, 460.0)
	add_child(letter_root)
	hint_drawer = preload("res://education/playtown/src/features/tracing/letter_trace_checkpoints.gd").new()
	hint_drawer.game = self
	letter_root.add_child(hint_drawer)
	_build_hud()
	GameState.coin_balance_changed.connect(_set_score_text)
	get_viewport().size_changed.connect(_layout_hud_controls)
	_layout_hud_controls()
	_load_word(false)
	_play_intro()
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
	main_card = Panel.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = CARD_COLOR
	sb.set_corner_radius_all(48)
	sb.shadow_color = Color(0, 0, 0, 0.18)
	sb.shadow_size = 18
	sb.shadow_offset = Vector2(0, 8)
	main_card.add_theme_stylebox_override("panel", sb)
	main_card.z_index = -9
	main_card.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(main_card)
	category_card = Panel.new()
	var category_style := sb.duplicate() as StyleBoxFlat
	category_style.set_corner_radius_all(36)
	category_style.shadow_size = 14
	category_card.add_theme_stylebox_override("panel", category_style)
	category_card.z_index = -9
	category_card.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(category_card)
func _build_score() -> void:
	score_panel = GameScorePanel.new()
	hud.add_child(score_panel)
	score_star = score_panel.score_icon
	score_label = score_panel.score_label
func _build_hud() -> void:
	hud = CanvasLayer.new()
	add_child(hud)
	_build_score()
	category_bar = CATEGORY_BAR_SCRIPT.new()
	category_bar.setup(selected_category)
	category_bar.category_selected.connect(_on_category_selected)
	hud.add_child(category_bar)
	exit_button = GameExitButton.new()
	exit_button.pressed.connect(_on_exit_pressed)
	hud.add_child(exit_button)
	var arrow_tex: Texture2D = load(ARROW_TEXTURE)
	prev_button = TextureButton.new()
	prev_button.texture_normal = arrow_tex
	prev_button.ignore_texture_size = true
	prev_button.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
	prev_button.flip_h = true
	prev_button.pressed.connect(_on_prev_pressed)
	hud.add_child(prev_button)
	next_button = TextureButton.new()
	next_button.texture_normal = arrow_tex
	next_button.ignore_texture_size = true
	next_button.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
	next_button.pressed.connect(_on_next_pressed)
	hud.add_child(next_button)
	word_icon = TextureButton.new()
	word_icon.ignore_texture_size = true
	word_icon.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
	word_icon.size = Vector2(190, 190)
	word_icon.pressed.connect(_play_word_voice)
	add_child(word_icon)
func _current_word() -> String:
	return String(word_objects[word_index].text)
func _load_word(play_voice: bool = true) -> void:
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
	var word := _current_word().to_upper()
	var n := word.length()
	var width_units: float = float(n) + GAP_RATIO * float(n - 1)
	var safe_width: float = maxf(280.0, trace_area_size.x - 112.0)
	var safe_height: float = maxf(150.0, trace_area_size.y - 112.0)
	var letter_w: float = minf(MAX_LETTER_W, safe_width / width_units)
	letter_w = minf(letter_w, safe_height / LETTER_ASPECT)
	var letter_h: float = letter_w * LETTER_ASPECT
	var gap: float = letter_w * GAP_RATIO
	var total_w: float = n * letter_w + (n - 1) * gap
	guide_width = clampf(letter_w * 0.27, 34.0, 96.0)
	path_tolerance = clampf(letter_w * 0.35, 45.0, 80.0)
	var start_x := -total_w * 0.5
	var top_y := -letter_h * 0.5
	for li in n:
		var origin := Vector2(start_x + li * (letter_w + gap), top_y)
		for stroke_norm in LetterPaths.get_strokes(word[li]):
			var pts := PackedVector2Array()
			for p in stroke_norm:
				pts.append(origin + Vector2(p.x * letter_w, p.y * letter_h))
			strokes.append(pts)
			stroke_samples.append(_resample(pts, sample_step))
			stroke_letter.append(li)
	for pts in strokes:
		outline_lines.append(_make_line(pts, guide_width + 12.0, OUTLINE_COLOR, -2))
		body_lines.append(_make_line(pts, guide_width, BODY_COLOR, -1))
	for i in strokes.size():
		var color: Color = FILL_COLORS[stroke_letter[i] % FILL_COLORS.size()]
		fill_lines.append(_make_line(PackedVector2Array(), maxf(guide_width - 16.0, 16.0), color, 1))
	word_icon.texture_normal = word_objects[word_index].texture
	_update_dot_limit()
	_update_score()
	hint_drawer.queue_redraw()
	if play_voice:
		_play_word_voice()
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
	_set_score_text(GameState.get_coin_balance())

func _set_score_text(balance: int) -> void:
	var value := str(balance)
	score_label.text = value
	var available_width: float = maxf(64.0, score_label.size.x - 10.0)
	var estimated_width_per_point := 0.62
	var font_size := clampi(int(available_width / (maxi(1, value.length()) * estimated_width_per_point)), 22, 44)
	score_label.add_theme_font_size_override("font_size", font_size)
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
	var prev_letter: int = stroke_letter[cur_stroke]
	cur_stroke += 1
	sample_idx = 0
	if cur_stroke >= strokes.size():
		_update_dot_limit()
		hint_drawer.queue_redraw()
		_finish_word()
		return
	if stroke_letter[cur_stroke] != prev_letter:
		_play_letter_voice(prev_letter)
	else:
		_play_sfx(correct_sound)
	_update_dot_limit()
	hint_drawer.queue_redraw()
func _finish_word() -> void:
	letter_done = true
	SFX.play_praise(get_viewport_rect().size * 0.5, 1.0)
	GameState.add_coins(coins_per_word)
	if word_index >= GameState.words_traced:
		GameState.set_words_traced(word_index + 1)
	_play_sfx(coin_sound)
	_play_word_voice()
	_update_score()
	celebrate_tween = create_tween()
	celebrate_tween.tween_interval(1.0)
	celebrate_tween.tween_property(letter_root, "scale", Vector2(1.12, 1.12), 0.25) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	celebrate_tween.tween_property(letter_root, "scale", Vector2.ONE, 0.25) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	celebrate_tween.tween_callback(_advance_word)
func _advance_word() -> void:
	word_index += 1
	if word_index >= word_objects.size():
		word_objects.shuffle()
		word_index = 0
	_load_word()
func _on_prev_pressed() -> void:
	word_index = wrapi(word_index - 1, 0, word_objects.size())
	_load_word()
func _on_next_pressed() -> void:
	word_index = wrapi(word_index + 1, 0, word_objects.size())
	_load_word()
func _on_exit_pressed() -> void:
	SFX.transition_to_scene(exit_scene_path)
func _play_word_voice() -> void:
	var voice := word_objects[word_index].voice as AudioStream
	if voice:
		voice_player.stream = voice
		voice_player.play()

func _play_intro() -> void:
	var intro := LanguageService.get_game_voice("word_trace_intro")
	if intro:
		voice_player.stop()
		voice_player.stream = intro
		voice_player.play()
		await voice_player.finished
		if voice_player.stream != intro:
			return
	_play_word_voice()
func _play_letter_voice(letter_i: int) -> void:
	var voice := LanguageService.get_letter_voice(_current_word().substr(letter_i, 1))
	if voice:
		voice_player.stream = voice
		voice_player.play()
func _play_sfx(stream: AudioStream) -> void:
	if stream:
		sfx_player.stream = stream
		sfx_player.play()

func _reload_word_pool() -> void:
	word_objects = ObjectCatalog.all(LanguageService.current_locale, selected_category)
	word_objects.shuffle()

func _on_category_selected(category: String) -> void:
	selected_category = category
	_reload_word_pool()
	if word_objects.is_empty():
		return
	word_index = 0
	_load_word()

func _layout_hud_controls() -> void:
	if category_bar == null or word_icon == null or prev_button == null or next_button == null or exit_button == null:
		return
	var viewport_size := get_viewport_rect().size
	var safe := _safe_area_insets(viewport_size)
	var margin: float = clampf(viewport_size.x * 0.016, 18.0, 30.0)
	var left_edge: float = safe.x + margin
	var right_edge: float = viewport_size.x - safe.z - margin
	var panel_top: float = safe.y + clampf(viewport_size.y * 0.032, 18.0, 28.0)
	var panel_bottom: float = viewport_size.y - safe.w - clampf(viewport_size.y * 0.032, 18.0, 28.0)
	var panel_height: float = maxf(560.0, panel_bottom - panel_top)
	var category_width: float = clampf(viewport_size.x * 0.105, 150.0, 176.0)
	var main_left: float = left_edge + category_width + clampf(viewport_size.x * 0.016, 20.0, 30.0)
	category_card.position = Vector2(left_edge, panel_top)
	category_card.size = Vector2(category_width, panel_height)
	main_card.position = Vector2(main_left, panel_top)
	main_card.size = Vector2(maxf(760.0, right_edge - main_left), panel_height)
	var bar_padding: float = clampf(category_width * 0.11, 15.0, 20.0)
	var exit_size: float = minf(clampf(category_width * 0.68, 102.0, 118.0), panel_height * 0.16)
	var exit_bottom: float = category_card.position.y + category_card.size.y - 20.0
	exit_button.position = Vector2(category_card.position.x + (category_width - exit_size) * 0.5, exit_bottom - exit_size)
	exit_button.size = Vector2.ONE * exit_size
	category_bar.set_layout(Rect2(
		Vector2(category_card.position.x + bar_padding, category_card.position.y + 22.0),
		Vector2(category_width - bar_padding * 2.0, exit_button.position.y - category_card.position.y - 38.0)
	), true)
	var content_center_x: float = main_card.position.x + main_card.size.x * 0.5
	var object_side: float = clampf(panel_height * 0.25, 148.0, 190.0)
	word_icon.size = Vector2.ONE * object_side
	word_icon.position = Vector2(content_center_x - object_side * 0.5, panel_top + clampf(panel_height * 0.06, 30.0, 46.0))
	var arrow_size := Vector2(124.0, 96.0) * clampf(panel_height / 710.0, 0.78, 1.0)
	var icon_center := word_icon.position + word_icon.size * 0.5
	var side_distance: float = clampf(main_card.size.x * 0.29, object_side * 1.45, 355.0)
	prev_button.position = Vector2(icon_center.x - side_distance - arrow_size.x * 0.5, icon_center.y - arrow_size.y * 0.5)
	prev_button.size = arrow_size
	next_button.position = Vector2(icon_center.x + side_distance - arrow_size.x * 0.5, icon_center.y - arrow_size.y * 0.5)
	next_button.size = arrow_size
	var score_height: float = clampf(panel_height * 0.085, 54.0, 64.0)
	var score_y: float = main_card.position.y + main_card.size.y - score_height - clampf(panel_height * 0.025, 16.0, 24.0)
	var score_group_width: float = clampf(main_card.size.x * 0.20, 190.0, 250.0)
	var score_group_left: float = content_center_x - score_group_width * 0.5
	score_panel.position = Vector2(score_group_left, score_y)
	score_panel.size = Vector2(score_group_width, score_height)
	var trace_top: float = word_icon.position.y + word_icon.size.y + clampf(panel_height * 0.025, 14.0, 22.0)
	var trace_bottom: float = score_y - clampf(panel_height * 0.025, 14.0, 22.0)
	var new_trace_size := Vector2(maxf(320.0, main_card.size.x - 92.0), maxf(150.0, trace_bottom - trace_top))
	var rebuild_trace: bool = not trace_area_size.is_equal_approx(new_trace_size)
	trace_area_size = new_trace_size
	letter_root.position = Vector2(content_center_x, (trace_top + trace_bottom) * 0.5)
	_set_score_text(GameState.get_coin_balance())
	if rebuild_trace and not strokes.is_empty():
		_load_word(false)

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
