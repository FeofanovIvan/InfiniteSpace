extends "res://bubble/scripts/bubble_brain.gd"
## Same procedural liquid actor, but FaceRig is swapped at construction only.
## Uses inherited locomotion, turn, blink and expression behavior unchanged.

const EXPERIMENTAL_FACE: Script = preload("res://bubble/face_lab/bubble_surface_face.gd")

func _attach_face() -> void:
	_face_rig = null
	var socket: Node2D = _actor.get_node_or_null("Body/Face") as Node2D
	if socket == null:
		push_error("Bubble Face Lab: missing Body/Face socket")
		return
	for old_part in socket.get_children():
		if old_part is CanvasItem:
			(old_part as CanvasItem).visible = false
	var rig: MikaBubbleFace = EXPERIMENTAL_FACE.new() as MikaBubbleFace
	rig.name = "ExperimentalEllipsoidFaceRig"
	rig.show_preview_body = false
	rig.automatic_blink = true
	rig.scale = Vector2.ONE * 0.79
	socket.add_child(rig)
	_face_rig = rig
	_last_face_id = ""
	rig.brushing_progress_changed.connect(_on_brush_progress)
	rig.set_surface_heading(_surface_heading)
