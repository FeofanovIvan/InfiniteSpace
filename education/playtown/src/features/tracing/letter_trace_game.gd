extends Node2D
@export var coins_per_letter: int = 5
@export var path_tolerance: float = 80.0
@export var guide_width: float = 96.0
@export var sample_step: float = 8.0
@export var correct_sound: AudioStream = preload("res://education/playtown/audio/sfx/correct.ogg")
@export var coin_sound: AudioStream = preload("res://education/playtown/audio/sfx/coin.ogg")
@export var exit_scene_path: String = "res://education/playtown/scenes/screens/game_select_school.tscn"
const ARROW_TEXTURE := "res://education/playtown/assets/ui/back_arrow.png"
const STAR_TEXTURE := "res://education/playtown/assets/ui/star.png"
const BOX_POS := Vector2(590.0, 170.0)
const BOX_SIZE := Vector2(360.0, 470.0)
const OUTLINE_COLOR := Color(0.87, 0.80, 0.62)
const BODY_COLOR := Color(1.0, 1.0, 1.0)
const CARD_COLOR := Color(0.976, 0.906, 0.702)
const BG_TOP := Color(0.62, 0.78, 0.96)
const BG_BOTTOM := Color(0.93, 0.70, 0.86)
const GOLD := Color(0.901961, 0.686275, 0.286275)
const GOLD_SHADOW := Color(0.709804, 0.505882, 0.14902)
const GOLD_OUTLINE := Color(0.85098, 0.631373, 0.231373)
const FILL_COLORS: Array[Color] = [
	Color("#e2595d"), Color("#2a9d8f"), Color("#e9973f"),
	Color("#7c6bd6"), Color("#3f88c5"), Color("#57a55a"),
]
var letter_index: int = 0
var strokes: Array = []
var stroke_samples: Array = []
var cur_stroke: int = 0
var sample_idx: int = 0
var tracing: bool = false
var letter_done: bool = false
var letter_root: Node2D
var outline_lines: Array = []
var body_lines: Array = []
var fill_lines: Array = []
var hint_drawer: Node2D
var celebrate_tween: Tween
var voice_player: AudioStreamPlayer
var sfx_player: AudioStreamPlayer
var hud: CanvasLayer
var score_label: Label
var letters: Array[String] = []
var intro_pending := true
func fill_color() -> Color:
	return FILL_COLORS[letter_index % FILL_COLORS.size()]
func _letter_center() -> Vector2:
	return BOX_POS + BOX_SIZE * 0.5
func _ready() -> void:
	letters = LanguageService.get_alphabet()
	letter_index = clampi(GameState.letters_traced, 0, letters.size() - 1)
	voice_player = AudioStreamPlayer.new()
	voice_player.bus = "VOICE"
	add_child(voice_player)
	sfx_player = AudioStreamPlayer.new()
	sfx_player.bus = "SFX"
	add_child(sfx_player)
	_build_background()
	letter_root = Node2D.new()
	letter_root.position = _letter_center()
	add_child(letter_root)
	hint_drawer = preload("res://education/playtown/src/features/tracing/letter_trace_checkpoints.gd").new()
	hint_drawer.game = self
	letter_root.add_child(hint_drawer)
	_build_hud()
	GameState.coin_balance_changed.connect(func(balance: int): score_label.text = str(balance))
	_load_letter()
	call_deferred("_play_instruction_and_letter")
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
	card.position = BOX_POS - Vector2(150, 120)
	card.size = BOX_SIZE + Vector2(300, 220)
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
	prev_btn.offset_left = 60.0
	prev_btn.offset_right = 200.0
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
	next_btn.offset_left = -200.0
	next_btn.offset_right = -60.0
	next_btn.offset_top = -55.0
	next_btn.offset_bottom = 55.0
	next_btn.pressed.connect(_on_next_pressed)
	hud.add_child(next_btn)
func _load_letter() -> void:
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
	var letter := _current_letter()
	var center := _letter_center()
	for stroke_norm in LetterPaths.get_strokes(letter):
		var pts := PackedVector2Array()
		for p in stroke_norm:
			pts.append(BOX_POS + Vector2(p.x * BOX_SIZE.x, p.y * BOX_SIZE.y) - center)
		strokes.append(pts)
		stroke_samples.append(_resample(pts, sample_step))
	for pts in strokes:
		outline_lines.append(_make_line(pts, guide_width + 16.0, OUTLINE_COLOR, -2))
		body_lines.append(_make_line(pts, guide_width, BODY_COLOR, -1))
	for i in strokes.size():
		fill_lines.append(_make_line(PackedVector2Array(), guide_width - 22.0, fill_color(), 1))
	_update_score()
	hint_drawer.queue_redraw()
	if not intro_pending:
		_play_letter_voice()
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
func _current_letter() -> String:
	return letters[letter_index]
func _update_score() -> void:
	score_label.text = str(GameState.get_coin_balance())
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
	hint_drawer.queue_redraw()
	if cur_stroke >= strokes.size():
		_finish_letter()
	else:
		_play_sfx(correct_sound)
func _finish_letter() -> void:
	letter_done = true
	SFX.play_praise(get_viewport_rect().size * 0.5, 0.9)
	GameState.add_coins(coins_per_letter)
	if letter_index >= GameState.letters_traced:
		GameState.set_letters_traced(letter_index + 1)
	_play_sfx(coin_sound)
	_play_letter_voice()
	_update_score()
	celebrate_tween = create_tween()
	celebrate_tween.tween_interval(0.9)
	celebrate_tween.tween_property(letter_root, "scale", Vector2(1.15, 1.15), 0.25) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	celebrate_tween.tween_property(letter_root, "scale", Vector2.ONE, 0.25) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	celebrate_tween.tween_callback(_advance_letter)
func _advance_letter() -> void:
	letter_index = (letter_index + 1) % letters.size()
	_load_letter()
func _on_prev_pressed() -> void:
	letter_index = wrapi(letter_index - 1, 0, letters.size())
	_load_letter()
func _on_next_pressed() -> void:
	letter_index = wrapi(letter_index + 1, 0, letters.size())
	_load_letter()
func _on_exit_pressed() -> void:
	SFX.transition_to_scene(exit_scene_path)
func _play_letter_voice() -> void:
	var stream := LanguageService.get_letter_voice(_current_letter())
	if stream == null and LanguageService.learning_locale == "en":
		var path := "res://education/playtown/audio/sfx/alphabet/%s.ogg" % _current_letter().to_lower()
		if ResourceLoader.exists(path):
			stream = load(path)
	if stream:
		voice_player.stop()
		voice_player.stream = stream
		voice_player.play()
func _play_instruction_and_letter() -> void:
	var stream := LanguageService.get_game_voice("letter_trace_intro")
	if stream:
		voice_player.stop()
		voice_player.stream = stream
		voice_player.play()
		await voice_player.finished
	intro_pending = false
	_play_letter_voice()
func _play_sfx(stream: AudioStream) -> void:
	if stream:
		sfx_player.stream = stream
		sfx_player.play()
