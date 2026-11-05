extends CharacterBody2D
@export var speed: float = 130.0
@export var follow_distance: float = 90.0
@export var stop_distance: float = 55.0
@export var teleport_distance: float = 500.0
const FRAMES_PATH := "res://education/playtown/assets/pet/pet_frames.tres"
const SPAWN_OFFSET := Vector2(-40.0, 24.0)
const LAYER_EPSILON := 2.0
@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
var target: Node = null
var chasing: bool = false
func _ready() -> void:
	if not GameState.has_pet_access():
		queue_free()
		return
	AccessService.preview_pet_access_changed.connect(_on_preview_pet_access_changed)
	add_to_group("pet")
	if ResourceLoader.exists(FRAMES_PATH):
		sprite.sprite_frames = load(FRAMES_PATH)
	call_deferred("_find_target")
func _on_preview_pet_access_changed(_available: bool) -> void:
	if not GameState.has_pet_access():
		queue_free()
func _find_target() -> void:
	var found := get_tree().get_first_node_in_group("player")
	if found and target == null:
		target = found
		global_position = target.global_position + SPAWN_OFFSET
	else:
		target = found
	_update_render_order()
func _physics_process(_delta: float) -> void:
	if target == null or not is_instance_valid(target):
		_find_target()
		return
	_update_render_order()
	var to_player: Vector2 = target.global_position - global_position
	var dist: float = to_player.length()
	if dist > teleport_distance:
		global_position = target.global_position + SPAWN_OFFSET
		velocity = Vector2.ZERO
		chasing = false
		sprite.stop()
		return
	if dist > follow_distance:
		chasing = true
	elif dist < stop_distance:
		chasing = false
	if chasing and dist > 4.0:
		var direction := to_player.normalized()
		velocity = direction * speed
		move_and_slide()
		if abs(direction.x) > abs(direction.y):
			sprite.play("walk_right" if direction.x > 0 else "walk_left")
		else:
			sprite.play("walk_down" if direction.y > 0 else "walk_up")
	else:
		velocity = Vector2.ZERO
		move_and_slide()
		sprite.stop()
	_update_render_order()
func _update_render_order() -> void:
	if target == null or not is_instance_valid(target):
		return
	var target_sprite := target.get_node_or_null("AnimatedSprite2D") as AnimatedSprite2D
	var pet_feet_y := _sprite_bottom_y(sprite)
	var target_feet_y := _sprite_bottom_y(target_sprite)
	var target_layer: int = target.z_index
	if pet_feet_y > target_feet_y + LAYER_EPSILON:
		z_index = target_layer + 1
	else:
		z_index = target_layer - 1
func _sprite_bottom_y(animated_sprite: AnimatedSprite2D) -> float:
	if animated_sprite == null or animated_sprite.sprite_frames == null:
		return global_position.y
	var texture := animated_sprite.sprite_frames.get_frame_texture(
		animated_sprite.animation,
		animated_sprite.frame
	)
	if texture == null:
		return animated_sprite.global_position.y
	return animated_sprite.global_position.y + texture.get_height() * absf(animated_sprite.global_scale.y) * 0.5
