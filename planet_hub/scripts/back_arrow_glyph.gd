@tool
extends Control
## v76: a bold, scalable neon back arrow. Decorative, never captures touches.

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	resized.connect(queue_redraw)

func _draw() -> void:
	if size.x < 10.0 or size.y < 10.0:
		return
	var s: float = minf(size.x, size.y)
	var start: Vector2 = Vector2(size.x * 0.26, size.y * 0.50)
	var end: Vector2 = Vector2(size.x * 0.77, size.y * 0.50)
	var upper: Vector2 = Vector2(size.x * 0.49, size.y * 0.27)
	var lower: Vector2 = Vector2(size.x * 0.49, size.y * 0.73)
	for thickness in [0.17, 0.105, 0.066]:
		var width_px: float = s * thickness
		var tint: Color = Color(0.08, 0.72, 1.0, 0.20) if thickness > 0.15 else (Color("38dfff") if thickness > 0.09 else Color("efffff"))
		draw_line(start, end, tint, width_px, true)
		draw_line(upper, start, tint, width_px, true)
		draw_line(start, lower, tint, width_px, true)
		draw_circle(start, width_px * 0.40, tint)
