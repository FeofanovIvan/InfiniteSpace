extends Control
## Lightweight animated hyperspace tunnel with a white departure trail.
var progress: float = 0.0
var travel_heading: Vector2 = Vector2.RIGHT
var phase: int = 0

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	visible = false
	process_mode = Node.PROCESS_MODE_ALWAYS

func update_warp(p: float, direction: Vector2, stage: int) -> void:
	progress = clampf(p, 0.0, 1.0)
	travel_heading = direction.normalized()
	if travel_heading.length_squared() < 0.001:
		travel_heading = Vector2.RIGHT
	phase = stage
	visible = true
	queue_redraw()

func end_warp() -> void:
	visible = false

func _draw() -> void:
	var sz: Vector2 = size
	var mid: Vector2 = sz * 0.5
	var heading: Vector2 = travel_heading.normalized()
	var side: Vector2 = Vector2(-heading.y, heading.x)
	var strength: float = sin(progress * PI)
	var tunnel_alpha: float = 0.18 + strength * 0.32
	draw_rect(Rect2(Vector2.ZERO, sz), Color(0.02, 0.07, 0.18, tunnel_alpha * 0.65))
	var mouth: Vector2 = mid + heading * lerpf(20.0, 48.0, progress)
	var tunnel_length: float = maxf(sz.x, sz.y) * lerpf(0.18, 0.64, progress)
	var width: float = lerpf(82.0, 210.0, strength)
	var poly: PackedVector2Array = PackedVector2Array([
		mouth - side * width * 0.62,
		mouth + side * width * 0.62,
		mouth + heading * tunnel_length + side * width,
		mouth + heading * tunnel_length - side * width
	])
	draw_colored_polygon(poly, Color(0.34, 0.72, 1.0, 0.12 + strength * 0.16))
	for i in range(68):
		var ray_p: float = float(i) / 67.0
		var angle_off: float = -0.80 + ray_p * 1.60
		var ray_dir: Vector2 = heading.rotated(angle_off)
		var inner: Vector2 = mouth + ray_dir * (24.0 + float(i % 5) * 4.0)
		var outer: Vector2 = mouth + ray_dir * (190.0 + strength * 320.0 + float(i % 7) * 18.0)
		var tint: Color = Color(0.30 + float(i % 4) * 0.10, 0.74, 1.0, 0.08 + strength * 0.12)
		draw_line(inner, outer, tint, 1.1 + float(i % 3) * 0.7, true)
	var streak_start: Vector2
	var streak_end: Vector2
	if phase == 0:
		streak_start = mid - heading * 14.0
		streak_end = mid + heading * (90.0 + progress * 230.0)
	else:
		streak_start = mid - heading * (120.0 - progress * 95.0)
		streak_end = mid + heading * 18.0
	draw_line(streak_start, streak_end, Color(1.0, 1.0, 1.0, 0.18 + strength * 0.46), 4.2, true)
	draw_circle(mouth, 24.0 + strength * 18.0, Color(0.62, 0.88, 1.0, 0.06 + strength * 0.10))
