extends CharacterBody2D
signal obstacle_state_changed(in_obstacle: bool)
signal puddle_state_changed(in_puddle: bool)
signal coin_collected(total: int)
@export var speed_x: float = 450.0
@export var player_control_path: NodePath
@export var road_path: NodePath = NodePath("../road")
@export var world_path: NodePath = NodePath("../World")
@export var coin_sound: AudioStream = preload("res://education/playtown/audio/sfx/coin.ogg")
@export var collision_sound: AudioStream = preload("res://education/playtown/audio/sfx/collision.ogg")
@onready var anim: AnimatedSprite2D = $AnimatedSprite2D
@onready var hit_area: Area2D = get_node_or_null("Area2D")
@onready var road: Node = get_node_or_null(road_path)
@onready var world: Node = get_node_or_null(world_path)
@onready var player_control: Control = get_node_or_null(player_control_path)
var input_x: float = 0.0
var in_obstacle_area: bool = false
var in_puddle_area: bool = false
var coins: int = 0
var can_play_collision := true
func _ready() -> void:
	_apply_selected_character_frames()
	if hit_area == null:
		return
	if player_control == null:
		return
	hit_area.area_entered.connect(_on_area_entered)
	hit_area.area_exited.connect(_on_area_exited)
	_play_up()
func set_input_x(x: float) -> void:
	input_x = clamp(x, -1.0, 1.0)
func _process(delta: float) -> void:
	var keyboard_x := Input.get_axis("ui_left", "ui_right")
	var effective_x := input_x if abs(input_x) > 0.001 else keyboard_x
	if in_obstacle_area:
		anim.stop()
		if abs(effective_x) <= 0.2:
			return
	if abs(effective_x) > 0.001:
		position.x += effective_x * speed_x * delta
		var bounds := _get_x_bounds_from_control()
		position.x = clamp(position.x, bounds.x, bounds.y)
		if effective_x < 0:
			_play_left()
		else:
			_play_right()
	else:
		_play_up()
func _get_x_bounds_from_control() -> Vector2:
	if player_control == null:
		return Vector2(-INF, INF)
	var rect: Rect2 = player_control.get_global_rect()
	var range: float = rect.size.x * 0.4
	var min_x: float = -range
	var max_x: float = range
	return Vector2(min_x, max_x)
func _on_area_entered(area: Area2D) -> void:
	if area.is_in_group("coin"):
		var coin_node := area.get_parent()
		if coin_node and coin_node.has_method("collect"):
			coin_node.collect()
		coins += 1
		coin_collected.emit(coins)
		if coin_sound:
			SFX.play_2d(coin_sound, global_position, -8)
		return
	if area.is_in_group("puddle"):
		if in_puddle_area:
			return
		in_puddle_area = true
		if road and road.has_method("slow_road"):
			road.slow_road()
		if world and world.has_method("slow_world"):
			world.slow_world()
		puddle_state_changed.emit(true)
		return
	if area.is_in_group("obstacle"):
		if in_obstacle_area:
			return
		in_obstacle_area = true
		anim.stop()
		if collision_sound and can_play_collision:
			can_play_collision = false
			SFX.play_2d(collision_sound, global_position, -4)
			_reset_collision_cooldown()
		if road and road.has_method("pause_road"):
			road.pause_road()
		if world and world.has_method("pause_world"):
			world.pause_world()
		obstacle_state_changed.emit(true)
		return
func _on_area_exited(area: Area2D) -> void:
	if area.is_in_group("puddle"):
		if not in_puddle_area:
			return
		in_puddle_area = false
		if road and road.has_method("restore_road_speed"):
			road.restore_road_speed()
		if world and world.has_method("restore_world_speed"):
			world.restore_world_speed()
		puddle_state_changed.emit(false)
		return
	if area.is_in_group("obstacle"):
		if not in_obstacle_area:
			return
		in_obstacle_area = false
		_play_up()
		if road and road.has_method("resume_road"):
			road.resume_road()
		if world and world.has_method("resume_world"):
			world.resume_world()
		obstacle_state_changed.emit(false)
		return
func _reset_collision_cooldown() -> void:
	await get_tree().create_timer(0.3).timeout
	can_play_collision = true
func _play_up() -> void:
	if anim.animation != "move_up" or not anim.is_playing():
		anim.play("move_up")
func _play_left() -> void:
	if anim.animation != "move_left" or not anim.is_playing():
		anim.play("move_left")
func _play_right() -> void:
	if anim.animation != "move_right" or not anim.is_playing():
		anim.play("move_right")
func _apply_selected_character_frames() -> void:
	var selected := "girl"
	if GameState != null and GameState.selected_character in ["girl", "boy"]:
		selected = GameState.selected_character
	var frame_paths: Dictionary
	if selected == "boy":
		frame_paths = {
			"up": [
				"res://education/playtown/assets/characters/boy_race/boy_up_1.png",
				"res://education/playtown/assets/characters/boy_race/boy_up_2.png"
			],
			"left": ["res://education/playtown/assets/characters/boy_race/boy_left.png"],
			"right": ["res://education/playtown/assets/characters/boy_race/boy_right.png"]
		}
	else:
		frame_paths = {
			"up": [
				"res://education/playtown/assets/characters/girl_race/girl_up_1.png",
				"res://education/playtown/assets/characters/girl_race/girl_up_2.png"
			],
			"left": ["res://education/playtown/assets/characters/girl_race/girl_left.png"],
			"right": ["res://education/playtown/assets/characters/girl_race/girl_right.png"]
		}
	var frames := SpriteFrames.new()
	frames.remove_animation(&"default")
	_add_animation(frames, &"move_up", frame_paths["up"], 5.0)
	_add_animation(frames, &"move_left", frame_paths["left"], 5.0)
	_add_animation(frames, &"move_right", frame_paths["right"], 5.0)
	anim.sprite_frames = frames
	anim.animation = &"move_up"
func _add_animation(
	frames: SpriteFrames,
	animation_name: StringName,
	texture_paths: Array,
	fps: float
) -> void:
	frames.add_animation(animation_name)
	frames.set_animation_loop(animation_name, true)
	frames.set_animation_speed(animation_name, fps)
	for texture_path in texture_paths:
		var texture := load(str(texture_path)) as Texture2D
		if texture != null:
			frames.add_frame(animation_name, texture)
