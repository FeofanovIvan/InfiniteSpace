extends Control
@onready var arrow: TextureRect = $Arrow
@onready var nav_panel = get_node("/root/Main/CanvasLayer/TopUI/NavPanel")
@onready var player_shape = get_node("/root/Main/Player/CollisionShape2D")
func _process(delta):
	var camera := get_viewport().get_camera_2d()
	if camera == null:
		return
	if nav_panel == null:
		return
	if player_shape == null:
		return
	var target_world_position = nav_panel.get_current_target_position()
	if target_world_position == null:
		return
	var player_pos: Vector2 = player_shape.get_global_transform().origin
	var direction = (target_world_position - player_pos).normalized()
	arrow.rotation = direction.angle()
