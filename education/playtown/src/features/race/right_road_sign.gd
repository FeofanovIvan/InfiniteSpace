extends Sprite2D
signal finished(obj)
@export var speed: float = 250.0
@export var spawn_x: float = 104.0
@export var spawn_y: float = -57.0
@export var angle_deg: float = 37.0
@export var end_y: float = 650.0
@export var start_scale: float = 0.3
@export var end_scale: float = 1.4
@export_enum("left", "right", "center") var side: String = "center"
var dir: Vector2
var active := false
var road_paused := false
var speed_multiplier := 1.0
func _ready() -> void:
	visible = false
	active = false
	road_paused = false
	speed_multiplier = 1.0
	dir = Vector2.RIGHT.rotated(deg_to_rad(angle_deg)).normalized()
	_reset_to_spawn()
func activate() -> void:
	_reset_to_spawn()
	visible = true
	active = true
func deactivate() -> void:
	visible = false
	active = false
func set_road_paused(value: bool) -> void:
	road_paused = value
func set_speed_multiplier(value: float) -> void:
	speed_multiplier = value
func _process(delta: float) -> void:
	if road_paused:
		return
	if not active:
		return
	position += dir * speed * speed_multiplier * delta
	var t := inverse_lerp(spawn_y, end_y, position.y)
	scale = Vector2.ONE * lerp(start_scale, end_scale, t)
	if position.y >= end_y:
		deactivate()
		finished.emit(self)
func _reset_to_spawn() -> void:
	position = Vector2(spawn_x, spawn_y)
	scale = Vector2.ONE * start_scale
