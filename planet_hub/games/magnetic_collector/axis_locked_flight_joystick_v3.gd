extends "res://scripts/Joystick.gd"
## Reuses the cockpit flight joystick input, geometry and dual-touch ownership.
## Only the visible guidance and returned axis are restricted to one dimension.

@export_enum("Horizontal", "Vertical") var motion_axis: int = 0


func _set_direction(next_direction: Vector2) -> void:
	if motion_axis == 0:
		super._set_direction(Vector2(next_direction.x, 0.0))
	else:
		super._set_direction(Vector2(0.0, next_direction.y))


func _draw() -> void:
	var center: Vector2 = size * 0.5
	# Same 184px cockpit disc, cyan outlines, shadows and 26px grip.
	draw_circle(center, 83.0, Color(0.02, 0.10, 0.18, 0.66))
	draw_circle(center, 67.0, Color(0.04, 0.17, 0.28, 0.64))
	draw_arc(center, 67.0, 0.0, TAU, 64, Color(0.38, 0.80, 1.0, 0.60), 2.5, true)
	draw_arc(center, 49.0, 0.0, TAU, 64, Color(0.18, 0.51, 0.70, 0.29), 1.0, true)
	var start: Vector2 = Vector2.LEFT * 54.0 if motion_axis == 0 else Vector2.UP * 54.0
	var finish: Vector2 = -start
	draw_line(center + start, center + finish, Color(0.35, 0.91, 1.0, 0.32), 10.0, true)
	draw_line(center + start, center + finish, Color(0.70, 0.96, 1.0, 0.91), 3.0, true)
	for direction_sign in [-1.0, 1.0]:
		var arrow: Vector2 = Vector2(direction_sign, 0) if motion_axis == 0 else Vector2(0, direction_sign)
		var tip: Vector2 = center + arrow * 52.0
		var tangent: Vector2 = Vector2(-arrow.y, arrow.x)
		draw_line(tip, tip - arrow * 10.0 + tangent * 6.0, Color("89eaff"), 2.5, true)
		draw_line(tip, tip - arrow * 10.0 - tangent * 6.0, Color("89eaff"), 2.5, true)
	var knob: Vector2 = center + direction * STICK_RADIUS
	draw_circle(knob, KNOB_RADIUS + 6.0, Color(0.09, 0.49, 0.68, 0.31))
	draw_circle(knob, KNOB_RADIUS, Color(0.09, 0.34, 0.53, 0.98))
	draw_arc(knob, KNOB_RADIUS, 0.0, TAU, 48, Color(0.70, 0.96, 1.0, 0.91), 2.0, true)
	draw_circle(knob + Vector2(-5.0, -6.0), 7.0, Color(0.47, 0.80, 0.93, 0.36))
