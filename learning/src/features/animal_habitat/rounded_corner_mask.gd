extends Control

@export var mask_color := Color.WHITE:
	set(value):
		mask_color = value
		queue_redraw()
@export var corner_radius := 24.0:
	set(value):
		corner_radius = value
		queue_redraw()

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	resized.connect(queue_redraw)

func _draw() -> void:
	var radius := minf(corner_radius, minf(size.x, size.y) * 0.5)
	if radius <= 0.0:
		return
	_draw_corner(Vector2(radius, radius), Vector2.ZERO, -PI * 0.5, -PI, radius)
	_draw_corner(Vector2(size.x - radius, radius), Vector2(size.x, 0.0), -PI * 0.5, 0.0, radius)
	_draw_corner(Vector2(size.x - radius, size.y - radius), size, 0.0, PI * 0.5, radius)
	_draw_corner(Vector2(radius, size.y - radius), Vector2(0.0, size.y), PI * 0.5, PI, radius)

func _draw_corner(center: Vector2, outer: Vector2, start_angle: float, end_angle: float, radius: float) -> void:
	var points := PackedVector2Array([outer])
	for index in range(13):
		var weight := float(index) / 12.0
		var angle := lerpf(start_angle, end_angle, weight)
		points.append(center + Vector2(cos(angle), sin(angle)) * radius)
	draw_colored_polygon(points, mask_color)
