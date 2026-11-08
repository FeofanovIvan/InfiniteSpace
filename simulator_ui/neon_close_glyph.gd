@tool
extends Control
## Vector X with the same cyan glow and white center as the PlanetHub back arrow.

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	resized.connect(queue_redraw)

func _draw() -> void:
	if minf(size.x, size.y) < 10.0:
		return
	var s: float = minf(size.x, size.y)
	var a: Vector2 = Vector2(size.x * 0.34, size.y * 0.34)
	var b: Vector2 = Vector2(size.x * 0.66, size.y * 0.66)
	var c: Vector2 = Vector2(size.x * 0.66, size.y * 0.34)
	var d: Vector2 = Vector2(size.x * 0.34, size.y * 0.66)
	for ratio in [0.20, 0.115, 0.066]:
		var width_px: float = s * ratio
		var tint: Color = Color(0.08, 0.72, 1.0, 0.20) if ratio > 0.18 else (Color("38dfff") if ratio > 0.10 else Color("efffff"))
		draw_line(a, b, tint, width_px, true)
		draw_line(c, d, tint, width_px, true)
