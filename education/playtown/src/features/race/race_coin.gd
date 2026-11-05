extends Sprite2D
signal finished(obj)
@export var speed: float = 250.0
@export var spawn_x: float = 0.0
@export var spawn_y: float = 0.0
@export var angle_deg: float = 90.0
@export var end_y: float = 650.0
@export var start_scale: float = 0.3
@export var end_scale: float = 1.0
@export_enum("left", "right", "center") var side: String = "center"
@export var spin_anim_name: String = "spin"
@onready var anim: AnimatedSprite2D = $AnimatedSprite2D
@onready var area2d: Area2D = $Area2D
var dir: Vector2
var active := false
var road_paused := false
var speed_multiplier := 1.0
var collected := false
func _ready() -> void:
	visible = false
	active = false
	collected = false
	road_paused = false
	speed_multiplier = 1.0
	dir = Vector2.RIGHT.rotated(deg_to_rad(angle_deg)).normalized()
	_reset_to_spawn()
	if anim:
		anim.stop()
	_set_collision_enabled(false)
func activate() -> void:
	collected = false
	_reset_to_spawn()
	visible = true
	active = true
	_set_collision_enabled(true)
	if anim:
		anim.play(spin_anim_name)
func deactivate() -> void:
	visible = false
	active = false
	if anim:
		anim.stop()
	_set_collision_enabled(false)
func collect() -> void:
	if collected:
		return
	collected = true
	deactivate()
	finished.emit(self)
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
func _set_collision_enabled(enabled: bool) -> void:
	if area2d == null:
		return
	area2d.set_deferred("monitoring", enabled)
	area2d.set_deferred("monitorable", enabled)
