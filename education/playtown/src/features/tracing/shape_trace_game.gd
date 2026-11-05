extends Node2D
@export var correct_sound: AudioStream = preload("res://education/playtown/audio/sfx/correct.ogg")
@export var wrong_sound: AudioStream = preload("res://education/playtown/audio/sfx/wrong.ogg")
@export var coin_sound: AudioStream = preload("res://education/playtown/audio/sfx/coin.ogg")
@export var coins_per_shape: int = 5
@export var exit_scene_path: String = "res://education/playtown/scenes/screens/game_select_school.tscn"
const ARROW_TEXTURE := "res://education/playtown/assets/ui/back_arrow.png"
const STAR_TEXTURE := "res://education/playtown/assets/ui/star.png"
const GOLD := Color(0.901961, 0.686275, 0.286275)
const GOLD_SHADOW := Color(0.709804, 0.505882, 0.14902)
const GOLD_OUTLINE := Color(0.85098, 0.631373, 0.231373)
const BORDER_COLOR := Color(0.62, 0.45, 0.28)
const CARD_COLOR := Color(0.976, 0.906, 0.702)
const TAB_COLOR := Color(0.90, 0.80, 0.58)
const TAB_TEXT_COLOR := Color(0.35, 0.22, 0.10)
const TITLE_TEXT_COLOR := Color(0.35, 0.22, 0.10)
const GridScript := preload("res://education/playtown/src/features/tracing/shape_trace_grid.gd")
const PENCIL_TEXTURES: Array[Texture2D] = [
	preload("res://education/playtown/assets/tracing/pencils/01_red.png"),
	preload("res://education/playtown/assets/tracing/pencils/02_orange.png"),
	preload("res://education/playtown/assets/tracing/pencils/03_yellow.png"),
	preload("res://education/playtown/assets/tracing/pencils/04_green.png"),
	preload("res://education/playtown/assets/tracing/pencils/05_cyan.png"),
	preload("res://education/playtown/assets/tracing/pencils/06_blue.png"),
	preload("res://education/playtown/assets/tracing/pencils/07_purple.png"),
]
const PENCIL_COLORS: Array[Color] = [
	Color("#ef3f36"), Color("#f28b2d"), Color("#f4d53b"), Color("#53b653"),
	Color("#37c9df"), Color("#397bdc"), Color("#995bd1"),
]
var shapes: Array = []
var shape_index: int = 0
var shape_done: bool = false
var coloring_stage: bool = false
var target_color_index: int = 0
var celebrate_tween: Tween
var sfx_player: AudioStreamPlayer
var voice_player: AudioStreamPlayer
var bg: ColorRect
var card: Panel
var title_tab: Panel
var title_label: Label
var sample_grid: Node2D
var draw_grid: Node2D
var hud: CanvasLayer
var score_label: Label
var pencil_bar: Panel
var pencil_cards: Array[Panel] = []
var pencil_buttons: Array[TextureButton] = []
func _ready() -> void:
	sfx_player = AudioStreamPlayer.new()
	sfx_player.bus = "SFX"
	add_child(sfx_player)
	voice_player = AudioStreamPlayer.new()
	voice_player.bus = "VOICE"
	add_child(voice_player)
	_build_shapes()
	_build_background()
	_build_panels()
	_build_hud()
	GameState.coin_balance_changed.connect(func(balance: int): score_label.text = str(balance))
	get_viewport().size_changed.connect(_layout)
	_layout()
	_load_shape(false)
	_play_intro()
func _closed_edges(n: int) -> Array:
	var e := []
	for i in range(n):
		var j := (i + 1) % n
		e.append([mini(i, j), maxi(i, j)])
	return e
func _shape(name: String, pts: PackedVector2Array) -> Dictionary:
	return {"name": name, "points": pts, "edges": _closed_edges(pts.size())}
func _build_shapes() -> void:
	shapes = [
		_shape("circle", _circle_points()),
		_shape("square", PackedVector2Array([
			Vector2(1, 1), Vector2(5, 1), Vector2(5, 5), Vector2(1, 5)
		])),
		_shape("triangle", PackedVector2Array([
			Vector2(3, 1), Vector2(5, 5), Vector2(1, 5)
		])),
		_shape("diamond", PackedVector2Array([
			Vector2(3, 1), Vector2(5, 3), Vector2(3, 5), Vector2(1, 3)
		])),
		_shape("star", _star_points()),
	]
func _circle_points() -> PackedVector2Array:
	var pts := PackedVector2Array()
	var center := Vector2(3, 3)
	var radius := 2.15
	for i in range(12):
		var angle := deg_to_rad(-90.0 + float(i) * 30.0)
		pts.append(center + Vector2(cos(angle), sin(angle)) * radius)
	return pts
func _star_points() -> PackedVector2Array:
	var pts := PackedVector2Array()
	var center := Vector2(3, 3)
	var r_outer := 2.5
	var r_inner := 1.05
	for i in range(10):
		var ang := deg_to_rad(-90 + i * 36)
		var r: float = r_outer if i % 2 == 0 else r_inner
		pts.append(center + Vector2(cos(ang), sin(ang)) * r)
	return pts
func _build_background() -> void:
	bg = ColorRect.new()
	bg.color = BORDER_COLOR
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bg.z_index = -10
	add_child(bg)
	card = Panel.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = CARD_COLOR
	sb.set_corner_radius_all(40)
	sb.shadow_color = Color(0, 0, 0, 0.18)
	sb.shadow_size = 16
	sb.shadow_offset = Vector2(0, 8)
	card.add_theme_stylebox_override("panel", sb)
	card.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.z_index = -9
	add_child(card)
	title_tab = _make_tab("SQUARE", 40)
func _make_tab(text: String, font_size: int) -> Panel:
	var p := Panel.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = TAB_COLOR
	sb.set_corner_radius_all(16)
	sb.shadow_color = Color(0, 0, 0, 0.12)
	sb.shadow_size = 8
	sb.shadow_offset = Vector2(0, 4)
	p.add_theme_stylebox_override("panel", sb)
	p.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(p)
	var l := Label.new()
	l.text = text
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	l.add_theme_font_size_override("font_size", font_size)
	l.add_theme_color_override("font_color", TAB_TEXT_COLOR)
	l.set_anchors_preset(Control.PRESET_FULL_RECT)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	p.add_child(l)
	title_label = l
	return p
func _build_panels() -> void:
	sample_grid = GridScript.new()
	sample_grid.interactive = false
	add_child(sample_grid)
	draw_grid = GridScript.new()
	draw_grid.interactive = true
	draw_grid.edge_attempt.connect(_on_edge_attempt)
	draw_grid.interaction_started.connect(_on_user_interaction_started)
	draw_grid.coloring_completed.connect(_on_coloring_completed)
	add_child(draw_grid)
func _build_hud() -> void:
	hud = CanvasLayer.new()
	add_child(hud)
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
	pencil_bar = Panel.new()
	pencil_bar.add_theme_stylebox_override("panel", _pencil_bar_style())
	pencil_bar.visible = false
	hud.add_child(pencil_bar)
	for index in range(PENCIL_TEXTURES.size()):
		var pencil_card := Panel.new()
		pencil_card.add_theme_stylebox_override("panel", _pencil_card_style(PENCIL_COLORS[index], false))
		pencil_bar.add_child(pencil_card)
		pencil_cards.append(pencil_card)
		var pencil_button := TextureButton.new()
		pencil_button.texture_normal = PENCIL_TEXTURES[index]
		pencil_button.ignore_texture_size = true
		pencil_button.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
		pencil_button.focus_mode = Control.FOCUS_NONE
		pencil_button.pressed.connect(_on_pencil_pressed.bind(index))
		pencil_card.add_child(pencil_button)
		pencil_buttons.append(pencil_button)
func _layout() -> void:
	var vs := get_viewport_rect().size
	bg.position = Vector2.ZERO
	bg.size = vs
	var pad: float = vs.x * 0.02
	card.position = Vector2(pad, pad)
	card.size = vs - Vector2(pad, pad) * 2.0
	var title_w: float = minf(vs.x * 0.46, 620.0)
	var title_h: float = vs.y * 0.09
	title_tab.size = Vector2(title_w, title_h)
	title_tab.position = Vector2(vs.x * 0.5 - title_w * 0.5, card.position.y + vs.y * 0.02)
	var side_clear: float = maxf(220.0, vs.x * 0.14)
	var bottom_clear: float = maxf(150.0, vs.y * 0.19)
	var top_y: float = title_tab.position.y + title_h + vs.y * 0.03
	var avail_w: float = vs.x - side_clear * 2.0
	var avail_h: float = vs.y - bottom_clear - top_y
	var gap: float = vs.x * 0.03
	var panel_size: float = minf(avail_h, (avail_w - gap) * 0.5)
	panel_size = maxf(panel_size, 120.0)
	var total_w: float = panel_size * 2.0 + gap
	var start_x: float = vs.x * 0.5 - total_w * 0.5
	var grid_y: float = top_y
	var sample_rect := Rect2(Vector2(start_x, grid_y), Vector2(panel_size, panel_size))
	var draw_rect := Rect2(Vector2(start_x + panel_size + gap, grid_y), Vector2(panel_size, panel_size))
	sample_grid.set_layout(sample_rect)
	draw_grid.set_layout(draw_rect)
	var pencil_height := clampf(vs.y * 0.16, 92.0, 138.0)
	var pencil_width := minf(vs.x - side_clear * 2.0 - 24.0, 720.0)
	pencil_bar.position = Vector2(vs.x * 0.5 - pencil_width * 0.5, vs.y - pencil_height - 18.0)
	pencil_bar.size = Vector2(pencil_width, pencil_height)
	var pencil_padding := 12.0
	var pencil_gap := 8.0
	var pencil_card_width := (pencil_width - pencil_padding * 2.0 - pencil_gap * 6.0) / 7.0
	for index in range(pencil_cards.size()):
		var pencil_card := pencil_cards[index]
		pencil_card.position = Vector2(pencil_padding + float(index) * (pencil_card_width + pencil_gap), pencil_padding)
		pencil_card.size = Vector2(pencil_card_width, pencil_height - pencil_padding * 2.0)
		pencil_buttons[index].position = Vector2(6.0, 5.0)
		pencil_buttons[index].size = pencil_card.size - Vector2(12.0, 10.0)
func _load_shape(play_name: bool = true) -> void:
	if celebrate_tween:
		celebrate_tween.kill()
		celebrate_tween = null
	draw_grid.scale = Vector2.ONE
	shape_done = false
	coloring_stage = false
	pencil_bar.visible = false
	var shape: Dictionary = shapes[shape_index]
	sample_grid.set_shape(shape["points"], shape["edges"])
	draw_grid.set_shape(shape["points"], shape["edges"])
	var shape_key := String(shape["name"])
	title_label.text = LanguageService.get_shape_name(shape_key)
	sample_grid.start_demo()
	_update_score()
	if play_name:
		_play_shape_name(shape_key)
func _on_user_interaction_started() -> void:
	sample_grid.stop_demo()
func _update_score() -> void:
	score_label.text = str(GameState.get_coin_balance())
func _on_edge_attempt(from_idx: int, to_idx: int) -> void:
	if shape_done:
		return
	var key := [mini(from_idx, to_idx), maxi(from_idx, to_idx)]
	for e in draw_grid.drawn_edges:
		if e[0] == key[0] and e[1] == key[1]:
			return
	var shape: Dictionary = shapes[shape_index]
	var edges: Array = shape["edges"]
	var is_valid := false
	for e in edges:
		if e[0] == key[0] and e[1] == key[1]:
			is_valid = true
			break
	if is_valid:
		draw_grid.mark_edge_drawn(key[0], key[1])
		_play_sfx(correct_sound)
		if draw_grid.drawn_edges.size() >= edges.size():
			_finish_shape()
	else:
		_play_sfx(wrong_sound)
		SFX.play_retry(get_viewport_rect().size * 0.5)
func _finish_shape() -> void:
	shape_done = true
	SFX.play_praise(get_viewport_rect().size * 0.5, 0.8)
	celebrate_tween = create_tween()
	celebrate_tween.tween_interval(0.55)
	celebrate_tween.tween_callback(_begin_coloring_stage)
func _begin_coloring_stage() -> void:
	coloring_stage = true
	target_color_index = randi_range(0, PENCIL_COLORS.size() - 1)
	var target_color := PENCIL_COLORS[target_color_index]
	sample_grid.set_solid_fill(target_color, true)
	draw_grid.prepare_coloring(target_color)
	pencil_bar.visible = true
	for index in range(pencil_cards.size()):
		pencil_cards[index].add_theme_stylebox_override("panel", _pencil_card_style(PENCIL_COLORS[index], false))
	call_deferred("_play_color_shape", target_color_index, String(shapes[shape_index]["name"]))
func _on_pencil_pressed(index: int) -> void:
	if not coloring_stage:
		return
	if index != target_color_index:
		_play_sfx(wrong_sound)
		SFX.play_retry(get_viewport_rect().size * 0.5)
		var card := pencil_cards[index]
		var start_position := card.position
		var tween := create_tween()
		tween.tween_property(card, "position:x", start_position.x - 7.0, 0.06)
		tween.tween_property(card, "position:x", start_position.x + 7.0, 0.06)
		tween.tween_property(card, "position:x", start_position.x, 0.06)
		return
	_play_sfx(correct_sound)
	draw_grid.enable_coloring()
	for card_index in range(pencil_cards.size()):
		pencil_cards[card_index].add_theme_stylebox_override(
			"panel",
			_pencil_card_style(PENCIL_COLORS[card_index], card_index == target_color_index)
		)
func _on_coloring_completed() -> void:
	if not coloring_stage:
		return
	coloring_stage = false
	pencil_bar.visible = false
	GameState.add_coins(coins_per_shape)
	_play_sfx(coin_sound)
	_update_score()
	SFX.play_praise(get_viewport_rect().size * 0.5, 0.8)
	celebrate_tween = create_tween()
	celebrate_tween.tween_property(draw_grid, "scale", Vector2(1.08, 1.08), 0.22) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	celebrate_tween.tween_property(draw_grid, "scale", Vector2.ONE, 0.22) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	celebrate_tween.tween_interval(0.65)
	celebrate_tween.tween_callback(_advance_shape)
func _advance_shape() -> void:
	shape_index = (shape_index + 1) % shapes.size()
	_load_shape()
func _on_prev_pressed() -> void:
	shape_index = wrapi(shape_index - 1, 0, shapes.size())
	_load_shape()
func _on_next_pressed() -> void:
	shape_index = wrapi(shape_index + 1, 0, shapes.size())
	_load_shape()
func _on_exit_pressed() -> void:
	SFX.transition_to_scene(exit_scene_path)
func _pencil_bar_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(1.0, 0.94, 0.74, 0.98)
	style.border_color = Color("#d49a38")
	style.set_border_width_all(4)
	style.set_corner_radius_all(24)
	style.shadow_color = Color(0.20, 0.10, 0.02, 0.22)
	style.shadow_size = 8
	style.shadow_offset = Vector2(0, 5)
	return style
func _pencil_card_style(color: Color, selected: bool) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = color.lightened(0.72 if selected else 0.84)
	style.border_color = Color("#654019") if selected else color.darkened(0.16)
	style.set_border_width_all(6 if selected else 3)
	style.set_corner_radius_all(18)
	style.shadow_color = Color(0.16, 0.08, 0.02, 0.20)
	style.shadow_size = 5
	style.shadow_offset = Vector2(0, 3)
	return style
func _play_sfx(stream: AudioStream) -> void:
	if stream:
		sfx_player.stream = stream
		sfx_player.play()

func _play_intro() -> void:
	var intro := LanguageService.get_game_voice("shape_trace_intro")
	if intro:
		voice_player.stream = intro
		voice_player.play()
		await voice_player.finished
		if voice_player.stream != intro:
			return
	_play_shape_name(String(shapes[shape_index]["name"]))

func _play_shape_name(shape_key: String) -> void:
	var stream := LanguageService.get_shape_voice(shape_key)
	if stream:
		voice_player.stop()
		voice_player.stream = stream
		voice_player.play()

func _play_color_shape(color_index: int, shape_key: String) -> void:
	var color_stream := LanguageService.get_shape_color_voice(color_index, shape_key)
	var shape_stream := LanguageService.get_shape_voice(shape_key)
	var streams: Array[AudioStream] = []
	if LanguageService.learning_locale in ["pt", "es", "fr"]:
		streams = [shape_stream, color_stream]
	else:
		streams = [color_stream, shape_stream]
	voice_player.stop()
	for stream in streams:
		if stream == null:
			continue
		voice_player.stream = stream
		voice_player.play()
		await voice_player.finished
	if not is_inside_tree() or not coloring_stage:
		return
