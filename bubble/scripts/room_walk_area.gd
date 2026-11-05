extends Node2D
# MikaRoomWalkArea deliberately local (fix duplicate global class registration)
## Walkable region in room image native coordinates (1672 × 941).
## Navigation is based on Bubble's FEET, not on the character sprite rectangle.
## The lower foreground furniture and back-wall equipment are excluded.

var polygon: PackedVector2Array = PackedVector2Array([
	Vector2(308, 463), Vector2(520, 452), Vector2(760, 448),
	Vector2(1060, 448), Vector2(1290, 451), Vector2(1430, 472),
	Vector2(1491, 527), Vector2(1465, 590), Vector2(1372, 655),
	Vector2(1302, 826), Vector2(396, 826), Vector2(325, 667),
	Vector2(238, 593), Vector2(213, 532), Vector2(244, 490)
])
@export var debug_visible: bool = false
const FOOT_MARGIN: float = 10.0
# MIKA_ROOM_V8_INTEGRATION
var _v8_forbidden: Array[Rect2] = []

func set_v8_forbidden(rects: Array[Rect2]) -> void:
	_v8_forbidden = rects.duplicate()
	queue_redraw()

func is_walkable(point: Vector2) -> bool:
	if not Geometry2D.is_point_in_polygon(point, polygon):
		return false
	for rect in _v8_forbidden:
		if rect.has_point(point):
			return false
	return true

func try_step(start: Vector2, change: Vector2) -> Vector2:
	# Separate axes make a collision slide along furniture instead of freezing.
	var step_x := start + Vector2(change.x, 0.0)
	if is_walkable(step_x):
		start = step_x
	var step_y := start + Vector2(0.0, change.y)
	if is_walkable(step_y):
		start = step_y
	return start

func nearest_point(point: Vector2) -> Vector2:
	if is_walkable(point):
		return point
	var nearest: Vector2 = polygon[0]
	var smallest: float = INF
	for i in range(polygon.size()):
		var a: Vector2 = polygon[i]
		var b: Vector2 = polygon[(i + 1) % polygon.size()]
		var hit: Vector2 = Geometry2D.get_closest_point_to_segment(point, a, b)
		var d: float = point.distance_squared_to(hit)
		if d < smallest:
			smallest = d
			nearest = hit
	# Move the point a fraction inward, avoiding boundary precision issues.
	var middle := Vector2(840, 610)
	return nearest.lerp(middle, 0.015)

func set_debug(enabled: bool) -> void:
	debug_visible = enabled
	queue_redraw()

func _draw() -> void:
	if not debug_visible:
		return
	draw_colored_polygon(polygon, Color(0.16, 0.9, 0.80, 0.11))
	var line := polygon.duplicate()
	line.append(polygon[0])
	draw_polyline(line, Color(0.52, 1, 0.90, 0.94), 3.0, true)
	for v in polygon:
		draw_circle(v, 4.0, Color(0.55, 1, 0.95, 0.84))
	for blocked in _v8_forbidden:
		draw_rect(blocked, Color(1.0, 0.20, 0.25, 0.16), true)
		draw_rect(blocked, Color(1.0, 0.30, 0.32, 0.80), false, 2.0)
