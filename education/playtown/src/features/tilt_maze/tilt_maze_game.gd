extends Node2D

const BOARD_SCRIPT = preload("res://education/playtown/src/features/tilt_maze/programmatic_maze_board.gd")
const CORRECT_SOUND: AudioStream = preload("res://education/playtown/audio/sfx/correct.ogg")
const COIN_SOUND: AudioStream = preload("res://education/playtown/audio/sfx/coin.ogg")
const START_POSITION := Vector2(0.2313, 0.1595)
const BALL_RADIUS_FACTOR := 0.014
const BALL_VISUAL_RADIUS_FACTOR := 0.023
const GOAL_RADIUS_FACTOR := 0.070
const SENSOR_GRAVITY := 9.81
const HORIZONTAL_SENSOR_DEADZONE := 0.015
const VERTICAL_SENSOR_DEADZONE := 0.045
const HORIZONTAL_SENSOR_SENSITIVITY := 3.6
const VERTICAL_SENSOR_SENSITIVITY := 1.8
const ACCELERATION := 1280.0
const MAX_SPEED := 760.0
const FRICTION := 1.45
const BOUNCE := 0.24

@export var back_scene_path: String = "res://education/playtown/scenes/screens/game_select_playground.tscn"

var background: ColorRect
var board: Node2D
var back_button: Button
var ball_root: Node2D
var shadow_shape: Polygon2D
var ball_shape: Polygon2D
var highlight_shape: Polygon2D
var win_overlay: Control
var win_panel: Panel
var win_label: Label
var again_button: Button
var exit_button: Button
var sfx: AudioStreamPlayer
var voice_player: AudioStreamPlayer
var board_rect := Rect2()
var source_size := Vector2(1000.0, 1000.0)
var ball_position := Vector2.ZERO
var ball_velocity := Vector2.ZERO
var ball_radius: float = 28.0
var touch_active: bool = false
var touch_target := Vector2.ZERO
var completed: bool = false

func _ready() -> void:
	ball_radius = source_size.x * BALL_RADIUS_FACTOR
	_build_ui()
	_apply_localized_text()
	_reset_game()
	get_viewport().size_changed.connect(_layout)
	_layout()
	call_deferred("_play_intro")

func _input(event: InputEvent) -> void:
	if completed:
		return
	if event is InputEventScreenTouch:
		if event.pressed and board_rect.has_point(event.position):
			touch_active = true
			touch_target = _screen_to_board(event.position)
			get_viewport().set_input_as_handled()
		elif not event.pressed:
			touch_active = false
	elif event is InputEventScreenDrag and touch_active:
		touch_target = _screen_to_board(event.position)
		get_viewport().set_input_as_handled()
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed and board_rect.has_point(event.position):
			touch_active = true
			touch_target = _screen_to_board(event.position)
		elif not event.pressed:
			touch_active = false
	elif event is InputEventMouseMotion and touch_active:
		touch_target = _screen_to_board(event.position)

func _physics_process(delta: float) -> void:
	if completed:
		return
	var direction := _read_direction()
	ball_velocity += direction * ACCELERATION * delta
	ball_velocity *= exp(-FRICTION * delta)
	if ball_velocity.length() > MAX_SPEED:
		ball_velocity = ball_velocity.normalized() * MAX_SPEED
	_move_ball(delta)
	_update_ball_visual()
	var goal := source_size * 0.5
	if ball_position.distance_to(goal) <= source_size.x * GOAL_RADIUS_FACTOR:
		_complete_game()

func _build_ui() -> void:
	background = ColorRect.new()
	background.color = Color(0.72, 0.88, 0.98)
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	background.z_index = -10
	add_child(background)
	board = BOARD_SCRIPT.new()
	add_child(board)
	back_button = GameExitButton.new()
	back_button.pressed.connect(_go_back)
	add_child(back_button)
	ball_root = Node2D.new()
	ball_root.z_index = 20
	add_child(ball_root)
	shadow_shape = Polygon2D.new()
	shadow_shape.polygon = _circle_polygon(1.04, 36)
	shadow_shape.color = Color(0.18, 0.08, 0.02, 0.30)
	shadow_shape.position = Vector2(0.12, 0.18)
	ball_root.add_child(shadow_shape)
	ball_shape = Polygon2D.new()
	ball_shape.polygon = _circle_polygon(1.0, 36)
	ball_shape.color = Color(0.92, 0.08, 0.08)
	ball_root.add_child(ball_shape)
	highlight_shape = Polygon2D.new()
	highlight_shape.polygon = _circle_polygon(0.24, 24)
	highlight_shape.color = Color(1.0, 0.93, 0.88, 0.95)
	highlight_shape.position = Vector2(-0.30, -0.33)
	ball_root.add_child(highlight_shape)
	sfx = AudioStreamPlayer.new()
	sfx.bus = "SFX"
	add_child(sfx)
	voice_player = AudioStreamPlayer.new()
	voice_player.bus = "VOICE"
	add_child(voice_player)
	_build_win_overlay()

func _build_win_overlay() -> void:
	win_overlay = Control.new()
	win_overlay.visible = false
	win_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	win_overlay.z_index = 50
	add_child(win_overlay)
	var dim := ColorRect.new()
	dim.color = Color(0.05, 0.16, 0.05, 0.42)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	win_overlay.add_child(dim)
	win_panel = Panel.new()
	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = Color(1.0, 0.96, 0.78)
	panel_style.border_color = Color(0.94, 0.65, 0.12)
	panel_style.set_border_width_all(7)
	panel_style.set_corner_radius_all(34)
	panel_style.shadow_color = Color(0, 0, 0, 0.28)
	panel_style.shadow_size = 14
	win_panel.add_theme_stylebox_override("panel", panel_style)
	win_overlay.add_child(win_panel)
	win_label = Label.new()
	win_label.text = "★ ★ ★\nGreat!"
	win_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	win_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	win_label.add_theme_font_size_override("font_size", 46)
	win_label.add_theme_color_override("font_color", Color(0.95, 0.58, 0.05))
	win_panel.add_child(win_label)
	again_button = Button.new()
	again_button.text = "Again"
	again_button.focus_mode = Control.FOCUS_NONE
	again_button.add_theme_font_size_override("font_size", 28)
	_apply_button_style(again_button, Color(0.35, 0.72, 0.30))
	again_button.pressed.connect(_reset_game)
	win_panel.add_child(again_button)
	exit_button = Button.new()
	exit_button.text = "Back"
	exit_button.focus_mode = Control.FOCUS_NONE
	exit_button.add_theme_font_size_override("font_size", 28)
	_apply_button_style(exit_button, Color(0.30, 0.57, 0.84))
	exit_button.pressed.connect(_go_back)
	win_panel.add_child(exit_button)

func _apply_localized_text() -> void:
	win_label.text = "★ ★ ★\n%s" % LanguageService.get_ui_text("great")
	again_button.text = LanguageService.get_ui_text("again")
	exit_button.text = LanguageService.get_ui_text("back")

func _play_intro() -> void:
	var stream := LanguageService.get_game_voice("tilt_maze_intro")
	if stream == null or voice_player == null:
		return
	voice_player.stream = stream
	voice_player.play()

func _apply_button_style(button: Button, color: Color) -> void:
	for state in ["normal", "hover", "pressed"]:
		var style := StyleBoxFlat.new()
		style.bg_color = color.darkened(0.14) if state == "pressed" else color
		style.set_corner_radius_all(20)
		style.border_width_bottom = 5
		style.border_color = color.darkened(0.28)
		style.shadow_color = Color(0, 0, 0, 0.20)
		style.shadow_size = 6
		style.shadow_offset = Vector2(0, 3)
		button.add_theme_stylebox_override(state, style)
	button.add_theme_color_override("font_color", Color.WHITE)
	button.add_theme_color_override("font_hover_color", Color.WHITE)
	button.add_theme_color_override("font_pressed_color", Color.WHITE)

func _circle_polygon(radius: float, points: int) -> PackedVector2Array:
	var polygon := PackedVector2Array()
	for i in range(points):
		var angle := TAU * float(i) / float(points)
		polygon.append(Vector2(cos(angle), sin(angle)) * radius)
	return polygon

func _layout() -> void:
	var viewport_size := get_viewport_rect().size
	background.position = Vector2.ZERO
	background.size = viewport_size
	var top_space: float = clampf(viewport_size.y * 0.035, 18.0, 34.0)
	var bottom_space: float = top_space
	var board_size: float = minf(viewport_size.y - top_space - bottom_space, viewport_size.x * 0.72)
	board_size = maxf(board_size, 260.0)
	board_rect = Rect2(
		Vector2((viewport_size.x - board_size) * 0.5, top_space),
		Vector2(board_size, board_size)
	)
	board.position = board_rect.position
	board.scale = board_rect.size / source_size
	var edge: float = maxf(16.0, viewport_size.x * 0.018)
	var button_size: float = clampf(viewport_size.y * 0.115, 74.0, 102.0)
	back_button.position = Vector2(edge, edge)
	back_button.size = Vector2(button_size, button_size)
	win_overlay.position = Vector2.ZERO
	win_overlay.size = viewport_size
	var panel_size := Vector2(minf(viewport_size.x * 0.50, 540.0), minf(viewport_size.y * 0.54, 380.0))
	win_panel.position = (viewport_size - panel_size) * 0.5
	win_panel.size = panel_size
	win_label.position = Vector2(panel_size.x * 0.08, panel_size.y * 0.08)
	win_label.size = Vector2(panel_size.x * 0.84, panel_size.y * 0.48)
	var action_y: float = panel_size.y * 0.68
	var action_w: float = panel_size.x * 0.36
	var action_h: float = panel_size.y * 0.20
	again_button.position = Vector2(panel_size.x * 0.10, action_y)
	again_button.size = Vector2(action_w, action_h)
	exit_button.position = Vector2(panel_size.x * 0.54, action_y)
	exit_button.size = Vector2(action_w, action_h)
	_update_ball_visual()

func _read_direction() -> Vector2:
	var keyboard := Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	if Input.is_physical_key_pressed(KEY_A):
		keyboard.x -= 1.0
	if Input.is_physical_key_pressed(KEY_D):
		keyboard.x += 1.0
	if Input.is_physical_key_pressed(KEY_W):
		keyboard.y -= 1.0
	if Input.is_physical_key_pressed(KEY_S):
		keyboard.y += 1.0
	keyboard = keyboard.limit_length(1.0)
	if touch_active:
		var touch_direction := touch_target - ball_position
		if touch_direction.length() > ball_radius * 0.7:
			return touch_direction.normalized() * 1.15
		return Vector2.ZERO
	var gravity := _read_sensor_vector()
	if gravity.length() <= 1.0:
		return keyboard
	var screen_gravity := _gravity_to_screen(gravity) / SENSOR_GRAVITY
	screen_gravity.x = _sensor_axis(screen_gravity.x, HORIZONTAL_SENSOR_DEADZONE)
	screen_gravity.y = _sensor_axis(screen_gravity.y, VERTICAL_SENSOR_DEADZONE)
	var sensor_direction := Vector2(
		screen_gravity.x * HORIZONTAL_SENSOR_SENSITIVITY,
		screen_gravity.y * VERTICAL_SENSOR_SENSITIVITY
	)
	return (sensor_direction + keyboard).limit_length(1.35)

func _gravity_to_screen(gravity: Vector3) -> Vector2:
	if OS.get_name() == "Android":
		return Vector2(gravity.x, -gravity.y)
	if OS.get_name() == "iOS":
		# iOS reports the landscape sensor axes in the opposite direction from
		# Android. The previous mapping inverted both screen axes, so the ball
		# rolled away from the side the child tilted toward on an iPhone.
		return Vector2(gravity.y, gravity.x)
	return Vector2(-gravity.y, -gravity.x)

func _sensor_axis(value: float, deadzone: float) -> float:
	if absf(value) <= deadzone:
		return 0.0
	return signf(value) * (absf(value) - deadzone) / (1.0 - deadzone)

func _read_sensor_vector() -> Vector3:
	var gravity := Input.get_gravity()
	if gravity.length() > 1.0:
		return gravity
	return Input.get_accelerometer()

func _screen_to_board(point: Vector2) -> Vector2:
	var local := (point - board_rect.position) / board_rect.size
	return Vector2(
		clampf(local.x, 0.0, 1.0) * source_size.x,
		clampf(local.y, 0.0, 1.0) * source_size.y
	)

func _move_ball(delta: float) -> void:
	var displacement := ball_velocity * delta
	var step_limit: float = maxf(ball_radius * 0.32, 2.0)
	var steps: int = maxi(1, int(ceil(displacement.length() / step_limit)))
	var step := displacement / float(steps)
	for _i in range(steps):
		var next_x := ball_position + Vector2(step.x, 0.0)
		if not _ball_hits_wall(next_x):
			ball_position.x = next_x.x
		else:
			ball_velocity.x *= -BOUNCE
		var next_y := ball_position + Vector2(0.0, step.y)
		if not _ball_hits_wall(next_y):
			ball_position.y = next_y.y
		else:
			ball_velocity.y *= -BOUNCE

func _ball_hits_wall(center: Vector2) -> bool:
	return board.hits_wall(center, ball_radius)

func _update_ball_visual() -> void:
	if source_size.x <= 0.0 or board_rect.size.x <= 0.0:
		return
	var normalized := ball_position / source_size
	ball_root.position = board_rect.position + normalized * board_rect.size
	var display_radius: float = BALL_VISUAL_RADIUS_FACTOR * board_rect.size.x
	ball_root.scale = Vector2.ONE * display_radius

func _reset_game() -> void:
	completed = false
	touch_active = false
	ball_velocity = Vector2.ZERO
	if board != null and board.has_method("generate_layout"):
		board.generate_layout()
	ball_position = source_size * START_POSITION
	win_overlay.visible = false
	_update_ball_visual()

func _complete_game() -> void:
	if completed:
		return
	completed = true
	touch_active = false
	ball_velocity = Vector2.ZERO
	ball_position = source_size * 0.5
	_update_ball_visual()
	GameState.last_score = 3
	GameState.add_coins(3)
	SFX.play_praise(get_viewport_rect().size * 0.5, 0.45)
	sfx.stream = CORRECT_SOUND
	sfx.play()
	var tween := create_tween()
	tween.tween_property(ball_root, "scale", ball_root.scale * 1.28, 0.16) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(ball_root, "scale", ball_root.scale, 0.12)
	tween.tween_callback(func():
		sfx.stream = COIN_SOUND
		sfx.play()
		win_overlay.visible = true
	)

func _go_back() -> void:
	SFX.transition_to_scene(back_scene_path)
