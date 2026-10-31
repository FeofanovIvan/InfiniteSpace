extends Node2D

const BACKGROUND_TEXTURE: Texture2D = preload("res://education/playtown/assets/basketball/background.png")
const COURT_TEXTURE: Texture2D = preload("res://education/playtown/assets/basketball/court_hoop.png")
const BALL_TEXTURE: Texture2D = preload("res://education/playtown/assets/basketball/ball.png")
const HOOP_FRONT_TEXTURE: Texture2D = preload("res://education/playtown/assets/basketball/hoop_front_exact.png")
const STAR_TEXTURE: Texture2D = preload("res://education/playtown/assets/ui/star.png")
const GAME_FONT: Font = preload("res://education/playtown/assets/ui/fonts/RobotoCondensed-Variable.ttf")
const CORRECT_SOUND: AudioStream = preload("res://education/playtown/audio/sfx/correct.ogg")
const WRONG_SOUND: AudioStream = preload("res://education/playtown/audio/sfx/wrong.ogg")
const SOURCE_SIZE := Vector2(1672.0, 941.0)
const HOOP_SOURCE_POINT := Vector2(836.0, 303.0)
const IDEAL_POWER := 0.60
# Art calibration: second supplied net image relative to the hoop in the court.
# Alignment finished; keep the front hoop hidden until a scored downward pass.
const HOOP_ALIGNMENT_MODE := false
const SHOT_DURATION := 1.05
const FLOOR_OPAQUE_RATIO := 0.80
const FLOOR_ALPHA_THRESHOLD := 0.70

var floor_edge_source_y: float = -1.0

var background: TextureRect
var court: TextureRect
var trajectory: BasketballTrajectory
var ball: TextureRect
var hoop_front: TextureRect
var power_gauge: BasketballPowerGauge
var throw_button: Button
var direction_buttons: Array[Button] = []
var exit_button: GameExitButton
var score_panel: Panel
var score_label: Label
var result_label: Label
var result_player: AudioStreamPlayer
var charging := false
var shooting := false
var charge := 0.0
var aim_offset := Vector2.ZERO
var held_direction := Vector2.ZERO
var score := 0
var ball_size := 220.0
var ball_start := Vector2.ZERO
var shot_start := Vector2.ZERO
var shot_control := Vector2.ZERO
var shot_end := Vector2.ZERO
var shot_velocity := Vector2.ZERO
var shot_gravity := 0.0
var shot_elapsed := 0.0
var shot_position := Vector2.ZERO
var shot_phase := 0 # 0 idle, 1 flight, 2 through net, 3 rebound/fall
var shot_scored := false
var shot_board_hit := false
var post_hit_elapsed := 0.0
var finishing_shot := false


func _ready() -> void:
	randomize()
	_randomize_aim()
	_build_ui()
	get_viewport().size_changed.connect(_layout)
	_layout()


func _process(delta: float) -> void:
	if charging and not shooting:
		charge = minf(1.0, charge + delta / 1.55)
		power_gauge.value = charge
	if held_direction != Vector2.ZERO and not shooting:
		_adjust_aim(held_direction * delta * 145.0)
	if shooting and not finishing_shot:
		_advance_shot(delta)


func _build_ui() -> void:
	background = _make_fullscreen_texture(BACKGROUND_TEXTURE)
	# The backdrop is aligned independently to the court's alpha edge.
	background.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	background.z_index = -30
	add_child(background)
	court = _make_fullscreen_texture(COURT_TEXTURE)
	court.z_index = -20
	add_child(court)
	trajectory = BasketballTrajectory.new()
	trajectory.mouse_filter = Control.MOUSE_FILTER_IGNORE
	# The aim guide is an overlay, never hidden behind the physical rim.
	trajectory.z_index = 10  # Aim guide above hoop, below stationary ball
	add_child(trajectory)
	ball = TextureRect.new()
	ball.texture = BALL_TEXTURE
	ball.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	ball.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	ball.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ball.z_index = 12  # Ball covers the aim guide at rest
	add_child(ball)
	# Occludes the travelling ball, but not the aim guide.
	hoop_front = TextureRect.new()
	hoop_front.texture = HOOP_FRONT_TEXTURE
	hoop_front.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	hoop_front.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	hoop_front.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hoop_front.z_index = 15
	hoop_front.visible = HOOP_ALIGNMENT_MODE # Show only while a successful ball passes through the rim.
	add_child(hoop_front)
	power_gauge = BasketballPowerGauge.new()
	power_gauge.mouse_filter = Control.MOUSE_FILTER_IGNORE
	power_gauge.z_index = 20
	add_child(power_gauge)
	throw_button = Button.new()
	throw_button.text = ""
	throw_button.icon = BALL_TEXTURE
	throw_button.expand_icon = true
	throw_button.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
	throw_button.focus_mode = Control.FOCUS_NONE
	throw_button.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	_apply_throw_button_style(throw_button, 26)
	throw_button.button_down.connect(_start_charge)
	throw_button.button_up.connect(_release_throw)
	throw_button.z_index = 20
	add_child(throw_button)
	for direction in [Vector2.UP, Vector2.LEFT, Vector2.DOWN, Vector2.RIGHT]:
		var button := Button.new()
		button.text = _direction_symbol(direction)
		button.focus_mode = Control.FOCUS_NONE
		button.add_theme_font_override("font", GAME_FONT)
		button.add_theme_font_size_override("font_size", 42)
		button.add_theme_color_override("font_color", Color.WHITE)
		button.add_theme_color_override("font_outline_color", Color("#235d8b"))
		button.add_theme_constant_override("outline_size", 3)
		_apply_blue_button_style(button, 22)
		button.pressed.connect(_adjust_aim.bind(direction * 18.0))
		button.button_down.connect(_set_held_direction.bind(direction))
		button.button_up.connect(_clear_held_direction)
		button.z_index = 20
		direction_buttons.append(button)
		add_child(button)
	exit_button = GameExitButton.new()
	exit_button.pressed.connect(_go_back)
	exit_button.z_index = 30
	add_child(exit_button)
	_build_score_panel()
	result_label = Label.new()
	result_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	result_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	result_label.add_theme_font_override("font", GAME_FONT)
	result_label.add_theme_font_size_override("font_size", 46)
	result_label.add_theme_color_override("font_color", Color.WHITE)
	result_label.add_theme_color_override("font_outline_color", Color("#7e3d19"))
	result_label.add_theme_constant_override("outline_size", 8)
	result_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	result_label.z_index = 30
	add_child(result_label)
	result_player = AudioStreamPlayer.new()
	result_player.bus = "SFX"
	add_child(result_player)


func _make_fullscreen_texture(texture: Texture2D) -> TextureRect:
	var rect := TextureRect.new()
	rect.texture = texture
	rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return rect


func _build_score_panel() -> void:
	score_panel = Panel.new()
	score_panel.add_theme_stylebox_override("panel", _panel_style())
	score_panel.z_index = 30
	add_child(score_panel)
	var star := TextureRect.new()
	star.texture = STAR_TEXTURE
	star.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	star.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	star.position = Vector2(10, 7)
	star.size = Vector2(58, 58)
	star.mouse_filter = Control.MOUSE_FILTER_IGNORE
	score_panel.add_child(star)
	score_label = Label.new()
	score_label.position = Vector2(70, 5)
	score_label.size = Vector2(72, 62)
	score_label.text = "0"
	score_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	score_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	score_label.add_theme_font_override("font", GAME_FONT)
	score_label.add_theme_font_size_override("font_size", 34)
	score_label.add_theme_color_override("font_color", Color("#6e4027"))
	score_panel.add_child(score_label)


func _layout() -> void:
	var view := get_viewport().get_visible_rect().size
	_layout_background_to_court(view)
	court.position = Vector2.ZERO
	court.size = view
	trajectory.position = Vector2.ZERO
	trajectory.size = view
	var safe := _safe_area_insets(view)
	var margin := clampf(view.y * 0.025, 14.0, 24.0)
	exit_button.position = Vector2(safe.x + margin, safe.y + margin)
	exit_button.size = Vector2(78, 72)
	score_panel.position = Vector2(view.x - safe.z - margin - 148.0, safe.y + margin)
	score_panel.size = Vector2(148, 72)
	ball_size = clampf(view.y * 0.36, 190.0, 300.0)
	ball.size = Vector2.ONE * ball_size
	# Only a little more than half of the ball remains visible at rest.
	ball_start = Vector2(view.x * 0.50, view.y - ball_size * 0.06)
	ball.position = ball_start - ball.size * 0.5
	ball.scale = Vector2.ONE
	_layout_hoop_front(view)
	var control_side := clampf(view.y * 0.102, 62.0, 86.0)
	var control_gap := clampf(view.y * 0.012, 8.0, 12.0)
	var cluster_x := view.x - safe.z - margin - control_side * 3.0 - control_gap * 2.0
	var bottom_row_y := view.y - safe.w - margin - control_side
	direction_buttons[0].position = Vector2(cluster_x + control_side + control_gap, bottom_row_y - control_side - control_gap)
	direction_buttons[1].position = Vector2(cluster_x, bottom_row_y)
	direction_buttons[2].position = Vector2(cluster_x + control_side + control_gap, bottom_row_y)
	direction_buttons[3].position = Vector2(cluster_x + (control_side + control_gap) * 2.0, bottom_row_y)
	for button in direction_buttons:
		button.size = Vector2.ONE * control_side
	var throw_side := clampf(view.y * 0.125, 90.0, 114.0)
	throw_button.position = Vector2(safe.x + margin, view.y - safe.w - margin - throw_side)
	throw_button.size = Vector2.ONE * throw_side
	var gauge_height := clampf(view.y * 0.30, 170.0, 245.0)
	power_gauge.size = Vector2(48.0, gauge_height)
	power_gauge.position = Vector2(throw_button.position.x + (throw_side - power_gauge.size.x) * 0.5, throw_button.position.y - control_gap - gauge_height)
	result_label.position = Vector2(view.x * 0.25, safe.y + margin)
	result_label.size = Vector2(view.x * 0.50, 82.0)
	_update_trajectory()


# Finds the first wide, opaque band of court flooring. Scanned once, not per frame.
# The backboard and pole are too narrow to qualify as a floor boundary.
func _find_floor_edge() -> float:
	if floor_edge_source_y >= 0.0:
		return floor_edge_source_y
	var image: Image = COURT_TEXTURE.get_image()
	if image == null or image.is_empty():
		# Fail-safe: use the court's lower edge; never break the game if image data is unavailable.
		return float(COURT_TEXTURE.get_height())
	var width: int = image.get_width()
	var height: int = image.get_height()
	var step_x: int = maxi(1, floori(float(width) / 160.0))
	var sample_count: int = ceili(float(width) / float(step_x))
	var required_count: int = ceili(float(sample_count) * FLOOR_OPAQUE_RATIO)
	for y in range(int(float(height) * 0.35), height):
		var solid_count: int = 0
		for x in range(0, width, step_x):
			if image.get_pixel(x, y).a >= FLOOR_ALPHA_THRESHOLD:
				solid_count += 1
		if solid_count >= required_count:
			floor_edge_source_y = float(y)
			return floor_edge_source_y
	floor_edge_source_y = float(height)
	return floor_edge_source_y


func _layout_background_to_court(view: Vector2) -> void:
	# Court rendering is unchanged: TextureRect covers the viewport, preserving aspect.
	var court_source := Vector2(COURT_TEXTURE.get_size())
	var court_scale: float = maxf(view.x / court_source.x, view.y / court_source.y)
	var court_origin_y: float = (view.y - court_source.y * court_scale) * 0.5
	var floor_screen_y: float = court_origin_y + _find_floor_edge() * court_scale

	# Background's bottom edge (fence base) meets the start of the opaque floor.
	# Scale background to cover the complete area above it, without gaps.
	var bg_source := Vector2(BACKGROUND_TEXTURE.get_size())
	var bg_scale: float = maxf(view.x / bg_source.x, maxf(1.0, floor_screen_y) / bg_source.y)
	background.size = bg_source * bg_scale
	background.position = Vector2((view.x - background.size.x) * 0.5, floor_screen_y - background.size.y)


func _start_charge() -> void:
	if shooting:
		return
	charging = true
	charge = 0.0
	power_gauge.value = 0.0
	result_label.text = ""


func _release_throw() -> void:
	if not charging or shooting:
		return
	charging = false
	_throw_ball()


func _layout_hoop_front(view: Vector2) -> void:
	# Same size, origin and cover transform as court_hoop.png.
	# Therefore the net and rim coincide with the originals at any resolution.
	hoop_front.position = court.position
	hoop_front.size = court.size


func _throw_ball() -> void:
	# Keep the front net hidden during the approach to the hoop.
	hoop_front.visible = HOOP_ALIGNMENT_MODE
	shooting = true
	finishing_shot = false
	held_direction = Vector2.ZERO
	_set_controls_enabled(false)
	trajectory.visible = false
	shot_start = ball_start
	shot_position = shot_start
	shot_end = _hoop_center() + aim_offset + Vector2(0.0, (IDEAL_POWER - charge) * get_viewport().get_visible_rect().size.y * 0.62)
	shot_elapsed = 0.0
	post_hit_elapsed = 0.0
	shot_phase = 1
	shot_scored = false
	shot_board_hit = false
	# Kinematic parabolic flight in screen space: height is acceleration-driven,
	# not a tween along the static aim curve. Endpoint is the projected rim plane.
	var view := get_viewport().get_visible_rect().size
	shot_gravity = view.y * 3.25
	shot_velocity = Vector2((shot_end.x - shot_start.x) / SHOT_DURATION,
		(shot_end.y - shot_start.y - 0.5 * shot_gravity * SHOT_DURATION * SHOT_DURATION) / SHOT_DURATION)
	_update_ball_image(0.0)


func _advance_shot(delta: float) -> void:
	var dt: float = minf(delta, 0.05)
	shot_elapsed += dt
	if shot_phase == 1:
		var t: float = minf(shot_elapsed, SHOT_DURATION)
		shot_position = shot_start + shot_velocity * t + Vector2(0.0, 0.5 * shot_gravity * t * t)
		var vertical_speed: float = shot_velocity.y + shot_gravity * t
		# The backboard sits just above the rim. Rebound when a high shot
		# approaches it on its way down rather than magically passing through.
		var hoop := _hoop_center()
		var view := get_viewport().get_visible_rect().size
		var near_board_x: bool = absf(shot_position.x - hoop.x) <= view.y * 0.105
		var near_board_y: bool = shot_position.y >= hoop.y - view.y * 0.17 and shot_position.y < hoop.y - view.y * 0.035
		var high_miss: bool = shot_end.y < hoop.y - view.y * 0.04
		if not shot_board_hit and high_miss and vertical_speed > 0.0 and near_board_x and near_board_y:
			shot_board_hit = true
			shot_phase = 3
			shot_velocity = Vector2((shot_position.x - hoop.x) * 2.0, -maxf(90.0, vertical_speed * 0.30))
			shot_elapsed = 0.0
		elif t >= SHOT_DURATION:
			var width_limit: float = maxf(28.0, view.y * 0.07)
			var height_limit: float = maxf(20.0, view.y * 0.055)
			shot_scored = absf(shot_position.x - hoop.x) < width_limit and absf(shot_position.y - hoop.y) < height_limit and absf(charge - IDEAL_POWER) < 0.085
			shot_elapsed = 0.0
			if shot_scored:
				shot_phase = 2
				# Show the foreground of the rim only during the downward net pass.
				hoop_front.visible = true
			else:
				shot_phase = 3
				shot_velocity = Vector2(shot_velocity.x, vertical_speed)
	elif shot_phase == 2:
		# Ball visibly drops through the centre of the net; front mesh covers it.
		shot_position.x = lerpf(shot_position.x, _hoop_center().x, minf(1.0, dt * 5.0))
		shot_position.y += get_viewport().get_visible_rect().size.y * 0.24 * dt
		if shot_elapsed >= 0.38:
			_complete_shot()
	elif shot_phase == 3:
		shot_velocity.y += shot_gravity * dt
		shot_position += shot_velocity * dt
		if shot_elapsed >= 0.7 or shot_position.y > get_viewport().get_visible_rect().size.y + ball_size:
			_complete_shot()
	_update_ball_image(minf(1.0, shot_elapsed / SHOT_DURATION) if shot_phase == 1 else 1.0)


func _update_ball_image(progress: float) -> void:
	var target_size: float = ball_size * lerpf(1.0, 0.23, progress)
	if shot_phase == 2:
		target_size *= lerpf(1.0, 0.76, minf(1.0, shot_elapsed / 0.38))
	ball.size = Vector2.ONE * target_size
	ball.position = shot_position - ball.size * 0.5
	# No artificial 1.8 full rotations; the ball remains visually stable.
	ball.rotation = 0.0


func _complete_shot() -> void:
	if finishing_shot:
		return
	finishing_shot = true
	hoop_front.visible = HOOP_ALIGNMENT_MODE
	if shot_scored:
		score += 1
		score_label.text = str(score)
		GameState.add_coins(1)
		result_label.text = "✓"
		result_player.stream = CORRECT_SOUND
	else:
		result_label.text = "↻"
		result_player.stream = WRONG_SOUND
	result_player.play()
	await get_tree().create_timer(0.55).timeout
	if not is_inside_tree():
		return
	if shot_scored:
		_randomize_aim()
	_reset_ball()


func _reset_ball() -> void:
	hoop_front.visible = HOOP_ALIGNMENT_MODE
	ball.rotation = 0.0
	ball.size = Vector2.ONE * ball_size
	ball.position = ball_start - ball.size * 0.5
	charge = 0.0
	power_gauge.value = 0.0
	shooting = false
	finishing_shot = false
	shot_phase = 0
	trajectory.visible = true
	_set_controls_enabled(true)
	_update_trajectory()


func _adjust_aim(delta: Vector2) -> void:
	if shooting:
		return
	var view := get_viewport().get_visible_rect().size
	aim_offset += delta
	aim_offset.x = clampf(aim_offset.x, -view.x * 0.16, view.x * 0.16)
	aim_offset.y = clampf(aim_offset.y, -view.y * 0.14, view.y * 0.14)
	_update_trajectory()


func _set_held_direction(direction: Vector2) -> void:
	held_direction = direction


func _clear_held_direction() -> void:
	held_direction = Vector2.ZERO


func _update_trajectory() -> void:
	if not is_instance_valid(trajectory):
		return
	var view := get_viewport().get_visible_rect().size
	trajectory.configure(ball_start - Vector2(0.0, ball_size * 0.24), _hoop_center() + aim_offset, view.y * 0.25)


func _randomize_aim() -> void:
	var horizontal := randf_range(-150.0, 150.0)
	if absf(horizontal) < 70.0:
		horizontal = 70.0 if horizontal >= 0.0 else -70.0
	aim_offset = Vector2(horizontal, randf_range(-85.0, 85.0))


func _hoop_center() -> Vector2:
	var view := get_viewport().get_visible_rect().size
	var scale_factor := maxf(view.x / SOURCE_SIZE.x, view.y / SOURCE_SIZE.y)
	var offset := (view - SOURCE_SIZE * scale_factor) * 0.5
	return offset + HOOP_SOURCE_POINT * scale_factor


func _set_controls_enabled(enabled: bool) -> void:
	throw_button.disabled = not enabled
	for button in direction_buttons:
		button.disabled = not enabled


func _direction_symbol(direction: Vector2) -> String:
	if direction == Vector2.LEFT:
		return "←"
	if direction == Vector2.RIGHT:
		return "→"
	if direction == Vector2.UP:
		return "↑"
	return "↓"


func _apply_red_button_style(button: Button, radius: int) -> void:
	button.add_theme_stylebox_override("normal", _red_style(Color("#e84d42"), radius, 0.0))
	button.add_theme_stylebox_override("hover", _red_style(Color("#f45b4f"), radius, 0.0))
	button.add_theme_stylebox_override("pressed", _red_style(Color("#c93630"), radius, 3.0))
	button.add_theme_stylebox_override("disabled", _red_style(Color("#b7847f"), radius, 0.0))

func _apply_blue_button_style(button: Button, radius: int) -> void:
	button.add_theme_stylebox_override("normal", _filled_button_style(Color("#67c9ef"), Color("#ffffff"), radius, 0.0, Color("#2d79b0")))
	button.add_theme_stylebox_override("hover", _filled_button_style(Color("#7ad7fb"), Color("#ffffff"), radius, 0.0, Color("#2d79b0")))
	button.add_theme_stylebox_override("pressed", _filled_button_style(Color("#53b8dd"), Color("#ffffff"), radius, 3.0, Color("#2d79b0")))
	button.add_theme_stylebox_override("disabled", _filled_button_style(Color("#9bbaca"), Color("#eef6fb"), radius, 0.0, Color("#6e8ea2")))


func _apply_throw_button_style(button: Button, radius: int) -> void:
	# Same blue family as the arrow keys; the orange ball remains the icon.
	_apply_blue_button_style(button, radius)



func _filled_button_style(fill: Color, border: Color, radius: int, pressed_offset: float, shadow: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.border_color = border
	style.set_border_width_all(3)
	style.set_corner_radius_all(radius)
	style.content_margin_left = 10.0
	style.content_margin_right = 10.0
	style.content_margin_top = 10.0 + pressed_offset
	style.content_margin_bottom = 10.0 - pressed_offset
	style.shadow_color = shadow.darkened(0.35)
	style.shadow_size = 8
	style.shadow_offset = Vector2(0, 5)
	return style


func _red_style(fill: Color, radius: int, pressed_offset: float) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.border_color = Color.WHITE
	style.set_border_width_all(3)
	style.set_corner_radius_all(radius)
	style.content_margin_top = 8.0 + pressed_offset
	style.content_margin_bottom = 8.0 - pressed_offset
	style.shadow_color = Color(0.22, 0.05, 0.03, 0.35)
	style.shadow_size = 8
	style.shadow_offset = Vector2(0, 5)
	return style


func _panel_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color("#fff5d9")
	style.border_color = Color("#dc9b35")
	style.set_border_width_all(4)
	style.set_corner_radius_all(18)
	style.shadow_color = Color(0.2, 0.1, 0.04, 0.28)
	style.shadow_size = 7
	style.shadow_offset = Vector2(0, 5)
	return style


func _localized(values: Dictionary) -> String:
	var locale := LanguageService.interface_locale if LanguageService else "en"
	return String(values.get(locale, values.get("en", "")))


func _safe_area_insets(view: Vector2) -> Vector4:
	if OS.get_name() not in ["iOS", "Android"]:
		return Vector4.ZERO
	var window_size := Vector2(DisplayServer.window_get_size())
	var safe_rect := DisplayServer.get_display_safe_area()
	if window_size.x <= 0.0 or window_size.y <= 0.0 or safe_rect.size.x <= 0:
		return Vector4.ZERO
	var scale := Vector2(view.x / window_size.x, view.y / window_size.y)
	return Vector4(float(safe_rect.position.x) * scale.x, float(safe_rect.position.y) * scale.y, maxf(0.0, window_size.x - safe_rect.end.x) * scale.x, maxf(0.0, window_size.y - safe_rect.end.y) * scale.y)


func _go_back() -> void:
	SFX.transition_to_scene(GameState.main_scene_path)
