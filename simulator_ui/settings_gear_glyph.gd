@tool
extends Control
## Light blue settings gear matching the simulator helmet / back-arrow palette.

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	resized.connect(queue_redraw)

func _draw() -> void:
	if minf(size.x, size.y) < 10.0:
		return
	var s: float = minf(size.x, size.y)
	var center: Vector2 = size * 0.5
	var rad: float = s * 0.23
	for k in range(8):
		var theta: float = float(k) * TAU / 8.0
		var v: Vector2 = Vector2(cos(theta), sin(theta))
		for thickness in [s * 0.17, s * 0.09]:
			var col: Color = Color(0.07, 0.76, 1.0, 0.23) if thickness > s * 0.1 else Color("a8f7ff")
			draw_line(center + v * rad * 1.0, center + v * rad * 1.45, col, thickness, true)
	draw_arc(center, rad, 0.0, TAU, 64, Color(0.06, 0.73, 1.0, 0.24), s * 0.17, true)
	draw_arc(center, rad, 0.0, TAU, 64, Color("d9ffff"), s * 0.085, true)
	draw_circle(center, rad * 0.37, Color("d9ffff"))
	draw_circle(center, rad * 0.18, Color("06254c"))
