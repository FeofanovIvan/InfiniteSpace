extends Control
@export var spawn_interval: float = 3.0
@export var puddle_speed_multiplier: float = 0.2
var obstacles: Array = []
var timer: Timer
var road_paused := false
var speed_multiplier := 1.0
func _ready() -> void:
	for child in get_children():
		if child.has_method("activate"):
			obstacles.append(child)
	timer = Timer.new()
	timer.wait_time = spawn_interval
	timer.one_shot = false
	timer.autostart = true
	add_child(timer)
	timer.timeout.connect(_spawn_random)
func _spawn_random() -> void:
	if road_paused:
		return
	if obstacles.is_empty():
		return
	for i in range(5):
		var obj = obstacles.pick_random()
		if not obj.active:
			obj.activate()
			return
func pause_road() -> void:
	if road_paused:
		return
	road_paused = true
	if timer:
		timer.paused = true
	for obj in obstacles:
		if obj.has_method("set_road_paused"):
			obj.set_road_paused(true)
func resume_road() -> void:
	if not road_paused:
		return
	road_paused = false
	if timer:
		timer.paused = false
	for obj in obstacles:
		if obj.has_method("set_road_paused"):
			obj.set_road_paused(false)
func slow_road() -> void:
	speed_multiplier = puddle_speed_multiplier
	_apply_speed_multiplier()
func restore_road_speed() -> void:
	speed_multiplier = 1.0
	_apply_speed_multiplier()
func _apply_speed_multiplier() -> void:
	for obj in obstacles:
		if obj.has_method("set_speed_multiplier"):
			obj.set_speed_multiplier(speed_multiplier)
