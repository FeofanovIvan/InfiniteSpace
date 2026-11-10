extends CharacterBody2D
@export var car_texture: Texture2D
@export var direction: Vector2 = Vector2.DOWN
@export var speed: float = 120.0
@export var wrap_min: float = -100000.0
@export var wrap_max: float = 100000.0
@export var speed_variance: float = 0.15
@export var wrap_jitter: float = 260.0
@export var start_jitter: float = 160.0
@export var gap_jitter: float = 50.0
@export var stuck_recycle_time: float = 10.0
var can_move: bool = true
var can_move_axis: bool = true
var base_speed: float
var blocked_time: float = 0.0
@onready var sprite: Sprite2D = $Sprite2D
@onready var front_sensor: Area2D = $FrontSensor
@onready var front_shape: CollisionShape2D = $FrontSensor/CollisionShape2D
@onready var engine_sound: AudioStreamPlayer = $EngineSound
func _ready() -> void:
	add_to_group("cars")
	direction = direction.normalized()
	rotation = direction.angle() - PI / 2.0
	base_speed = speed
	speed = base_speed * randf_range(1.0 - speed_variance, 1.0 + speed_variance)
	position += direction * randf_range(-start_jitter, start_jitter)
	if front_shape:
		front_shape.position += direction * randf_range(0.0, gap_jitter)
	if car_texture:
		sprite.texture = car_texture
	engine_sound.play()
	engine_sound.pitch_scale = randf_range(0.95, 1.05)
func _physics_process(delta: float) -> void:
	var allowed_to_move := can_move and can_move_axis
	var obstacle := _obstacle_ahead() if allowed_to_move else null
	var moving: bool = allowed_to_move and obstacle == null
	if allowed_to_move and obstacle != null:
		blocked_time += delta
		if blocked_time >= stuck_recycle_time:
			force_recycle()
			obstacle = null
	else:
		blocked_time = 0.0
	if moving:
		position += direction * speed * delta
	_update_engine_sound(moving, delta)
	_wrap()
func _wrap() -> void:
	var wrapped := false
	if absf(direction.x) > absf(direction.y):
		if direction.x > 0.0 and position.x > wrap_max:
			position.x = _find_safe_wrap_coord(wrap_min - randf_range(0.0, wrap_jitter), true)
			wrapped = true
		elif direction.x < 0.0 and position.x < wrap_min:
			position.x = _find_safe_wrap_coord(wrap_max + randf_range(0.0, wrap_jitter), true)
			wrapped = true
	else:
		if direction.y > 0.0 and position.y > wrap_max:
			position.y = _find_safe_wrap_coord(wrap_min - randf_range(0.0, wrap_jitter), false)
			wrapped = true
		elif direction.y < 0.0 and position.y < wrap_min:
			position.y = _find_safe_wrap_coord(wrap_max + randf_range(0.0, wrap_jitter), false)
			wrapped = true
	if wrapped:
		_reset_after_recycle()
func force_recycle() -> void:
	var is_x := absf(direction.x) > absf(direction.y)
	if is_x:
		var candidate_x := wrap_min - randf_range(0.0, wrap_jitter) if direction.x > 0.0 else wrap_max + randf_range(0.0, wrap_jitter)
		position.x = _find_safe_wrap_coord(candidate_x, true)
	else:
		var candidate_y := wrap_min - randf_range(0.0, wrap_jitter) if direction.y > 0.0 else wrap_max + randf_range(0.0, wrap_jitter)
		position.y = _find_safe_wrap_coord(candidate_y, false)
	_reset_after_recycle()
func _reset_after_recycle() -> void:
	can_move = true
	can_move_axis = true
	blocked_time = 0.0
	speed = base_speed * randf_range(1.0 - speed_variance, 1.0 + speed_variance)
	engine_sound.volume_db = -30.0
	engine_sound.pitch_scale = 0.8
const WRAP_SAFE_GAP := 220.0
const WRAP_SAFE_MAX_ATTEMPTS := 6
func _find_safe_wrap_coord(candidate: float, is_x: bool) -> float:
	var moving_axis_sign: float = (direction.x if is_x else direction.y)
	var step: float = -sign(moving_axis_sign) * WRAP_SAFE_GAP
	var attempts := 0
	while attempts < WRAP_SAFE_MAX_ATTEMPTS and _lane_blocked(candidate, is_x):
		candidate += step
		attempts += 1
	return candidate
func _lane_blocked(candidate: float, is_x: bool) -> bool:
	for other in get_tree().get_nodes_in_group("cars"):
		if other == self:
			continue
		var same_lane: bool
		var other_moving_coord: float
		if is_x:
			same_lane = absf(other.position.y - position.y) < 5.0
			other_moving_coord = other.position.x
		else:
			same_lane = absf(other.position.x - position.x) < 5.0
			other_moving_coord = other.position.y
		if not same_lane:
			continue
		if absf(other_moving_coord - candidate) < WRAP_SAFE_GAP:
			return true
	return false
func _obstacle_ahead() -> Node:
	if front_sensor == null:
		return null
	for body in front_sensor.get_overlapping_bodies():
		if body == self:
			continue
		if body.is_in_group("cars"):
			if "direction" in body:
				var other_direction: Vector2 = body.direction.normalized()
				if absf(direction.dot(other_direction)) < 0.75:
					continue
			return body
		if body.is_in_group("player") or body.is_in_group("pet"):
			return body
	return null
func _update_engine_sound(moving: bool, delta: float) -> void:
	var player := get_tree().get_first_node_in_group("player")
	if player == null:
		return
	var distance := global_position.distance_to(player.global_position)
	var max_hear_distance := 400.0
	var target_volume := -40.0
	var target_pitch := 0.8
	if moving and distance <= max_hear_distance:
		var t := 1.0 - (distance / max_hear_distance)
		target_volume = lerp(-30.0, 0.0, t)
		target_pitch = 1.0
	engine_sound.volume_db = lerp(engine_sound.volume_db, target_volume, delta * 6.0)
	engine_sound.pitch_scale = lerp(engine_sound.pitch_scale, target_pitch, delta * 2.0)
func set_can_move(value: bool) -> void:
	can_move = value
func set_axis_can_move(value: bool) -> void:
	can_move_axis = value
