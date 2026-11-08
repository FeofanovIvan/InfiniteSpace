extends Sprite2D
@export var speed: float = 250.0
@export var spawn_x: float = 323.0
@export var spawn_y: float = 18.0
@export var angle_deg: float = 40.0
@export var end_y: float = 450.0
@export var respawn_delay: float = 0.8
var world_paused := false
var world_speed_multiplier := 1.0
var dir: Vector2
var active := false
var respawn_timer: Timer
func _ready() -> void:
	dir = Vector2.RIGHT.rotated(deg_to_rad(angle_deg)).normalized()
	visible = false
	active = false
	respawn_timer = Timer.new()
	respawn_timer.one_shot = true
	respawn_timer.wait_time = respawn_delay
	add_child(respawn_timer)
	respawn_timer.timeout.connect(_on_respawn)
	respawn_timer.start()
func set_world_paused(value: bool) -> void:
	world_paused = value
	if respawn_timer:
		respawn_timer.paused = value
func set_world_speed_multiplier(value: float) -> void:
	world_speed_multiplier = value
func _process(delta: float) -> void:
	if world_paused or not active:
		return
	position += dir * speed * world_speed_multiplier * delta
	if position.y >= end_y:
		_start_respawn()
func _start_respawn() -> void:
	active = false
	visible = false
	respawn_timer.start()
func _on_respawn() -> void:
	position = Vector2(spawn_x, spawn_y)
	visible = true
	active = true
