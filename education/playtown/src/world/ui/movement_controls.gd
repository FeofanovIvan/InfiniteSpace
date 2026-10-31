extends Control

const JoystickScript := preload("res://education/playtown/src/ui/child_joystick.gd")

var player: CharacterBody2D
var joystick: ChildJoystick


func _ready() -> void:
	player = get_tree().get_first_node_in_group("player") as CharacterBody2D
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	for child in get_children():
		child.visible = false
	joystick = JoystickScript.new() as ChildJoystick
	joystick.name = "ChildJoystick"
	joystick.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	joystick.z_index = 100
	joystick.direction_changed.connect(_on_direction_changed)
	add_child(joystick)
	get_viewport().size_changed.connect(_layout)
	resized.connect(_layout)
	call_deferred("_layout")


func _exit_tree() -> void:
	if is_instance_valid(player):
		player.set("extra_direction", Vector2.ZERO)


func _layout() -> void:
	if joystick == null:
		return
	# TopUI is already reduced to the platform safe area by world_hud.gd.
	# Positioning from the full viewport applied that inset twice on phones with
	# a left-side cutout/navigation area, pushing the joystick past the right
	# edge. Anchor it to this actual safe container instead.
	var available := size
	if available.x <= 1.0 or available.y <= 1.0:
		call_deferred("_layout")
		return
	var side := clampf(minf(available.x, available.y) * 0.245, 150.0, 218.0)
	var right_margin := maxf(20.0, side * 0.11)
	var bottom_margin := maxf(18.0, side * 0.10)
	joystick.anchor_left = 1.0
	joystick.anchor_top = 1.0
	joystick.anchor_right = 1.0
	joystick.anchor_bottom = 1.0
	joystick.offset_left = -right_margin - side
	joystick.offset_top = -bottom_margin - side
	joystick.offset_right = -right_margin
	joystick.offset_bottom = -bottom_margin


func _on_direction_changed(direction: Vector2) -> void:
	if not is_instance_valid(player):
		player = get_tree().get_first_node_in_group("player") as CharacterBody2D
	if is_instance_valid(player):
		player.set("extra_direction", direction)
