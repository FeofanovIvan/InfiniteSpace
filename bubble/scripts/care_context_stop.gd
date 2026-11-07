extends "res://scripts/ActionButton.gd"
## Drop-in care-only version of the original circular Use button.
## Touch/mouse hit testing and the exact original silhouette are inherited.
var stop_active: bool = false

func set_stop_active(enabled: bool) -> void:
	if stop_active == enabled:
		return
	stop_active = enabled
	queue_redraw()

func _draw() -> void:
	if not stop_active:
		super._draw()
		return
	# Preserve the flight joystick's original 184 px circular frame.
	var center: Vector2 = size * 0.5
	var active: float = 1.0 if _pressed_visual else 0.0
	var flash: float = _press_flash / 0.18
	draw_circle(center, 83.0, Color(0.02, 0.10, 0.18, 0.36))
	draw_circle(center, CIRCLE_RADIUS, Color(0.04, 0.17, 0.28, 0.43 + active * 0.15))
	draw_arc(center, CIRCLE_RADIUS, 0.0, TAU, 64, Color(0.38, 0.80, 1.0, 0.42 + flash * 0.46), 2.0 + active, true)
	draw_arc(center, 49.0, 0.0, TAU, 64, Color(0.18, 0.51, 0.70, 0.22), 1.0, true)
	if _pressed_visual or flash > 0.0:
		draw_circle(center, 45.0, Color(0.13, 0.56, 0.82, 0.13 + 0.11 * maxf(active, flash)))
	if not interaction_available:
		return
	# One centered stop icon INSIDE the existing circle, not a second button.
	var side: float = 43.0
	var rect: Rect2 = Rect2(center - Vector2.ONE * side * 0.5, Vector2.ONE * side)
	draw_rect(rect, Color(0.93, 0.40, 0.51, 0.98), true)
	draw_rect(rect, Color(1.0, 0.87, 0.90, 0.95), false, 2.8, true)
