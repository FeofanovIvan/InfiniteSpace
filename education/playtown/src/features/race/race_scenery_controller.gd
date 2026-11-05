extends Control
@export var puddle_speed_multiplier: float = 0.2
var world_paused := false
var speed_multiplier := 1.0
func pause_world() -> void:
	if world_paused:
		return
	world_paused = true
	_apply_pause(true)
func resume_world() -> void:
	if not world_paused:
		return
	world_paused = false
	_apply_pause(false)
func slow_world() -> void:
	speed_multiplier = puddle_speed_multiplier
	_apply_speed_multiplier(speed_multiplier)
func restore_world_speed() -> void:
	speed_multiplier = 1.0
	_apply_speed_multiplier(speed_multiplier)
func _apply_pause(value: bool) -> void:
	for child in get_children():
		if child.has_method("set_world_paused"):
			child.set_world_paused(value)
func _apply_speed_multiplier(value: float) -> void:
	for child in get_children():
		if child.has_method("set_world_speed_multiplier"):
			child.set_world_speed_multiplier(value)
