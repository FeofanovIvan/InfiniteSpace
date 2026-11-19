extends "res://simulator_ui/menu/mika_free_world_more_games_v1.gd"
## Keeps the route smoke deterministic without reading or changing the player's
## persistent user://miko_mode.cfg selection.


func _mika_read_mode() -> String:
	return "free_world"
