extends Control

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	resized.connect(queue_redraw)

func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), Color("#c9efff"))
	var unit: float = minf(size.x / 1536.0, size.y / 768.0)
	var horizon: float = size.y * 0.58
	draw_circle(Vector2(size.x * 0.82, size.y * 0.15), 72.0 * unit, Color("#ffe88a"))
	_draw_cloud(Vector2(size.x * 0.17, size.y * 0.14), 54.0 * unit)
	_draw_cloud(Vector2(size.x * 0.70, size.y * 0.28), 38.0 * unit)
	for index in range(9):
		var hill_x: float = size.x * (float(index) / 8.0)
		var hill_radius: float = (150.0 + float(index % 3) * 22.0) * unit
		draw_circle(Vector2(hill_x, horizon + hill_radius * 0.36), hill_radius, Color("#8acb62"))
	draw_rect(Rect2(0.0, horizon, size.x, size.y - horizon), Color("#70bd50"))
	for index in range(24):
		var x: float = fmod(73.0 + float(index) * 181.0, size.x)
		var y: float = horizon + 36.0 * unit + fmod(float(index * 47), maxf(42.0, size.y - horizon - 55.0 * unit))
		var flower_color := Color("#fff7a8") if index % 2 == 0 else Color("#ffffff")
		draw_circle(Vector2(x, y), 4.5 * unit, flower_color)
		draw_circle(Vector2(x, y), 1.8 * unit, Color("#f3a531"))

func _draw_cloud(center: Vector2, radius: float) -> void:
	var color := Color(1.0, 1.0, 1.0, 0.78)
	draw_circle(center + Vector2(-radius, radius * 0.24), radius * 0.72, color)
	draw_circle(center, radius, color)
	draw_circle(center + Vector2(radius, radius * 0.26), radius * 0.68, color)
	draw_rect(Rect2(center + Vector2(-radius * 1.62, radius * 0.18), Vector2(radius * 3.15, radius * 0.78)), color)
