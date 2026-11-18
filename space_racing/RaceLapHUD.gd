extends Control
## Right-side vertical progress rail, matching the existing joystick axis.
var completed: int = 0
var place: int = 1
var best_lap: float = 0.0
var current_time: float = 0.0

func _draw() -> void:
	var panel := StyleBoxFlat.new()
	panel.bg_color = Color(0.025, 0.065, 0.13, 0.92)
	panel.border_color = Color(0.22, 0.79, 0.96, 0.88)
	panel.set_border_width_all(2)
	panel.set_corner_radius_all(18)
	panel.shadow_color = Color(0.0, 0.8, 1.0, 0.13)
	panel.shadow_size = 5
	draw_style_box(panel, Rect2(Vector2.ZERO, size))
	var font: Font = ThemeDB.fallback_font
	var center_x: float = size.x * 0.5
	var factor: float = size.y / 222.0
	draw_string(font, Vector2(10.0, 24.0 * factor), "LAPS", HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color(0.84, 0.95, 1.0))
	var first_y: float = 55.0 * factor
	var step: float = 47.0 * factor
	draw_line(Vector2(center_x, first_y), Vector2(center_x, first_y + step * 2.0), Color(0.17, 0.45, 0.58), 3.0, true)
	for i in range(3):
		var center := Vector2(center_x, first_y + float(i) * step)
		var done: bool = i < completed
		draw_circle(center, 17.0 * factor, Color(0.01, 0.025, 0.07))
		draw_circle(center, 12.0 * factor, Color(0.20, 0.94, 0.59) if done else Color(0.15, 0.29, 0.42))
		draw_arc(center, 16.0 * factor, 0.0, TAU, 28, Color(0.30, 0.82, 0.97), 1.6, true)
		if done:
			draw_line(center + Vector2(-5, 0) * factor, center + Vector2(-1, 4) * factor, Color(0.01, 0.16, 0.12), 2.5, true)
			draw_line(center + Vector2(-1, 4) * factor, center + Vector2(6, -5) * factor, Color(0.01, 0.16, 0.12), 2.5, true)
		else:
			draw_string(font, center + Vector2(-4, 5) * factor, str(i + 1), HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color(0.78, 0.90, 1.0))
	if best_lap > 0.0:
		draw_string(font, Vector2(8.0, size.y - 12.0 * factor), "%.1fs" % best_lap, HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color(0.49, 0.96, 0.74))
