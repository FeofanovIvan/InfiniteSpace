extends Node2D

const BOARD_SCRIPT := preload("res://education/playtown/src/features/path_builder/path_builder_board.gd")
const TOOL_SCRIPT := preload("res://education/playtown/src/features/path_builder/path_builder_tool.gd")
const GAME_FONT: Font = preload("res://education/playtown/assets/ui/fonts/RobotoCondensed-Variable.ttf")
const BACK_ARROW_TEXTURE: Texture2D = preload("res://education/playtown/assets/ui/back_arrow.png")
const PET_FRAMES: SpriteFrames = preload("res://education/playtown/assets/pet/pet_frames.tres")
const HOUSE_TEXTURE: Texture2D = preload("res://education/playtown/assets/pet_home/item_house.png")
const BACK_SCENE := "res://education/playtown/scenes/screens/game_select_playground.tscn"

var background: TextureRect
var board_frame: Panel
var board: Control
var side_panel: Panel
var tools_label: Label
var bridge_tools: Array[Control] = []
var bridge_assignments := [-1, -1]
var stop_tool: Control
var back_button: Button
var back_icon: TextureRect
var start_button: Button
var retry_button: Button
var score_panel: Panel
var score_label: Label
var dog: AnimatedSprite2D
var house: TextureRect
var result_overlay: ColorRect
var result_panel: Panel
var result_title: Label
var result_text: Label
var again_button: Button
var result_back_button: Button
var correct_player: AudioStreamPlayer
var wrong_player: AudioStreamPlayer
var voice_player: AudioStreamPlayer
var running := false
var rewarded := false
var round_score := 0

func _ready() -> void:
	randomize()
	_build_ui()
	get_viewport().size_changed.connect(_layout)
	_layout()
	_new_round()
	call_deferred("_play_intro")

func _build_ui() -> void:
	background = TextureRect.new()
	var gradient := Gradient.new()
	gradient.colors = PackedColorArray([Color("#bcecff"), Color("#e9f7cf")])
	var texture := GradientTexture2D.new()
	texture.gradient = gradient
	texture.fill_from = Vector2(0.5, 0.0)
	texture.fill_to = Vector2(0.5, 1.0)
	background.texture = texture
	background.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	background.z_index = -10
	add_child(background)

	board_frame = Panel.new()
	board_frame.add_theme_stylebox_override("panel", _panel_style(Color("#fff3ca"), Color("#d79835"), 7, 28))
	add_child(board_frame)
	board = Control.new()
	board.set_script(BOARD_SCRIPT)
	board.clip_contents = true
	board_frame.add_child(board)
	board.layout_changed.connect(_position_characters)
	side_panel = Panel.new()
	side_panel.add_theme_stylebox_override("panel", _panel_style(Color("#fff4d1"), Color("#d89b35"), 5, 26))
	add_child(side_panel)

	tools_label = Label.new()
	tools_label.text = LanguageService.get_ui_text("drag")
	tools_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	tools_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	tools_label.add_theme_font_override("font", GAME_FONT)
	tools_label.add_theme_color_override("font_color", Color("#6b4a27"))
	tools_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(tools_label)
	for index in range(2):
		var bridge_tool := Control.new()
		bridge_tool.set_script(TOOL_SCRIPT)
		bridge_tool.tool_type = "bridge"
		bridge_tool.tool_index = index
		bridge_tool.z_index = 12
		bridge_tool.drag_started.connect(_on_tool_drag_started)
		bridge_tool.drag_finished.connect(_on_tool_drag_finished)
		add_child(bridge_tool)
		bridge_tools.append(bridge_tool)
	stop_tool = Control.new()
	stop_tool.set_script(TOOL_SCRIPT)
	stop_tool.tool_type = "stop"
	stop_tool.tool_index = -1
	stop_tool.z_index = 12
	stop_tool.drag_started.connect(_on_tool_drag_started)
	stop_tool.drag_finished.connect(_on_tool_drag_finished)
	add_child(stop_tool)

	back_button = GameExitButton.new()
	back_button.pressed.connect(func() -> void: SFX.transition_to_scene(BACK_SCENE))
	add_child(back_button)
	back_icon = TextureRect.new()
	back_icon.texture = BACK_ARROW_TEXTURE
	back_icon.flip_h = true
	back_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	back_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	back_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	back_icon.visible = false
	back_button.add_child(back_icon)

	start_button = _make_button(LanguageService.get_ui_text("start"), Color("#4daf57"))
	start_button.add_theme_stylebox_override("normal", _round_button_style(Color("#58c861")))
	start_button.add_theme_stylebox_override("hover", _round_button_style(Color("#68d471")))
	start_button.add_theme_stylebox_override("pressed", _round_button_style(Color("#3eaa49")))
	start_button.add_theme_stylebox_override("disabled", _round_button_style(Color("#85aa87")))
	start_button.pressed.connect(_start_run)
	add_child(start_button)
	retry_button = _make_button(LanguageService.get_ui_text("path_try_again"), Color("#e99b35"))
	retry_button.pressed.connect(_new_round)
	retry_button.visible = false
	add_child(retry_button)
	score_panel = GameScorePanel.new()
	score_label = (score_panel as GameScorePanel).score_label
	add_child(score_panel)

	house = TextureRect.new()
	house.texture = HOUSE_TEXTURE
	house.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	house.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	house.mouse_filter = Control.MOUSE_FILTER_IGNORE
	house.z_index = 4
	add_child(house)
	dog = AnimatedSprite2D.new()
	dog.sprite_frames = PET_FRAMES
	dog.animation = &"walk_right"
	dog.z_index = 30
	add_child(dog)

	correct_player = AudioStreamPlayer.new()
	correct_player.stream = preload("res://education/playtown/audio/sfx/correct.ogg")
	correct_player.bus = "SFX"
	add_child(correct_player)
	wrong_player = AudioStreamPlayer.new()
	wrong_player.stream = preload("res://education/playtown/audio/sfx/wrong.ogg")
	wrong_player.bus = "SFX"
	add_child(wrong_player)
	voice_player = AudioStreamPlayer.new()
	voice_player.bus = "VOICE"
	add_child(voice_player)
	_build_result_overlay()

func _play_intro() -> void:
	var stream := LanguageService.get_game_voice("path_builder_intro")
	if stream == null:
		return
	voice_player.stream = stream
	voice_player.play()

func _build_result_overlay() -> void:
	result_overlay = ColorRect.new()
	result_overlay.color = Color(0.04, 0.10, 0.12, 0.62)
	result_overlay.z_index = 20
	result_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(result_overlay)
	result_panel = Panel.new()
	result_panel.add_theme_stylebox_override("panel", _panel_style(Color("#fff7dc"), Color("#e19a2c"), 7, 30))
	result_overlay.add_child(result_panel)
	result_title = Label.new()
	result_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	result_title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	result_title.add_theme_font_override("font", GAME_FONT)
	result_title.add_theme_color_override("font_color", Color("#5d3b20"))
	result_panel.add_child(result_title)
	result_text = Label.new()
	result_text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	result_text.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	result_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	result_text.add_theme_font_override("font", GAME_FONT)
	result_text.add_theme_color_override("font_color", Color("#476238"))
	result_panel.add_child(result_text)
	again_button = _make_button(LanguageService.get_ui_text("path_try_again"), Color("#4daf57"))
	again_button.pressed.connect(_new_round)
	result_panel.add_child(again_button)
	result_back_button = _make_button(LanguageService.get_ui_text("back_to_games"), Color("#c2914b"))
	result_back_button.pressed.connect(func() -> void: SFX.transition_to_scene(BACK_SCENE))
	result_panel.add_child(result_back_button)
	result_overlay.hide()

func _layout() -> void:
	var viewport_size := get_viewport_rect().size
	var scale_factor: float = minf(viewport_size.x / 1536.0, viewport_size.y / 768.0)
	var safe := _safe_area_insets(viewport_size)
	var short_side := minf(viewport_size.x, viewport_size.y)
	var edge: float = clampf(short_side * 0.025, 10.0, 24.0)
	var gap := clampf(short_side * 0.018, 8.0, 18.0)
	var content_top := safe.y + edge
	var content_bottom := viewport_size.y - safe.w - edge
	var panel_height := content_bottom - content_top
	var side_width := clampf(short_side * 0.19, 112.0, 168.0)
	var side_x := viewport_size.x - safe.z - edge - side_width
	background.position = Vector2.ZERO
	background.size = viewport_size
	side_panel.position = Vector2(side_x, content_top)
	side_panel.size = Vector2(side_width, panel_height)
	var inner_x := side_x + side_width * 0.12
	var inner_width := side_width * 0.76
	var control_side := minf(inner_width, panel_height * 0.145)
	var vertical_gap := maxf(4.0, panel_height * 0.012)
	start_button.position = Vector2(side_x + (side_width - control_side) * 0.5, content_top + side_width * 0.10)
	start_button.size = Vector2.ONE * control_side
	start_button.add_theme_font_size_override("font_size", maxi(13, int(control_side * 0.24)))
	var bridge_home := Vector2(inner_x, start_button.position.y + control_side + vertical_gap)
	for index in range(bridge_tools.size()):
		var bridge_tool: Control = bridge_tools[index]
		bridge_tool.size = Vector2(inner_width, control_side * 0.62)
		bridge_tool.set_home(bridge_home)
	stop_tool.size = Vector2.ONE * control_side * 0.76
	stop_tool.set_home(Vector2(side_x + (side_width - stop_tool.size.x) * 0.5, bridge_home.y + control_side * 0.62 + vertical_gap))
	tools_label.position = Vector2(inner_x, stop_tool.home_position.y + stop_tool.size.y + vertical_gap * 0.25)
	tools_label.size = Vector2(inner_width, maxf(22.0, panel_height * 0.055))
	tools_label.add_theme_font_size_override("font_size", maxi(10, int(minf(18.0, side_width * 0.12))))
	tools_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var exit_side := control_side * 0.84
	back_button.position = Vector2(side_x + (side_width - exit_side) * 0.5, content_bottom - exit_side - side_width * 0.10)
	back_button.size = Vector2.ONE * exit_side
	back_icon.position = Vector2.ONE * exit_side * 0.14
	back_icon.size = Vector2.ONE * exit_side * 0.72
	var score_height := clampf(panel_height * 0.105, 46.0, 68.0)
	score_panel.position = Vector2(inner_x, back_button.position.y - score_height - vertical_gap * 1.3)
	score_panel.size = Vector2(inner_width, score_height)
	board_frame.position = Vector2(safe.x + edge, content_top)
	board_frame.size = Vector2(side_x - gap - board_frame.position.x, panel_height)
	var frame_inset: float = maxf(8.0, 12.0 * scale_factor)
	board.position = Vector2.ONE * frame_inset
	board.size = board_frame.size - Vector2.ONE * frame_inset * 2.0
	_position_characters()
	_snap_placed_bridge_tools()
	_layout_result(viewport_size, scale_factor)

func _position_characters() -> void:
	if not is_instance_valid(board) or board.nodes.is_empty():
		return
	var dog_center: Vector2 = board_frame.position + board.position + board.get_node_position(board.start_node)
	var house_center: Vector2 = board_frame.position + board.position + board.get_node_position(board.goal_node)
	var dog_height: float = board.size.y * 0.145
	dog.scale = Vector2.ONE * (dog_height / 224.0)
	if not running:
		dog.position = dog_center + _dog_road_offset()
	var house_size := Vector2(board.size.y * 0.19, board.size.y * 0.17)
	house.size = house_size
	house.position = house_center - Vector2(house_size.x * 0.52, house_size.y * 0.76)

func _dog_road_offset() -> Vector2:
	return Vector2(0.0, -board.size.y * 0.052)

func _layout_result(viewport_size: Vector2, scale_factor: float) -> void:
	result_overlay.position = Vector2.ZERO
	result_overlay.size = viewport_size
	var panel_size := Vector2(minf(viewport_size.x * 0.66, 780.0 * scale_factor), minf(viewport_size.y * 0.62, 450.0 * scale_factor))
	result_panel.position = (viewport_size - panel_size) * 0.5
	result_panel.size = panel_size
	result_title.position = Vector2(panel_size.x * 0.07, panel_size.y * 0.08)
	result_title.size = Vector2(panel_size.x * 0.86, panel_size.y * 0.20)
	result_title.add_theme_font_size_override("font_size", maxi(24, int(43.0 * scale_factor)))
	result_text.position = Vector2(panel_size.x * 0.09, panel_size.y * 0.29)
	result_text.size = Vector2(panel_size.x * 0.82, panel_size.y * 0.22)
	result_text.add_theme_font_size_override("font_size", maxi(18, int(28.0 * scale_factor)))
	again_button.position = Vector2(panel_size.x * 0.12, panel_size.y * 0.58)
	again_button.size = Vector2(panel_size.x * 0.76, panel_size.y * 0.14)
	result_back_button.position = Vector2(panel_size.x * 0.12, panel_size.y * 0.76)
	result_back_button.size = Vector2(panel_size.x * 0.76, panel_size.y * 0.14)
	again_button.add_theme_font_size_override("font_size", maxi(17, int(27.0 * scale_factor)))
	result_back_button.add_theme_font_size_override("font_size", maxi(17, int(27.0 * scale_factor)))

func _new_round() -> void:
	if running:
		return
	result_overlay.hide()
	rewarded = false
	round_score = 0
	score_label.text = str(GameState.get_coin_balance())
	board.interactive = true
	board.configure(randi_range(0, 3), randi_range(0, 3))
	bridge_assignments = [-1, -1]
	for bridge_tool in bridge_tools:
		bridge_tool.enabled = true
		bridge_tool.return_home()
	stop_tool.enabled = true
	stop_tool.return_home()
	dog.stop()
	dog.animation = &"walk_right"
	_position_characters()
	start_button.disabled = false
	retry_button.disabled = false

func _start_run() -> void:
	if running:
		return
	running = true
	board.interactive = false
	for bridge_tool in bridge_tools:
		bridge_tool.enabled = false
	stop_tool.enabled = false
	start_button.disabled = true
	retry_button.disabled = true
	var result: Dictionary = board.simulate_route()
	var route: Array = result["route"]
	var crossed_rivers: Dictionary = {}
	for index in range(1, route.size()):
		var from_node: String = route[index - 1]
		var to_node: String = route[index]
		var from_position: Vector2 = board.get_node_position(route[index - 1])
		var to_position: Vector2 = board.get_node_position(route[index])
		_set_walk_animation(to_position - from_position)
		dog.play()
		var destination: Vector2 = board_frame.position + board.position + to_position + _dog_road_offset()
		var duration: float = clampf(from_position.distance_to(to_position) / maxf(240.0, board.size.x * 0.28), 0.22, 0.58)
		var movement := create_tween()
		movement.tween_property(dog, "position", destination, duration).set_trans(Tween.TRANS_LINEAR)
		await movement.finished
		var crossed_river := _bridge_crossing_index(from_node, to_node)
		if crossed_river >= 0 and not crossed_rivers.has(crossed_river):
			crossed_rivers[crossed_river] = true
			_award_points(5)
	dog.stop()
	running = false
	if bool(result["won"]):
		correct_player.play()
		SFX.play_praise(get_viewport_rect().size * 0.5, 0.4)
		if not rewarded:
			_award_points(10)
			rewarded = true
		_show_result(true)
	else:
		wrong_player.play()
		SFX.play_retry(get_viewport_rect().size * 0.5)
		_show_result(false)

func _set_walk_animation(delta: Vector2) -> void:
	if absf(delta.x) >= absf(delta.y):
		dog.animation = &"walk_left" if delta.x < 0.0 else &"walk_right"
	else:
		dog.animation = &"walk_up" if delta.y < 0.0 else &"walk_down"

func _bridge_crossing_index(from_node: String, to_node: String) -> int:
	if not from_node.contains(":") or not to_node.contains(":"):
		return -1
	var from_column := int(from_node.get_slice(":", 0))
	var to_column := int(to_node.get_slice(":", 0))
	var low := mini(from_column, to_column)
	var high := maxi(from_column, to_column)
	if low == 2 and high == 3:
		return 0
	if low == 5 and high == 6:
		return 1
	return -1

func _award_points(amount: int) -> void:
	round_score += amount
	GameState.last_score = round_score
	GameState.add_coins(amount)

func _on_tool_drag_started(tool: Control) -> void:
	if tool.tool_type == "bridge":
		var assigned_river: int = bridge_assignments[int(tool.tool_index)]
		if assigned_river >= 0:
			board.clear_bridge(assigned_river)
		bridge_assignments[int(tool.tool_index)] = -1
		tool.placed = false

func _on_tool_drag_finished(tool: Control, drop_position: Vector2) -> void:
	if tool.tool_type == "bridge":
		var placement: Dictionary = board.place_bridge_any_from_global(drop_position)
		if not placement.is_empty():
			var river: int = placement["river"]
			for other_index in range(bridge_assignments.size()):
				if other_index != int(tool.tool_index) and bridge_assignments[other_index] == river:
					bridge_assignments[other_index] = -1
					bridge_tools[other_index].return_home()
			bridge_assignments[int(tool.tool_index)] = river
			tool.placed = true
			_snap_bridge_tool(tool, river)
		else:
			tool.return_home()
	else:
		board.place_stop_from_global(drop_position)
		tool.return_home()

func _snap_placed_bridge_tools() -> void:
	if not is_instance_valid(board):
		return
	for river in range(bridge_tools.size()):
		var tool: Control = bridge_tools[river]
		var assigned_river: int = bridge_assignments[river]
		if tool.placed and assigned_river >= 0 and board.bridge_rows[assigned_river] >= 0:
			_snap_bridge_tool(tool, assigned_river)

func _snap_bridge_tool(tool: Control, river: int) -> void:
	var center: Vector2 = board.get_bridge_global_center(river)
	if center == Vector2.ZERO:
		tool.return_home()
		return
	tool.z_index = 12
	var destination := center - tool.size * 0.5
	var tween := create_tween()
	tween.tween_property(tool, "global_position", destination, 0.18).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

func _show_result(won: bool) -> void:
	if won:
		result_title.text = LanguageService.get_ui_text("path_success_title")
		result_text.text = LanguageService.get_ui_text("path_success_body")
	else:
		result_title.text = LanguageService.get_ui_text("path_fail_title")
		result_text.text = LanguageService.get_ui_text("path_fail_body")
	result_overlay.show()

func _make_button(text: String, color: Color) -> Button:
	var button := Button.new()
	button.text = text
	button.focus_mode = Control.FOCUS_NONE
	button.add_theme_font_override("font", GAME_FONT)
	button.add_theme_color_override("font_color", Color.WHITE)
	button.add_theme_color_override("font_hover_color", Color.WHITE)
	button.add_theme_color_override("font_pressed_color", Color.WHITE)
	button.add_theme_color_override("font_disabled_color", Color(1, 1, 1, 0.62))
	button.add_theme_stylebox_override("normal", _panel_style(color, color.darkened(0.27), 4, 18))
	button.add_theme_stylebox_override("hover", _panel_style(color.lightened(0.08), color.darkened(0.27), 4, 18))
	button.add_theme_stylebox_override("pressed", _panel_style(color.darkened(0.12), color.darkened(0.30), 4, 18))
	button.add_theme_stylebox_override("disabled", _panel_style(color.darkened(0.30), color.darkened(0.38), 4, 18))
	return button

func _panel_style(fill: Color, border: Color, border_width: int, radius: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.border_color = border
	style.set_border_width_all(border_width)
	style.set_corner_radius_all(radius)
	style.shadow_color = Color(0, 0, 0, 0.22)
	style.shadow_size = 7
	style.shadow_offset = Vector2(0, 4)
	return style

func _round_button_style(fill: Color) -> StyleBoxFlat:
	var style := _panel_style(fill, fill.darkened(0.30), 5, 999)
	style.content_margin_left = 10.0
	style.content_margin_right = 10.0
	style.content_margin_top = 10.0
	style.content_margin_bottom = 10.0
	return style

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
