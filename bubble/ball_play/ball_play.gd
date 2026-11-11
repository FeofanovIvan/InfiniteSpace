extends Control
## MIKA Bubble Ball v8.5.7: release ball in front of Bubble until next throw.
# MIKA_BUBBLE_BALL_RELEASE_FRONT_V8_5_7
# MIKA_BUBBLE_BALL_SOUNDS_V8_5_9
## The existing planet-hub renderer supplies the background. This Control only
## draws controls and the play actors, so there is no planet-image scene swap.
signal exit_requested

const BUBBLE_SCENE: PackedScene = preload("res://bubble/scenes/bubble_character.tscn")
const JOYSTICK_SCRIPT: Script = preload("res://bubble/scripts/room_joystick.gd")
const ACTION_SCRIPT: Script = preload("res://scripts/ActionButton.gd")
const BACK_ARROW: Script = preload("res://simulator_ui/back_arrow_glyph.gd")
const STRENGTH_SCRIPT: Script = preload("res://bubble/ball_play/strength_bar.gd")
const BALL_VISUAL_SCRIPT: Script = preload("res://bubble/ball_play/ball_visual.gd")
const SHARED_PLANETS: String = "res://planet_hub/data/uninhabited_shared_backgrounds.json"
const PLAY_ZONES: String = "res://bubble/ball_play/play_zones.json"
const MAX_SHOTS: int = 5
const NEAR_SIDE_MARGIN: float = 0.15
const FAR_SIDE_MARGIN: float = 0.25
const IDEAL_FAR_Y: float = 0.40
const BALL_START_Y: float = 0.925
const FAR_SCALE: float = 0.78
const MIN_CHARGE: float = 0.12
const CHARGE_HALF_CYCLE: float = 1.30
const THROW_DURATION: float = 1.68
const PICKUP_DURATION: float = 1.48
const DROP_DURATION: float = 1.34
const MOUTH_PICKUP_TOLERANCE: float = 6.0
const MOUTH_DROP_TOLERANCE: float = 5.0
const CARRY_BALL_SIZE: float = 0.43
const ROUND_MOUTH_TEXTURE: Texture2D = preload("res://bubble/assets/face/mouth_o.png")
# Back-facing collection hides the regular face; the temporary mouth is a
# separate composite attached to the exact face's existing mouth coordinate.

const THROW_TEXT: Dictionary = {
	"ru": "БРОСИТЬ", "en": "THROW", "fr": "LANCER", "de": "WERFEN",
	"es": "LANZAR", "pt_BR": "LANÇAR"
}

var _ball_sound: AudioStreamPlayer
var _ball_hit_sound: AudioStreamPlayer
var _planet_id: String = ""
var _profile: Dictionary = {"far_y": 0.52}
var _allowed: Rect2
var _far_y: float = 0.0
var _near_y: float = 0.0
var _bubble_base_scale: float = 1.0
var _ball_base_scale: float = 1.0
var _bubble: MikaBubbleBrain
var _ball: Node2D
var _joystick: Control
var _throw_button: Control
var _throw_label: Label
var _back_button: Button
var _meter: Control
var _rng: RandomNumberGenerator = RandomNumberGenerator.new()
var _input_enabled: bool = false
var _time: float = 0.0
var _pose: Vector2 = Vector2.ZERO
var _home: Vector2 = Vector2.ZERO
var _ball_ground: Vector2 = Vector2.ZERO
var _ball_start: Vector2 = Vector2.ZERO
var _pickup_lean: float = 0.0
var _drop_lean: float = 0.0
var _entry_start: Vector2 = Vector2.ZERO
var _entry_time: float = 0.0
var _state: String = "entering" # entering / ready / clearing / flying / landed / pickup / returning / dropping
var _idle_kind: String = "pause" # pause / wander / zigzag / hop / twirl
var _idle_clock: float = 0.0
var _idle_span: float = 0.0
var _idle_target: Vector2 = Vector2.ZERO
var _idle_twirl_sign: float = 1.0
var _idle_speed: float = 195.0
var _idle_spin: float = 0.0
var _facing: float = 0.0
var _motion_energy: float = 0.0
var _gaze_target: Vector2 = Vector2.ZERO
var _last_stick: Vector2 = Vector2(0.0, -1.0)
var _charge_elapsed: float = 0.0
var _charging: bool = false
var _strength: float = MIN_CHARGE
var _locked_strength: float = MIN_CHARGE
var _locked_pitch: float = 0.5
var _shots_left: int = MAX_SHOTS
var _flight_clock: float = 0.0
var _flight_duration: float = THROW_DURATION
var _clear_target: Vector2 = Vector2.ZERO
var _clear_clock: float = 0.0
var _landing_clock: float = 0.0
var _pickup_side: float = 1.0
var _ball_in_mouth: bool = false
var _drop_ground_target: Vector2 = Vector2.ZERO
var _flight_start: Vector2 = Vector2.ZERO
var _flight_end: Vector2 = Vector2.ZERO
var _pickup_clock: float = 0.0
var _pickup_ball_from: Vector2 = Vector2.ZERO
var _drop_clock: float = 0.0
var _drop_ball_from: Vector2 = Vector2.ZERO
var _fetch_mouth: Node2D
var _fetch_round: Sprite2D
var _fetch_socket: Marker2D
var _ball_ground_marker: Marker2D
var _mouth_point_marker: Marker2D
var _ball_pickup_start: Vector2 = Vector2.ZERO
var _drop_released: bool = false
# Keep the delivered ball visibly in front from mouth release through landing.
# Reset only at the NEXT throw; ordinary flight keeps depth sorting.
var _returned_ball_front: bool = false
var _drop_start_fraction: float = CARRY_BALL_SIZE
var _pickup_alignment_wait: float = 0.0
var _drop_alignment_wait: float = 0.0
var _drop_ground_marker: Marker2D

func configure_planet(id: String, _background_path: String) -> void:
	_planet_id = id
	_profile = {"far_y": 0.52}
	if not FileAccess.file_exists(SHARED_PLANETS) or not FileAccess.file_exists(PLAY_ZONES):
		return
	var listing: Variant = JSON.parse_string(FileAccess.get_file_as_string(SHARED_PLANETS))
	var profiles: Variant = JSON.parse_string(FileAccess.get_file_as_string(PLAY_ZONES))
	if not (listing is Dictionary and profiles is Dictionary):
		return
	var mappings: Dictionary = listing.get("planet_to_background", {})
	if not mappings.has(id):
		return
	var code: String = "%02d" % int(mappings[id])
	var zones: Dictionary = profiles.get("profiles_by_shared_background", {})
	if zones.get(code) is Dictionary:
		_profile = zones[code]

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	process_mode = Node.PROCESS_MODE_ALWAYS
	_rng.randomize()
	# Run after the brain and FaceRig, so the temporary mouth does not flicker.
	process_priority = 150
	_bubble = BUBBLE_SCENE.instantiate() as MikaBubbleBrain
	_bubble.name = "ONE_ExistingLiquidBubble_NoSpriteSwaps"
	_bubble.external_motion_control = true
	_bubble.auto_return_idle = false
	_bubble.z_index = 20
	add_child(_bubble)
	_ball = BALL_VISUAL_SCRIPT.new() as Node2D
	_ball.name = "OriginalReal3DCircuitBall"
	_ball.z_index = 18 # Depth sorting updates this whenever the ball is free.
	add_child(_ball)
	_ball_ground_marker = Marker2D.new()
	_ball_ground_marker.name = "BALL_PICKUP_POINT_OnPlanetGround"
	add_child(_ball_ground_marker)
	_mouth_point_marker = Marker2D.new()
	_mouth_point_marker.name = "MOUTH_ATTACH_POINT_ActualFaceRig"
	add_child(_mouth_point_marker)
	_drop_ground_marker = Marker2D.new()
	_drop_ground_marker.name = "BALL_RETURN_POINT_OriginalThrowOrigin"
	add_child(_drop_ground_marker)
	_build_fetch_mouth()
	_make_controls()
	_ball_sound = AudioStreamPlayer.new()
	_ball_sound.name = "BubbleBallThrowAndReturn"
	_ball_sound.volume_db = -16.0
	add_child(_ball_sound)
	_ball_hit_sound = AudioStreamPlayer.new()
	_ball_hit_sound.name = "BubbleBallTouchdown"
	_ball_hit_sound.volume_db = -18.0
	add_child(_ball_hit_sound)
	if not MobileLocale.language_changed.is_connected(_on_language_changed):
		MobileLocale.language_changed.connect(_on_language_changed)
	resized.connect(_layout)
	_layout()
	_ball_start = Vector2(size.x * 0.5, _near_y)
	_ball_ground = _ball_start
	_home = _clamp_play_position(Vector2(size.x * 0.305, _near_y - size.y * 0.08), 16.0)
	_entry_start = Vector2(-125.0, _near_y)
	_pose = _entry_start
	_idle_target = _home
	_bubble.position = _pose
	_ball.position = _ball_start
	_ball.visible = true
	_bubble.set_room_emotion("excited", 1.6)
	set_input_enabled(false)

func _make_controls() -> void:
	_joystick = JOYSTICK_SCRIPT.new() as Control
	_joystick.name = "OriginalRightJoystick_Aim"
	_joystick.z_index = 70
	add_child(_joystick)
	_joystick.connect("direction_changed", Callable(self, "_aim_changed"))
	_throw_button = ACTION_SCRIPT.new() as Control
	_throw_button.name = "OriginalLeftAction_Throw"
	_throw_button.z_index = 70
	add_child(_throw_button)
	_throw_button.call("set_action_mode", "use")
	_throw_button.call("set_action_available", true)
	_throw_button.connect("action_requested", Callable(self, "_on_throw_released"))
	_throw_label = Label.new()
	_throw_label.name = "Throw_SixLanguages"
	_throw_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_throw_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_throw_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_throw_label.add_theme_color_override("font_color", Color("e7fbff"))
	_throw_label.add_theme_color_override("font_shadow_color", Color("03152b"))
	_throw_label.add_theme_constant_override("shadow_offset_y", 1)
	_throw_label.add_theme_font_size_override("font_size", 16)
	_throw_button.add_child(_throw_label)
	_meter = STRENGTH_SCRIPT.new() as Control
	_meter.name = "VerticalGreenToRedStrength"
	_meter.z_index = 72
	add_child(_meter)
	_back_button = Button.new()
	_back_button.name = "SameSimulatorBackButton"
	_back_button.text = ""
	_back_button.focus_mode = Control.FOCUS_NONE
	_back_button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	_back_button.z_index = 80
	var style := StyleBoxFlat.new()
	style.bg_color = Color("061c38")
	style.border_color = Color("26dfff")
	style.set_border_width_all(2)
	style.set_corner_radius_all(18)
	style.shadow_color = Color(0.04, 0.64, 1.0, 0.47)
	style.shadow_size = 6
	_back_button.add_theme_stylebox_override("normal", style)
	var hover := style.duplicate() as StyleBoxFlat
	hover.bg_color = Color("113a60")
	_back_button.add_theme_stylebox_override("hover", hover)
	_back_button.add_theme_stylebox_override("pressed", hover)
	_back_button.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	add_child(_back_button)
	var glyph: Control = BACK_ARROW.new() as Control
	glyph.name = "ThickNeonBackArrow"
	glyph.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_back_button.add_child(glyph)
	glyph.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_back_button.pressed.connect(_request_exit)
	_on_language_changed("")

func set_input_enabled(enabled: bool) -> void:
	_input_enabled = enabled
	if is_instance_valid(_back_button):
		_back_button.disabled = not enabled
	if is_instance_valid(_throw_button):
		_throw_button.set_process_input(enabled)
	if is_instance_valid(_joystick):
		_joystick.set_process_input(enabled)

func _on_language_changed(_locale: String) -> void:
	if is_instance_valid(_throw_label):
		_throw_label.text = str(THROW_TEXT.get(str(MobileLocale.language), THROW_TEXT["en"]))

func _layout() -> void:
	if size.x < 100.0 or size.y < 100.0:
		return
	var w: float = size.x
	var h: float = size.y
	var safe: Rect2 = MobileLocale.safe_rect(size)
	_far_y = h * maxf(IDEAL_FAR_Y, float(_profile.get("far_y", IDEAL_FAR_Y)))
	_near_y = h * BALL_START_Y
	_far_y = minf(_far_y, _near_y - h * 0.10)
	_allowed = Rect2(Vector2(w * NEAR_SIDE_MARGIN, _far_y), Vector2(w * (1.0 - NEAR_SIDE_MARGIN * 2.0), maxf(25.0, h * 0.94 - _far_y)))
	var control_scale: float = clampf(minf(w / 520.0, h / 340.0), 0.55, 1.0) * 1.10
	var visual: float = 184.0 * control_scale
	var margin: float = 18.0 * control_scale
	_joystick.scale = Vector2.ONE * control_scale
	_throw_button.scale = Vector2.ONE * control_scale
	_joystick.position = Vector2(safe.end.x - visual - margin, safe.end.y - visual - margin)
	_throw_button.position = Vector2(safe.position.x + margin, safe.end.y - visual - margin)
	_throw_label.position = Vector2(26.0, 123.0)
	_throw_label.size = Vector2(132.0, 32.0)
	var hub_scale: float = minf(h / 864.0, w / 1680.0)
	var back_side: float = maxf(44.0, 158.0 * hub_scale * 0.60)
	_back_button.position = Vector2(safe.position.x + maxf(10.0, 24.0 * hub_scale), safe.position.y + 20.0 * hub_scale)
	_back_button.size = Vector2.ONE * back_side
	# Vertical gauge, thicker than a normal status bar. Small screens clamp the
	# height instead of allowing the gauge to collide with the back button.
	var meter_top_limit: float = _back_button.position.y + back_side + 8.0 * control_scale
	var meter_height: float = minf(178.0 * control_scale, maxf(52.0 * control_scale, _throw_button.position.y - meter_top_limit - 13.0 * control_scale))
	_meter.size = Vector2(37.0 * control_scale, meter_height)
	_meter.position = Vector2(_throw_button.position.x + (visual - _meter.size.x) * 0.5, maxf(meter_top_limit, _throw_button.position.y - meter_height - 13.0 * control_scale))
	# Keep the same 100→78% perspective, but begin with a slightly larger Bubble.
	_bubble_base_scale = 0.395 * clampf(minf(w / 1280.0, h / 720.0), 0.60, 1.25)
	# The 3D ball was disproportionately large. Its base size is smaller;
	# the single shared depth factor still applies to BOTH characters.
	_ball_base_scale = 0.67 * clampf(minf(w / 1280.0, h / 720.0), 0.72, 1.40)
	_home = _clamp_play_position(Vector2(w * 0.305, _near_y - h * 0.08), 16.0)
	if _state == "entering":
		_entry_start = Vector2(-125.0, _near_y)
	if _state != "entering":
		_pose = _clamp_play_position(_pose, 13.0)
		_idle_target = _clamp_play_position(_idle_target, 13.0)
	_bubble.scale = Vector2.ONE * _bubble_base_scale * _perspective_scale(_pose.y)
	if not _ball_in_mouth:
		_ball.scale = Vector2.ONE * _ball_base_scale * _perspective_scale(_ball_ground.y)
	queue_redraw()

func _margin_at_y(y: float) -> float:
	# Exact trapezoid: 15% side margins near, 25% at the far horizon.
	return lerpf(NEAR_SIDE_MARGIN, FAR_SIDE_MARGIN, _depth_fraction(y))

func _clamp_play_position(point: Vector2, padding: float = 0.0) -> Vector2:
	var y: float = clampf(point.y, _far_y + padding, _near_y)
	var side: float = _margin_at_y(y) * size.x
	return Vector2(clampf(point.x, side + padding, size.x - side - padding), y)

func _depth_fraction(y: float) -> float:
	return clampf((_near_y - y) / maxf(1.0, _near_y - _far_y), 0.0, 1.0)

func _perspective_scale(y: float) -> float:
	return lerpf(1.0, FAR_SCALE, _depth_fraction(y))

func _softstep(t: float) -> float:
	var v: float = clampf(t, 0.0, 1.0)
	return v * v * (3.0 - 2.0 * v)

func _throw_origin() -> Vector2:
	return Vector2(size.x * 0.50, _near_y)

func _aim_changed(direction: Vector2) -> void:
	if not _input_enabled or direction.length_squared() < 0.015:
		return
	_last_stick = direction.limit_length(1.0)
	queue_redraw()

func _pitch() -> float:
	# Up/down on the joystick tilts the arrow's arc rather than modifying
	# its length, and is locked when the ball leaves the hand.
	return clampf(0.5 - _last_stick.y * 0.5, 0.0, 1.0)

func _guide_endpoint() -> Vector2:
	# This is the SAME long guide for weak and strong throws. Only joystick
	# direction changes it; the strength bar never scales the guide.
	var origin: Vector2 = _throw_origin()
	var length_px: float = maxf(40.0, _near_y - _far_y - 15.0)
	var max_bearing: float = minf(0.77, atan(size.x * 0.225 / maxf(1.0, length_px)))
	var bearing: float = clampf(_last_stick.x, -1.0, 1.0) * max_bearing
	return _clamp_play_position(origin + Vector2(sin(bearing), -cos(bearing)) * length_px, 12.0)

func _calculate_throw(power: float) -> Vector2:
	var fraction: float = clampf((power - MIN_CHARGE) / (1.0 - MIN_CHARGE), 0.0, 1.0)
	# Strength controls distance; aiming always shows the FULL depth of the field.
	# Reserve enough room for Bubble's projected mouth BELOW the far horizon.
	# Otherwise the body would stop at the edge while its mouth could not reach
	# a ball only twelve pixels below that edge.
	var endpoint: Vector2 = _clamp_play_position(_throw_origin().lerp(_guide_endpoint(), 0.045 + 0.955 * pow(fraction, 0.85)), 12.0)
	var ui_scale: float = clampf(minf(size.x / 1280.0, size.y / 720.0), 0.60, 1.25)
	endpoint.y = maxf(endpoint.y, _far_y + maxf(42.0, 54.0 * ui_scale))
	return _clamp_play_position(endpoint, 12.0)

func _flight_ground_point(t: float, start: Vector2, end: Vector2) -> Vector2:
	# Forward travel is independent of vertical lift. It accelerates visibly
	# into the screen rather than jumping up and down in place.
	var u: float = clampf(t, 0.0, 1.0)
	var advance: float = 1.0 - pow(1.0 - u, 1.26)
	return start.lerp(end, advance)

func _flight_point(t: float, start: Vector2, end: Vector2, pitch: float) -> Vector2:
	var ground: Vector2 = _flight_ground_point(t, start, end)
	var distance: float = start.distance_to(end)
	var full_distance: float = maxf(1.0, _near_y - _far_y)
	var power_depth: float = clampf(distance / full_distance, 0.0, 1.0)
	var lift: float = (size.y * (0.024 + 0.027 * pitch) + distance * 0.09) * (0.23 + 0.77 * sqrt(power_depth)) * maxf(0.0, sin(PI * t))
	return Vector2(ground.x, ground.y - lift)

func _distance_to_segment(point: Vector2, start: Vector2, end: Vector2) -> float:
	var axis: Vector2 = end - start
	var squared: float = maxf(1.0, axis.length_squared())
	var t: float = clampf((point - start).dot(axis) / squared, 0.0, 1.0)
	return point.distance_to(start + axis * t)

func _safe_away_from_throw(point: Vector2, start: Vector2, end: Vector2, clearance: float) -> Vector2:
	var axis: Vector2 = end - start
	var len2: float = maxf(1.0, axis.length_squared())
	var along: float = clampf((point - start).dot(axis) / len2, 0.0, 1.0)
	var closest: Vector2 = start + axis * along
	var away: Vector2 = (point - closest).normalized()
	if away.length_squared() < 0.01:
		away = Vector2(-1.0, 0.0)
	var left: Vector2 = _clamp_play_position(closest + away * clearance, 24.0)
	var right: Vector2 = _clamp_play_position(closest - away * clearance, 24.0)
	return left if _distance_to_segment(left, start, end) >= _distance_to_segment(right, start, end) else right

func _play_ball_sound(name: String, touchdown: bool = false) -> void:
	var player: AudioStreamPlayer = _ball_hit_sound if touchdown else _ball_sound
	if not is_instance_valid(player):
		return
	var path: String = "res://learning/audio/sfx/" + name
	if not ResourceLoader.exists(path):
		return
	player.stop()
	player.stream = load(path) as AudioStream
	player.play()

func _launch_projectile() -> void:
	_flight_clock = 0.0
	_state = "flying"
	_play_ball_sound("connect_point.ogg")
	_bubble.set_room_emotion("excited", 1.35)

func _on_throw_released(_mode: String) -> void:
	if not _input_enabled or _state != "ready" or _shots_left <= 0:
		return
	_charging = false
	_returned_ball_front = false # New projectile uses normal 2.5D depth sorting.
	_shots_left -= 1
	_locked_strength = _strength
	_locked_pitch = _pitch()
	_flight_start = _throw_origin()
	_flight_end = _calculate_throw(_locked_strength)
	_flight_duration = THROW_DURATION + 0.28 * _depth_fraction(_flight_end.y)
	_ball_ground = _flight_start
	_ball.visible = true
	_ball.position = _flight_start
	_ball.modulate = Color.WHITE
	_throw_button.call("set_action_available", false)
	# Bubble must clear the actual shot corridor BEFORE the projectile flies.
	var clearance: float = 94.0 * clampf(minf(size.x / 1280.0, size.y / 720.0), 0.65, 1.3)
	if _distance_to_segment(_pose, _flight_start, _flight_end) < clearance:
		_clear_target = _safe_away_from_throw(_pose, _flight_start, _flight_end, clearance + 30.0)
		_clear_clock = 0.0
		_state = "clearing"
		_bubble.set_room_emotion("playful", 0.8)
	else:
		_launch_projectile()
	queue_redraw()

func _choose_idle_action() -> void:
	_idle_clock = 0.0
	var choice: float = _rng.randf()
	if choice < 0.43:
		_idle_kind = "wander"
		_idle_span = _rng.randf_range(1.0, 2.7)
	elif choice < 0.62:
		_idle_kind = "zigzag"
		_idle_span = _rng.randf_range(0.8, 1.65)
	elif choice < 0.79:
		_idle_kind = "hop"
		_idle_span = _rng.randf_range(0.75, 1.7)
	elif choice < 0.91:
		_idle_kind = "twirl"
		_idle_span = _rng.randf_range(0.82, 1.25)
	else:
		_idle_kind = "pause"
		_idle_span = _rng.randf_range(0.35, 1.15)
	var radius: float = maxf(16.0, _near_y - _far_y)
	var target_depth: float = _rng.randf_range(0.08, 0.69)
	# Side areas are Bubble's playground: the middle is the throw corridor.
	var left_side: bool = _rng.randf() < 0.50
	var x_fraction: float = _rng.randf_range(0.27, 0.36) if left_side else _rng.randf_range(0.64, 0.73)
	var x: float = size.x * x_fraction
	_idle_target = _clamp_play_position(Vector2(x, _near_y - radius * target_depth), 18.0)
	if _distance_to_segment(_idle_target, _throw_origin(), _guide_endpoint()) < 96.0 * clampf(size.y / 720.0, 0.65, 1.3):
		_idle_target = _safe_away_from_throw(_idle_target, _throw_origin(), _guide_endpoint(), 110.0 * clampf(size.y / 720.0, 0.65, 1.3))
	_idle_speed = _rng.randf_range(178.0, 245.0)
	_idle_twirl_sign = -1.0 if _rng.randf() < 0.5 else 1.0
	_idle_spin = 0.0
	var expressions: Array[String] = ["playful", "happy", "curious", "delighted", "excited", "proud", "content"]
	_bubble.set_room_emotion(expressions[_rng.randi_range(0, expressions.size() - 1)], _idle_span + 0.20)

func _move_bubble_towards(destination: Vector2, top_speed: float, dt: float) -> float:
	var target: Vector2 = _clamp_play_position(destination, 16.0)
	var delta_to: Vector2 = target - _pose
	var distance: float = delta_to.length()
	if distance < 2.0:
		_motion_energy = move_toward(_motion_energy, 0.0, dt * 5.0)
		_bubble.set_room_locomotion("idle", 0.0, 0.0)
		return distance
	# Ease the approach so Bubble does not mechanically stop on a frame.
	var speed: float = top_speed * clampf(distance / 80.0, 0.26, 1.0)
	var shift: Vector2 = delta_to.limit_length(speed * dt)
	_pose = _clamp_play_position(_pose + shift, 16.0)
	_motion_energy = move_toward(_motion_energy, clampf(speed / 420.0, 0.0, 1.0), dt * 4.0)
	var wanted_heading: float = clampf(delta_to.x / maxf(60.0, distance), -0.86, 0.86)
	_facing = lerp_angle(_facing, wanted_heading, minf(1.0, dt * 4.3))
	_bubble.set_room_heading(_facing)
	_bubble.set_room_locomotion("walk_forward", _motion_energy, shift.length(), wanted_heading - _facing)
	_bubble.set_room_turn_activity(clampf(absf(wanted_heading - _facing) * 0.70, 0.0, 1.0))
	return _pose.distance_to(target)

func _update_idle(dt: float) -> void:
	_idle_clock += dt
	if _idle_clock >= _idle_span:
		_choose_idle_action()
	if _idle_kind == "wander":
		_move_bubble_towards(_idle_target, _idle_speed, dt)
	elif _idle_kind == "zigzag":
		var wiggle: Vector2 = Vector2(sin(_time * 7.0) * 24.0, sin(_time * 4.1) * 15.0)
		_move_bubble_towards(_idle_target + wiggle, _idle_speed * 1.12, dt)
	elif _idle_kind == "hop":
		_move_bubble_towards(_idle_target, 148.0, dt)
	elif _idle_kind == "twirl":
		_motion_energy = move_toward(_motion_energy, 0.0, dt * 4.0)
		_bubble.set_room_locomotion("idle", 0.0, 0.0)
		_bubble.set_room_turn_activity(0.9)
		_idle_spin = _idle_twirl_sign * TAU * _softstep(_idle_clock / _idle_span)
	else:
		_motion_energy = move_toward(_motion_energy, 0.0, dt * 4.0)
		_bubble.set_room_locomotion("idle", 0.0, 0.0)
		_bubble.set_room_turn_activity(0.0)

func _build_fetch_mouth() -> void:
	# Dedicated toothless mouth + attached 3D ball. NEVER use ContinuousJawRig.
	# The regular smile remains untouched and reappears after the drop.
	var face: MikaBubbleFace = _bubble.get_face()
	if not is_instance_valid(face):
		return
	_fetch_mouth = Node2D.new()
	_fetch_mouth.name = "FetchMouth_WithBall_NO_TEETH"
	_fetch_mouth.visible = false
	face.add_child(_fetch_mouth)
	_fetch_round = Sprite2D.new()
	_fetch_round.name = "OriginalRoundMouth_O"
	_fetch_round.texture = ROUND_MOUTH_TEXTURE
	_fetch_round.centered = true
	_fetch_round.z_index = 0
	_fetch_mouth.add_child(_fetch_round)
	_fetch_socket = Marker2D.new()
	_fetch_socket.name = "MOUTH_BALL_SOCKET"
	_fetch_socket.position = Vector2(0.0, 2.0)
	_fetch_socket.z_index = 1
	_fetch_mouth.add_child(_fetch_socket)

func _closed_mouth_sprite() -> Sprite2D:
	var face: MikaBubbleFace = _bubble.get_face()
	if not is_instance_valid(face):
		return null
	return face.get_node_or_null("ClosedMouth") as Sprite2D

func _sync_fetch_mouth() -> void:
	if not is_instance_valid(_fetch_mouth):
		return
	var original: Sprite2D = _closed_mouth_sprite()
	if not is_instance_valid(original):
		return
	# Position, yaw projection and spring deformation are inherited from the
	# SAME rig that draws the ordinary mouth, not guessed screen coordinates.
	_fetch_mouth.position = original.position
	_fetch_mouth.rotation = original.rotation
	_fetch_mouth.scale = original.scale * 1.16
	_fetch_mouth.visible = _ball_in_mouth and cos(_facing) > 0.13
	# In carry state the drawn mouth is the single circular, no-teeth composite.
	if _ball_in_mouth:
		original.visible = false
	_mouth_point_marker.position = _mouth_point()

func _mouth_point() -> Vector2:
	# The marker is the true position of the closed-mouth anchor in FaceRig.
	var face: MikaBubbleFace = _bubble.get_face()
	var original: Sprite2D = _closed_mouth_sprite()
	if is_instance_valid(face) and is_instance_valid(original):
		return get_global_transform().affine_inverse() * face.to_global(original.position)
	return _bubble.position + Vector2(0.0, 25.0) * _perspective_scale(_pose.y)

func _set_ball_visual(where: Vector2, ground_y: float, size_fraction: float = 1.0) -> void:
	if _ball_in_mouth:
		return
	_ball.visible = true
	_ball.position = where
	_ball.scale = Vector2.ONE * _ball_base_scale * _perspective_scale(ground_y) * size_fraction

func _attach_ball_inside_mouth() -> void:
	if _ball_in_mouth or not is_instance_valid(_fetch_socket):
		return
	# Reuse the live 3D sphere, parented inside a separate round-mouth composite.
	# No teeth, no jaw cavity and no second Bubble renderer.
	_ball.reparent(_fetch_socket, false)
	_ball.position = Vector2.ZERO
	_ball.scale = Vector2.ONE * 0.80
	_ball.modulate.a = 1.0
	_ball.z_index = 0
	_ball_in_mouth = true
	_bubble.set_mouth_open(0.0)

func _release_ball_from_mouth() -> void:
	if not _ball_in_mouth:
		return
	# Capture the *actual* 3D ball transform inside the mouth BEFORE reparenting.
	# This guarantees neither its position nor size jumps on the release frame.
	var mouth_ball_transform: Transform2D = get_global_transform().affine_inverse() * _ball.get_global_transform()
	var world_point: Vector2 = mouth_ball_transform.origin
	var world_scale: Vector2 = mouth_ball_transform.get_scale()
	_ball.reparent(self, false)
	_ball_in_mouth = false
	_ball.position = world_point
	_ball.modulate.a = 1.0
	_ball.scale = world_scale
	# The mouth is in front at release: keep that drawing order continuously
	# until the next throw, including both bounces and the idle ball.
	_returned_ball_front = true
	_ball.z_index = 26 # Above Bubble (20), below all HUD buttons (70+).
	_drop_ball_from = world_point
	var normal_size: float = _ball_base_scale * _perspective_scale(_drop_ground_target.y)
	_drop_start_fraction = maxf(0.04, absf(world_scale.x) / maxf(0.001, normal_size))
	_bubble.set_mouth_open(0.0)
	_bubble.set_room_emotion("happy", 1.15)
	if is_instance_valid(_fetch_mouth):
		_fetch_mouth.visible = false

func _update_ball_layer() -> void:
	if _ball_in_mouth:
		return
	# Release is a continuous foreground event: the original proximity
	# check must NOT move a falling/bouncing ball behind Bubble.
	if _returned_ball_front:
		_ball.z_index = 26
		return
	# Ball goes behind the back-facing Bubble during pickup.
	if _state == "pickup":
		_ball.z_index = 18
		return
	# Ground footprint determines 2.5D overlap while airborne.
	var overlapping: bool = _ball.position.distance_to(_bubble.position) < 86.0 * clampf(size.y / 720.0, 0.65, 1.3)
	_ball.z_index = 18 if overlapping or _ball_ground.y < _pose.y + 12.0 else 22

func _mouth_to_body_offset() -> Vector2:
	# Dynamic, measured from the ACTUAL projected FaceRig mouth. The liquid
	# body deforms and the face rotates; a hardcoded 47px offset cannot work.
	return _mouth_point() - _pose

func _stance_for_mouth(target_mouth_point: Vector2, padding: float = 16.0) -> Vector2:
	# Root target is SOLVED from the live mouth socket, not from Bubble's center.
	return _clamp_play_position(target_mouth_point - _mouth_to_body_offset(), padding)

func _nudge_mouth_to(target_mouth_point: Vector2, dt: float, max_speed: float = 300.0) -> float:
	# Servo the WHOLE existing actor, never the ball, toward the two matching
	# markers. Runs every frame to absorb procedural bob and yaw projection.
	var error: Vector2 = target_mouth_point - _mouth_point()
	var correction: Vector2 = (error * minf(1.0, 8.0 * dt)).limit_length(max_speed * dt)
	var previous_pose: Vector2 = _pose
	_pose = _clamp_play_position(_pose + correction, 14.0)
	return (error - (_pose - previous_pose)).length()

func _rear_pickup_target() -> Vector2:
	# Approach with the back to camera, placing the INVISIBLE mouth projection
	# on the ground-ball center. This is not a fixed behind/above offset.
	return _stance_for_mouth(_ball_ground, 16.0)

func _start_pickup() -> void:
	_state = "pickup"
	_pickup_clock = 0.0
	_pickup_ball_from = _ball_ground
	_ball_pickup_start = _ball_ground
	_pickup_lean = 0.0
	_pickup_alignment_wait = 0.0
	_bubble.set_room_emotion("curious", 0.76)
	_bubble.set_mouth_open(0.0)
	_bubble.set_room_locomotion("idle", 0.0, 0.0)
	# The real FaceRig occludes eyes and mouth at yaw PI (back to camera).
	_facing = PI
	_bubble.set_room_heading(_facing)

func _start_returning() -> void:
	_attach_ball_inside_mouth()
	_state = "returning"
	_bubble.set_mouth_open(0.0)
	_bubble.set_room_emotion("proud", 1.5)
	# Gradual front-facing turn while moving back reveals the round carry mouth.
	_facing = PI
	_bubble.set_room_heading(_facing)

func _return_spot() -> Vector2:
	# Come STRAIGHT IN FRONT OF the original throw point. The ball must fall
	# vertically from the mouth, not slide diagonally back to the launch pad.
	var s: float = clampf(minf(size.x / 1280.0, size.y / 720.0), 0.60, 1.30)
	return _stance_for_mouth(_throw_origin() - Vector2(0.0, 40.0 * s), 16.0)

func _start_dropping() -> void:
	_state = "dropping"
	_drop_clock = 0.0
	_drop_lean = 0.0
	_drop_released = false
	_drop_alignment_wait = 0.0
	_drop_ground_target = _throw_origin()
	_bubble.set_mouth_open(0.0)
	_bubble.set_room_emotion("delighted", 1.1)
	# Do not snap the face to camera: the drop phase turns it smoothly.
	_bubble.set_room_heading(_facing)

func _finish_round() -> void:
	_state = "ready"
	_play_ball_sound("correct.ogg")
	_charging = false
	_strength = MIN_CHARGE
	_charge_elapsed = 0.0
	_meter.set("strength", _strength)
	_ball_ground = _drop_ground_target
	_set_ball_visual(_ball_ground, _ball_ground.y)
	_bubble.set_mouth_open(0.0)
	if is_instance_valid(_fetch_mouth):
		_fetch_mouth.visible = false
	_choose_idle_action()
	_throw_button.call("set_action_available", _shots_left > 0)

func _process(delta: float) -> void:
	if not is_instance_valid(_bubble) or not is_instance_valid(_ball):
		return
	var dt: float = minf(delta, 0.05)
	_time += dt
	_idle_spin = 0.0
	var bob_amplitude: float = 6.0
	if _state == "entering":
		_entry_time = minf(1.0, _entry_time + dt / 1.0)
		var easing: float = _softstep(_entry_time)
		var travel_to: Vector2 = _entry_start.lerp(_home, easing)
		var traveled: float = _pose.distance_to(travel_to)
		_pose = travel_to
		_motion_energy = 0.73
		_bubble.set_room_locomotion("walk_forward", 0.74, traveled)
		if _entry_time >= 1.0:
			_bubble.set_room_locomotion("idle", 0.0, 0.0)
			_state = "ready"
			_choose_idle_action()
	elif _state == "ready":
		if _input_enabled and _shots_left > 0:
			var pressed: bool = bool(_throw_button.get("_pressed_visual"))
			if pressed and not _charging:
				_charging = true
				_charge_elapsed = 0.0
				_strength = MIN_CHARGE
			if _charging and pressed:
				_charge_elapsed += dt
				var phase: float = fposmod(_charge_elapsed, CHARGE_HALF_CYCLE * 2.0) / CHARGE_HALF_CYCLE
				var charge_fraction: float = phase if phase <= 1.0 else 2.0 - phase
				_strength = lerpf(MIN_CHARGE, 1.0, charge_fraction)
			_meter.set("strength", _strength)
			_throw_button.call("set_action_available", true)
		_update_idle(dt)
		if _idle_kind == "hop":
			bob_amplitude = 16.0
		elif _idle_kind == "pause":
			bob_amplitude = 3.2
	elif _state == "clearing":
		# Hold the ball at the launch point while Bubble sidesteps its flight path.
		_clear_clock += dt
		var distance: float = _move_bubble_towards(_clear_target, 455.0, dt)
		_ball_ground = _flight_start
		_set_ball_visual(_flight_start, _flight_start.y)
		bob_amplitude = 12.0
		if distance < 20.0 or _clear_clock > 1.35:
			_launch_projectile()
	elif _state == "flying":
		_flight_clock = minf(_flight_duration, _flight_clock + dt)
		var t: float = clampf(_flight_clock / _flight_duration, 0.0, 1.0)
		_ball_ground = _flight_ground_point(t, _flight_start, _flight_end)
		_set_ball_visual(_flight_point(t, _flight_start, _flight_end, _locked_pitch), _ball_ground.y)
		# Bubble watches the flight from the side and ONLY chases after touchdown;
		# it cannot run through an airborne projectile.
		_motion_energy = move_toward(_motion_energy, 0.0, dt * 3.8)
		_bubble.set_room_locomotion("idle", 0.0, 0.0)
		bob_amplitude = 9.0
		if t >= 1.0:
			_state = "landed"
			_play_ball_sound("collision.ogg", true)
			_landing_clock = 0.0
			_pickup_side = -1.0 if _pose.x <= _ball_ground.x else 1.0
			_bubble.set_room_emotion("excited", 0.9)
	elif _state == "landed":
		_landing_clock += dt
		_ball_ground = _flight_end
		var tiny_bounce: float = 13.0 * maxf(0.0, sin(PI * minf(1.0, _landing_clock / 0.31))) * maxf(0.0, 1.0 - _landing_clock / 0.31)
		_set_ball_visual(_ball_ground - Vector2(0.0, tiny_bounce), _ball_ground.y)
		if _landing_clock >= 0.24:
			var catch_point: Vector2 = _rear_pickup_target()
			var distance: float = _move_bubble_towards(catch_point, 420.0, dt)
			# Turn toward the ball (away from the screen) while approaching.
			_facing = lerp_angle(_facing, PI, minf(1.0, dt * 5.2))
			_bubble.set_room_heading(_facing)
			# Settle the gait before the mouth-to-ball contact: no bob snap.
			bob_amplitude = 12.0 * clampf(distance / 75.0, 0.0, 1.0)
			if distance < 16.0:
				_start_pickup()
	elif _state == "pickup":
		_pickup_clock = minf(PICKUP_DURATION, _pickup_clock + dt)
		var t: float = clampf(_pickup_clock / PICKUP_DURATION, 0.0, 1.0)
		# Bend down and HOLD the bend while the physical mouth reaches the ball.
		# Only unbend after the same live 3D ball is attached to the socket.
		var bend_in: float = _softstep(t / 0.43)
		var bend_out: float = 1.0 - _softstep((t - 0.76) / 0.24)
		_pickup_lean = bend_in * bend_out
		_bubble.set_room_locomotion("idle", 0.0, 0.0)
		_facing = PI
		_bubble.set_room_heading(_facing)
		_bubble.set_mouth_open(0.0)
		bob_amplitude = 0.0
		# Bubble's center is steered until its real, projected mouth coincides
		# with the BALL_PICKUP_POINT marker. No screen-position jump is allowed.
		var mouth_error: float = _ball_pickup_start.distance_to(_mouth_point())
		if not _ball_in_mouth:
			mouth_error = _nudge_mouth_to(_ball_pickup_start, dt, 315.0)
		if t >= 0.66 and not _ball_in_mouth:
			_pickup_alignment_wait += dt
			if mouth_error <= MOUTH_PICKUP_TOLERANCE:
				_attach_ball_inside_mouth()
			else:
				# Hold the head down and keep aligning instead of attaching early.
				_pickup_clock = minf(_pickup_clock, PICKUP_DURATION * 0.71)
		if t >= 1.0 and _ball_in_mouth:
			_start_returning()
	elif _state == "returning":
		var remaining: float = _move_bubble_towards(_return_spot(), 370.0, dt)
		# Never open the tooth-bearing jaw: use only round mouth + carried sphere.
		_bubble.set_mouth_open(0.0)
		_ball_ground = _pose
		# Reduce running bounce continuously before the mouth goes to the drop point.
		bob_amplitude = 9.5 * clampf(remaining / 76.0, 0.0, 1.0)
		var return_mouth_goal: Vector2 = _throw_origin() - Vector2(0.0, 40.0 * clampf(minf(size.x / 1280.0, size.y / 720.0), 0.60, 1.30))
		if remaining < 18.0 and absf(_mouth_point().x - return_mouth_goal.x) < 24.0:
			_start_dropping()
	elif _state == "dropping":
		_drop_clock = minf(DROP_DURATION, _drop_clock + dt)
		var t: float = clampf(_drop_clock / DROP_DURATION, 0.0, 1.0)
		var bend_in: float = _softstep(t / 0.39)
		var bend_out: float = 1.0 - _softstep((t - 0.75) / 0.25)
		_drop_lean = bend_in * bend_out
		_bubble.set_room_locomotion("idle", 0.0, 0.0)
		_bubble.set_mouth_open(0.0)
		_facing = lerp_angle(_facing, 0.0, minf(1.0, dt * 8.0))
		_bubble.set_room_heading(_facing)
		bob_amplitude = 0.0
		var drop_goal: Vector2 = _drop_ground_target - Vector2(0.0, 24.0 * clampf(minf(size.x / 1280.0, size.y / 720.0), 0.60, 1.30))
		if not _drop_released:
			var mouth_error: float = _nudge_mouth_to(drop_goal, dt, 300.0)
			if t >= 0.43:
				_drop_alignment_wait += dt
				if mouth_error <= MOUTH_DROP_TOLERANCE:
					_release_ball_from_mouth()
					_drop_released = true
				else:
					# Hold near peak lean; never spit while the mouth is offset.
					_drop_clock = minf(_drop_clock, DROP_DURATION * 0.48)
		if _drop_released and not _ball_in_mouth:
			var drop_t: float = clampf((t - 0.43) / 0.57, 0.0, 1.0)
			_ball_ground = _drop_ground_target
			# The mouth is ALREADY directly above the target. Fall and two
			# damped hops happen on a VERTICAL LINE, with no backward roll.
			var fall_ratio: float = _softstep(drop_t / 0.35)
			var fall_point: Vector2 = Vector2(_drop_ball_from.x, lerpf(_drop_ball_from.y, _drop_ground_target.y, fall_ratio))
			var bounce_1: float = 21.0 * pow(maxf(0.0, sin(PI * clampf((drop_t - 0.35) / 0.36, 0.0, 1.0))), 2.0)
			var bounce_2: float = 9.0 * pow(maxf(0.0, sin(PI * clampf((drop_t - 0.71) / 0.29, 0.0, 1.0))), 2.0)
			fall_point.y -= (bounce_1 + bounce_2) * _perspective_scale(_drop_ground_target.y)
			_set_ball_visual(fall_point, _drop_ground_target.y, lerpf(_drop_start_fraction, 1.0, _softstep(drop_t)))
		if t >= 1.0 and _drop_released:
			_finish_round()
	# Preserve one procedural body and face throughout; no play_action swaps.
	var perspective: float = _perspective_scale(_pose.y)
	var bounce: float = absf(sin(_time * (8.8 if _motion_energy > 0.2 else 5.8))) * bob_amplitude
	var side_lean: float = _pickup_lean if _state == "pickup" else (_drop_lean if _state == "dropping" else 0.0)
	# Collect from behind; no sideways head teleport or painted side-mouth.
	var lean_shift: Vector2 = Vector2(0.0, 12.0 * side_lean) * perspective
	_bubble.position = _pose + lean_shift + Vector2(0.0, -bounce * perspective)
	_bubble.rotation = _idle_spin + sin(_time * 4.3) * 0.025 * (0.45 + _motion_energy) + 0.035 * side_lean
	_bubble.scale = Vector2(1.0 + 0.045 * side_lean, 1.0 - 0.135 * side_lean) * _bubble_base_scale * perspective
	# Bring the physical sphere behind the body and reduce it to carry size
	# while the back is facing us; it appears in the round mouth on the turn.
	if _state == "pickup" and not _ball_in_mouth:
		_ball_ground = _ball_pickup_start
		# The ground ball DOES NOT slide toward the face. The live mouth is
		# brought to the stationary ball, then they join behind Bubble's back.
		_set_ball_visual(_ball_pickup_start, _ball_pickup_start.y)
		_ball.modulate.a = 1.0
	_sync_fetch_mouth()
	_ball_ground_marker.position = _ball_pickup_start if _state == "pickup" else _ball_ground
	_drop_ground_marker.position = _throw_origin()
	_update_ball_layer()
	# Eyes follow the projectile naturally, even during idle anticipation.
	var face: MikaBubbleFace = _bubble.get_face()
	if is_instance_valid(face):
		var look: Vector2 = (_ball.position - _bubble.position) / maxf(80.0, size.x * 0.12)
		face.set_gaze(look.clamp(Vector2(-0.9, -0.65), Vector2(0.9, 0.55)))
	queue_redraw()

func _draw() -> void:
	if size.x < 100.0 or _allowed.size.x <= 0.0:
		return
	var ui_scale: float = clampf(minf(size.x / 1280.0, size.y / 720.0), 0.60, 1.30)
	# Five shots on the upper right; spent shots turn into dark inactive orbs.
	var strip_base: Vector2 = Vector2(size.x - 32.0 * ui_scale - 140.0 * ui_scale, 65.0 * ui_scale)
	for i in range(MAX_SHOTS):
		var c: Vector2 = strip_base + Vector2(float(i) * 33.0 * ui_scale, 0.0)
		var r: float = 9.5 * ui_scale
		draw_circle(c, r + 3.0 * ui_scale, Color(0.20, 0.72, 1.0, 0.12))
		draw_circle(c, r, Color("3fc7ee") if i < _shots_left else Color(0.13, 0.23, 0.34, 0.69))
		draw_arc(c, r, 0.0, TAU, 28, Color("c7faff") if i < _shots_left else Color(0.27, 0.45, 0.57, 0.42), 1.4 * ui_scale, true)
	# Dots only, NO arrowhead. Full-length trajectory is unaffected by charge;
	# the right stick changes horizontal bearing and arc height.
	if _state == "ready" and _shots_left > 0:
		var origin: Vector2 = _throw_origin()
		var endpoint: Vector2 = _guide_endpoint()
		var pitch: float = _pitch()
		var points: int = 36
		for i in range(1, points + 1):
			var t: float = float(i) / float(points)
			var dot: Vector2 = _flight_point(t, origin, endpoint, pitch)
			draw_circle(dot, (2.9 - 0.95 * t) * ui_scale, Color(0.39, 0.89, 1.0, 0.68 * (1.0 - 0.40 * t)))

func _request_exit() -> void:
	if _input_enabled:
		exit_requested.emit()

func _unhandled_key_input(event: InputEvent) -> void:
	if _input_enabled and event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_ESCAPE:
		exit_requested.emit()
		get_viewport().set_input_as_handled()
