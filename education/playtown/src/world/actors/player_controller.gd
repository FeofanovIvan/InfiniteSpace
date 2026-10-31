extends CharacterBody2D
const SPEED = 100
const WORLD_ACTOR_Z := 20
@onready var sprite = $AnimatedSprite2D
var extra_direction := Vector2.ZERO
var wait_for_input_release := false
func _ready() -> void:
	add_to_group("player")
	z_index = WORLD_ACTOR_Z
	var frames_path: String = GameState.character_frames_path()
	if ResourceLoader.exists(frames_path):
		sprite.sprite_frames = load(frames_path)
func _physics_process(delta):
	if wait_for_input_release:
		velocity = Vector2.ZERO
		sprite.stop()
		if not _has_movement_input():
			wait_for_input_release = false
		return
	var direction = Vector2.ZERO
	if Input.is_action_pressed("ui_right"):
		direction.x += 1
	if Input.is_action_pressed("ui_left"):
		direction.x -= 1
	if Input.is_action_pressed("ui_down"):
		direction.y += 1
	if Input.is_action_pressed("ui_up"):
		direction.y -= 1
	direction += extra_direction
	if direction != Vector2.ZERO:
		if direction.length() > 1.0:
			direction = direction.normalized()
		velocity = direction * SPEED
		move_and_slide()
		if abs(direction.x) > abs(direction.y):
			sprite.play("walk_right" if direction.x > 0 else "walk_left")
		else:
			sprite.play("walk_down" if direction.y > 0 else "walk_up")
	else:
		velocity = Vector2.ZERO
		sprite.stop()

func stop_movement_until_released() -> void:
	extra_direction = Vector2.ZERO
	velocity = Vector2.ZERO
	sprite.stop()
	wait_for_input_release = true

func _has_movement_input() -> bool:
	return Input.is_action_pressed("ui_right") \
		or Input.is_action_pressed("ui_left") \
		or Input.is_action_pressed("ui_down") \
		or Input.is_action_pressed("ui_up") \
		or extra_direction != Vector2.ZERO
