class_name HouseSearchPlayer
extends CharacterBody2D

@export var speed := 225.0
@export var floor_left := 65.0
@export var floor_right := 1470.0

var floor_y := 725.0
var touch_direction := Vector2.ZERO
var input_enabled := true

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D


func _ready() -> void:
	add_to_group("house_search_player")


func _physics_process(delta: float) -> void:
	if not input_enabled:
		velocity = Vector2.ZERO
		return
	var requested := Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down") + touch_direction
	var horizontal := signf(requested.x)
	velocity = Vector2(horizontal * speed, 0.0)
	position.x = clampf(position.x + velocity.x * delta, floor_left, floor_right)
	position.y = floor_y
	if horizontal != 0.0:
		animated_sprite.play("walk_right" if horizontal > 0.0 else "walk_left")
	elif absf(requested.y) > 0.01:
		face(Vector2.DOWN if requested.y > 0.0 else Vector2.UP)
	else:
		animated_sprite.pause()
		animated_sprite.frame = 0


func set_touch_direction(direction: Vector2) -> void:
	touch_direction = direction


func clear_touch_direction() -> void:
	touch_direction = Vector2.ZERO


func face(direction: Vector2) -> void:
	if absf(direction.x) > absf(direction.y):
		animated_sprite.animation = "walk_right" if direction.x > 0.0 else "walk_left"
	else:
		animated_sprite.animation = "walk_down" if direction.y > 0.0 else "walk_up"
	animated_sprite.pause()
	animated_sprite.frame = 0


func play_walk(direction: Vector2) -> void:
	if absf(direction.x) > absf(direction.y):
		animated_sprite.play("walk_right" if direction.x > 0.0 else "walk_left")
	else:
		animated_sprite.play("walk_down" if direction.y > 0.0 else "walk_up")


func set_floor(floor_number: int, x_position := -1.0) -> void:
	floor_y = 725.0 if floor_number == 1 else 397.0
	if x_position >= 0.0:
		position.x = x_position
	position.y = floor_y
