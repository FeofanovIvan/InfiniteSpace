@tool
extends Control
## Simple neon search glyph matching the simulator / settings palette.

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	resized.connect(queue_redraw)

func _draw() -> void:
	var s: float = minf(size.x, size.y)
	if s < 12.0:
		return
	var center: Vector2 = Vector2(size.x * 0.44, size.y * 0.44)
	var radius: float = s * 0.21
	for width_px in [s * 0.16, s * 0.09, s * 0.05]:
		var tint: Color = Color(0.08, 0.72, 1.0, 0.20) if width_px > s * 0.12 else (Color("38dfff") if width_px > s * 0.07 else Color("efffff"))
		draw_arc(center, radius, 0.0, TAU, 40, tint, width_px, true)
		var a: Vector2 = center + Vector2(cos(PI * 0.23), sin(PI * 0.23)) * radius
		var b: Vector2 = center + Vector2(cos(PI * 0.23), sin(PI * 0.23)) * (radius + s * 0.22)
		draw_line(a, b, tint, width_px, true)
