extends Node2D
const STAR_TEXTURE: Texture2D = preload("res://education/playtown/assets/ui/star.png")
const CLOCK_TEXTURE: Texture2D = preload("res://education/playtown/assets/ui/clock.png")
const GIRL_MARKER_TEXTURE: Texture2D = preload("res://education/playtown/assets/race/girl_minimap_marker.png")
const BOY_MARKER_TEXTURE: Texture2D = preload("res://education/playtown/assets/race/boy_minimap_marker.png")
const BACKDROP_SCRIPT := preload("res://education/playtown/src/features/race/race_backdrop.gd")
@export var time_limit_sec := 150
@export var player_finish_sec := 100.0
@export var opponent_finish_sec := 150.0
@export var results_scene_path := "res://education/playtown/scenes/screens/game_select_playground.tscn"
@export var player_path: NodePath = NodePath("CanvasLayer/PlayerControl/Control/Player")
@onready var music: AudioStreamPlayer2D = $AudioStreamPlayer2D
var game_timer: Timer
var player: Node
var game_finished := false
var rewarded_coins := 0
var elapsed_time := 0.0
var player_progress := 0.0
var opponent_progress := 0.0
var player_blocked := false
var player_slowed := false
var background_layer: CanvasLayer
var hud_layer: CanvasLayer
var backdrop: Control
var home_button: Button
var score_panel: Panel
var score_icon: TextureRect
var score_label: Label
var timer_panel: Panel
var timer_icon: TextureRect
var timer_label: Label
var map_panel: Panel
var map_title: Label
var map_track_player: Panel
var map_track_opponent: Panel
var map_player_marker: TextureRect
var map_opponent_marker: TextureRect
var map_finish: Label
var left_button: Button
var right_button: Button
var left_arrow: Polygon2D
var right_arrow: Polygon2D
var finish_banner: Panel
var finish_label: Label
var voice_player: AudioStreamPlayer
func _ready() -> void:
	player = get_node_or_null(player_path)
	if player == null:
		return
	_remove_legacy_visuals()
	_build_programmatic_scene()
	_apply_localized_text()
	_setup_voice()
	_connect_player()
	if music:
		music.volume_db = -18.0
		if not music.playing:
			music.play()
	game_timer = Timer.new()
	game_timer.one_shot = true
	game_timer.wait_time = float(time_limit_sec)
	game_timer.timeout.connect(_on_time_over)
	add_child(game_timer)
	game_timer.start()
	get_viewport().size_changed.connect(_layout_for_viewport)
	_layout_for_viewport()
	_update_score(0)
	_update_timer_label()
	call_deferred("_play_intro")
func _process(delta: float) -> void:
	if game_finished:
		return
	elapsed_time += delta
	opponent_progress = minf(1.0, opponent_progress + delta / opponent_finish_sec)
	if not player_blocked:
		var speed_factor := 0.2 if player_slowed else 1.0
		player_progress = minf(1.0, player_progress + delta * speed_factor / player_finish_sec)
	_update_timer_label()
	_update_minimap_positions()
	if player_progress >= 1.0:
		_finish_game("finish")
func _remove_legacy_visuals() -> void:
	for path in [
		"CanvasLayer/BackgroundControl",
		"CanvasLayer/ScoreBoxNewControl",
		"CanvasLayer/TimerBoxControl",
		"CanvasLayer/PanelControl",
		"CanvasLayer/MovementControls",
		"CanvasLayer/ExitButtonControl"
	]:
		var node := get_node_or_null(path)
		if node:
			node.visible = false
			node.queue_free()
func _build_programmatic_scene() -> void:
	background_layer = CanvasLayer.new()
	background_layer.layer = -10
	add_child(background_layer)
	backdrop = BACKDROP_SCRIPT.new()
	background_layer.add_child(backdrop)
	backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	hud_layer = CanvasLayer.new()
	hud_layer.layer = 20
	add_child(hud_layer)
	home_button = GameExitButton.new()
	home_button.pressed.connect(_go_home)
	hud_layer.add_child(home_button)
	score_panel = GameScorePanel.new()
	hud_layer.add_child(score_panel)
	score_icon = (score_panel as GameScorePanel).score_icon
	score_label = (score_panel as GameScorePanel).score_label
	timer_panel = _make_panel(Color(1.0, 0.97, 0.86, 0.96), Color("#d99c36"), 3, 20)
	hud_layer.add_child(timer_panel)
	timer_icon = _make_texture_rect(CLOCK_TEXTURE)
	timer_panel.add_child(timer_icon)
	timer_label = _make_hud_label("00:00", Color("#5e3b1f"))
	timer_panel.add_child(timer_label)
	map_panel = _make_panel(Color(0.98, 0.97, 0.9, 0.96), Color("#268e9f"), 4, 22)
	map_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hud_layer.add_child(map_panel)
	map_title = _make_hud_label("RACE", Color("#176778"))
	map_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	map_panel.add_child(map_title)
	map_track_player = _make_panel(Color("#d9edf1"), Color("#7fc4cf"), 2, 12)
	map_track_player.mouse_filter = Control.MOUSE_FILTER_IGNORE
	map_panel.add_child(map_track_player)
	map_track_opponent = _make_panel(Color("#f0dfc8"), Color("#d6a96c"), 2, 12)
	map_track_opponent.mouse_filter = Control.MOUSE_FILTER_IGNORE
	map_panel.add_child(map_track_opponent)
	var selected_is_boy := GameState.selected_character == "boy"
	map_player_marker = _make_texture_rect(BOY_MARKER_TEXTURE if selected_is_boy else GIRL_MARKER_TEXTURE)
	map_opponent_marker = _make_texture_rect(GIRL_MARKER_TEXTURE if selected_is_boy else BOY_MARKER_TEXTURE)
	map_panel.add_child(map_player_marker)
	map_panel.add_child(map_opponent_marker)
	map_finish = _make_hud_label("FINISH", Color("#5f4424"))
	map_finish.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	map_panel.add_child(map_finish)
	left_button = _make_drive_button()
	left_arrow = _make_drive_arrow(-1.0)
	left_button.add_child(left_arrow)
	left_button.button_down.connect(func(): player.set_input_x(-1.0))
	left_button.button_up.connect(func(): player.set_input_x(0.0))
	hud_layer.add_child(left_button)
	right_button = _make_drive_button()
	right_arrow = _make_drive_arrow(1.0)
	right_button.add_child(right_arrow)
	right_button.button_down.connect(func(): player.set_input_x(1.0))
	right_button.button_up.connect(func(): player.set_input_x(0.0))
	hud_layer.add_child(right_button)
	finish_banner = _make_panel(Color(1.0, 0.96, 0.76, 0.98), Color("#e39a28"), 5, 30)
	finish_banner.visible = false
	hud_layer.add_child(finish_banner)
	finish_label = _make_hud_label("FINISH!", Color("#9b4b20"))
	finish_banner.add_child(finish_label)

func _apply_localized_text() -> void:
	map_title.text = LanguageService.get_ui_text("race")
	map_finish.text = LanguageService.get_ui_text("finish")
	finish_label.text = LanguageService.get_ui_text("race_finished")

func _setup_voice() -> void:
	voice_player = AudioStreamPlayer.new()
	voice_player.bus = "VOICE"
	add_child(voice_player)

func _play_intro() -> void:
	var stream := LanguageService.get_game_voice("race_intro")
	if stream == null or voice_player == null:
		return
	voice_player.stream = stream
	voice_player.play()
func _connect_player() -> void:
	if player.has_signal("coin_collected"):
		player.coin_collected.connect(_update_score)
	if player.has_signal("obstacle_state_changed"):
		player.obstacle_state_changed.connect(_on_obstacle_state_changed)
	if player.has_signal("puddle_state_changed"):
		player.puddle_state_changed.connect(_on_puddle_state_changed)
func _on_obstacle_state_changed(value: bool) -> void:
	player_blocked = value
	if backdrop and backdrop.has_method("set_road_paused"):
		backdrop.set_road_paused(value)
func _on_puddle_state_changed(value: bool) -> void:
	player_slowed = value
	if backdrop and backdrop.has_method("set_road_speed_multiplier"):
		backdrop.set_road_speed_multiplier(0.2 if value else 1.0)
func _make_panel(fill: Color, border: Color, border_width: int, radius: int) -> Panel:
	var panel := Panel.new()
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.border_color = border
	style.set_border_width_all(border_width)
	style.set_corner_radius_all(radius)
	style.shadow_color = Color(0.18, 0.14, 0.08, 0.18)
	style.shadow_size = 7
	style.shadow_offset = Vector2(0.0, 4.0)
	panel.add_theme_stylebox_override("panel", style)
	return panel
func _make_texture_rect(texture: Texture2D) -> TextureRect:
	var rect := TextureRect.new()
	rect.texture = texture
	rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return rect
func _make_hud_label(text_value: String, color: Color) -> Label:
	var label := Label.new()
	label.text = text_value
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_color_override("font_color", color)
	label.add_theme_color_override("font_outline_color", Color.WHITE)
	label.add_theme_constant_override("outline_size", 3)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return label
func _make_drive_button() -> Button:
	var button := Button.new()
	button.text = ""
	button.focus_mode = Control.FOCUS_NONE
	button.keep_pressed_outside = true
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	button.add_theme_color_override("font_color", Color.WHITE)
	button.add_theme_color_override("font_hover_color", Color.WHITE)
	button.add_theme_color_override("font_pressed_color", Color.WHITE)
	button.add_theme_stylebox_override("normal", _button_style(Color(0.08, 0.55, 0.68, 0.88), Color.WHITE))
	button.add_theme_stylebox_override("hover", _button_style(Color(0.1, 0.63, 0.75, 0.94), Color.WHITE))
	button.add_theme_stylebox_override("pressed", _button_style(Color(0.05, 0.43, 0.55, 0.96), Color("#d7f8ff")))
	return button

func _make_drive_arrow(direction: float) -> Polygon2D:
	var arrow := Polygon2D.new()
	arrow.polygon = PackedVector2Array([
		Vector2(-0.58 * direction, -0.72),
		Vector2(0.58 * direction, 0.0),
		Vector2(-0.58 * direction, 0.72),
		Vector2(-0.24 * direction, 0.0)
	])
	arrow.color = Color.WHITE
	return arrow
func _button_style(fill: Color, border: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.border_color = border
	style.set_border_width_all(4)
	style.set_corner_radius_all(38)
	style.shadow_color = Color(0.0, 0.15, 0.2, 0.24)
	style.shadow_size = 8
	style.shadow_offset = Vector2(0.0, 5.0)
	return style
func _layout_for_viewport() -> void:
	var view := get_viewport_rect().size
	if view.x <= 1.0 or view.y <= 1.0:
		return
	var short_side := minf(view.x, view.y)
	var edge := clampf(short_side * 0.025, 14.0, 30.0)
	var safe := _safe_area_insets(view)
	var left_edge := edge + safe.x
	var top_edge := edge + safe.y
	var right_edge := edge + safe.z
	var bottom_edge := edge + safe.w
	var button_size := clampf(short_side * 0.135, 82.0, 118.0)
	var top_height := clampf(short_side * 0.105, 66.0, 92.0)
	var info_width := clampf(view.x * 0.13, 160.0, 225.0)
	home_button.position = Vector2(left_edge, top_edge)
	home_button.size = Vector2.ONE * button_size
	score_panel.position = Vector2(view.x - right_edge - info_width, top_edge)
	score_panel.size = Vector2(info_width, top_height)
	timer_panel.position = Vector2(score_panel.position.x - edge * 0.6 - info_width, top_edge)
	timer_panel.size = Vector2(info_width, top_height)
	var icon_size := top_height * 0.72
	score_icon.position = Vector2(top_height * 0.08, top_height * 0.14)
	score_icon.size = Vector2.ONE * icon_size
	score_label.position = Vector2(top_height * 0.82, 0.0)
	score_label.size = Vector2(info_width - top_height * 0.9, top_height)
	score_label.add_theme_font_size_override("font_size", int(top_height * 0.46))
	timer_icon.position = Vector2(top_height * 0.08, top_height * 0.14)
	timer_icon.size = Vector2.ONE * icon_size
	timer_label.position = Vector2(top_height * 0.78, 0.0)
	timer_label.size = Vector2(info_width - top_height * 0.84, top_height)
	timer_label.add_theme_font_size_override("font_size", int(top_height * 0.38))
	var map_width := clampf(view.x * 0.34, 380.0, 570.0)
	var map_height := clampf(short_side * 0.16, 110.0, 142.0)
	var available_left := home_button.position.x + home_button.size.x + edge
	var available_right := timer_panel.position.x - edge
	var map_x := (available_left + available_right - map_width) * 0.5
	map_x = clampf(map_x, left_edge, view.x - right_edge - map_width)
	map_panel.position = Vector2(map_x, top_edge)
	map_panel.size = Vector2(map_width, map_height)
	map_title.position = Vector2(map_width * 0.035, 0.0)
	map_title.size = Vector2(map_width * 0.18, map_height)
	map_title.add_theme_font_size_override("font_size", int(map_height * 0.19))
	var track_x := map_width * 0.2
	var track_width := map_width * 0.68
	var track_height := map_height * 0.22
	map_track_player.position = Vector2(track_x, map_height * 0.2)
	map_track_player.size = Vector2(track_width, track_height)
	map_track_opponent.position = Vector2(track_x, map_height * 0.59)
	map_track_opponent.size = Vector2(track_width, track_height)
	map_finish.position = Vector2(map_width * 0.87, 0.0)
	map_finish.size = Vector2(map_width * 0.12, map_height)
	map_finish.add_theme_font_size_override("font_size", int(map_height * 0.12))
	var drive_size := clampf(short_side * 0.18, 112.0, 158.0)
	left_button.position = Vector2(left_edge, view.y - bottom_edge - drive_size)
	left_button.size = Vector2.ONE * drive_size
	right_button.position = Vector2(view.x - right_edge - drive_size, view.y - bottom_edge - drive_size)
	right_button.size = Vector2.ONE * drive_size
	var arrow_scale := drive_size * 0.31
	left_arrow.position = Vector2.ONE * drive_size * 0.5
	left_arrow.scale = Vector2.ONE * arrow_scale
	right_arrow.position = Vector2.ONE * drive_size * 0.5
	right_arrow.scale = Vector2.ONE * arrow_scale
	var banner_size := Vector2(clampf(view.x * 0.34, 400.0, 560.0), clampf(short_side * 0.17, 110.0, 150.0))
	finish_banner.position = (view - banner_size) * 0.5
	finish_banner.size = banner_size
	finish_label.position = Vector2.ZERO
	finish_label.size = banner_size
	finish_label.add_theme_font_size_override("font_size", int(banner_size.y * 0.46))
	_update_minimap_positions()

func _safe_area_insets(view: Vector2) -> Vector4:
	if OS.get_name() not in ["iOS", "Android"]:
		return Vector4.ZERO
	var window_size := Vector2(DisplayServer.window_get_size())
	var safe_rect := DisplayServer.get_display_safe_area()
	if window_size.x <= 0.0 or window_size.y <= 0.0 or safe_rect.size.x <= 0 or safe_rect.size.y <= 0:
		return Vector4.ZERO
	var scale_to_view := view / window_size
	var right_px := maxf(0.0, window_size.x - float(safe_rect.position.x + safe_rect.size.x))
	var bottom_px := maxf(0.0, window_size.y - float(safe_rect.position.y + safe_rect.size.y))
	return Vector4(
		float(safe_rect.position.x) * scale_to_view.x,
		float(safe_rect.position.y) * scale_to_view.y,
		right_px * scale_to_view.x,
		bottom_px * scale_to_view.y
	)
func _update_minimap_positions() -> void:
	if map_panel == null:
		return
	var marker_size := clampf(map_panel.size.y * 0.34, 36.0, 50.0)
	var start_x := map_track_player.position.x - marker_size * 0.28
	var travel := map_track_player.size.x - marker_size * 0.44
	map_player_marker.size = Vector2(marker_size, marker_size)
	map_opponent_marker.size = Vector2(marker_size, marker_size)
	map_player_marker.position = Vector2(
		start_x + travel * player_progress,
		map_track_player.position.y + (map_track_player.size.y - marker_size) * 0.5
	)
	map_opponent_marker.position = Vector2(
		start_x + travel * opponent_progress,
		map_track_opponent.position.y + (map_track_opponent.size.y - marker_size) * 0.5
	)
func _update_score(total: int) -> void:
	if score_label:
		score_label.text = str(GameState.get_coin_balance())
	var reward := maxi(0, total - rewarded_coins)
	if reward > 0:
		rewarded_coins = total
		GameState.last_score = total
		GameState.add_coins(reward)
func _update_timer_label() -> void:
	if timer_label == null:
		return
	var total_seconds := int(elapsed_time)
	timer_label.text = "%02d:%02d" % [total_seconds / 60, total_seconds % 60]
func _on_time_over() -> void:
	_finish_game("time")
func _finish_game(reason: String) -> void:
	if game_finished:
		return
	game_finished = true
	player.set_input_x(0.0)
	if game_timer:
		game_timer.stop()
	finish_label.text = LanguageService.get_ui_text("race_finished" if reason == "finish" else "time_up")
	finish_banner.visible = true
	_fade_out_music()
	if reason == "finish":
		SFX.play_praise(get_viewport_rect().size * 0.5, 0.25)
	else:
		SFX.play_retry(get_viewport_rect().size * 0.5, 0.25)
	var score := _get_player_coins()
	GameState.last_score = score
	await get_tree().create_timer(0.9).timeout
	SFX.transition_to_scene(results_scene_path)
func _fade_out_music() -> void:
	if music == null:
		return
	var tween := create_tween()
	tween.tween_property(music, "volume_db", -40.0, 0.35)
	tween.tween_callback(music.stop)
func _get_player_coins() -> int:
	if player != null and "coins" in player:
		return int(player.coins)
	if player != null and player.has_method("get_coins"):
		return int(player.get_coins())
	return 0
func _go_home() -> void:
	if game_finished:
		return
	game_finished = true
	if game_timer:
		game_timer.stop()
	_fade_out_music()
	SFX.transition_to_scene(results_scene_path)
