extends Sprite2D
@export var speed: float = 250.0
@export var spawn_x: float = -357.0
@export var spawn_y: float = 9.0
@export var angle_deg: float = 135.0
@export var end_y: float = 450.0
var world_paused := false
var world_speed_multiplier := 1.0
var dir: Vector2
func _ready() -> void:
	position = Vector2(spawn_x, spawn_y)
	dir = Vector2.RIGHT.rotated(deg_to_rad(angle_deg)).normalized()
func set_world_paused(value: bool) -> void:
	world_paused = value
func set_world_speed_multiplier(value: float) -> void:
	world_speed_multiplier = value
func _process(delta: float) -> void:
	if world_paused:
		return
	position += dir * speed * world_speed_multiplier * delta
	if position.y >= end_y:
		position = Vector2(spawn_x, spawn_y)
