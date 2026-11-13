extends Node2D
## World-space race corridor: luminous side barriers and flowing direction dots.
var route: PackedVector2Array = PackedVector2Array()
var start_world := Vector2.ZERO
var camera_world := Vector2.ZERO
var viewport_size := Vector2(1280, 720)
var animation_time := 0.0
var next_index := 0
var track_width: float = 360.0

func _draw() -> void:
	if route.size() < 4:
		return
	var center: Vector2 = viewport_size * 0.5
	var n: int = route.size()
	var half: float = track_width * 0.5
	var visible := Rect2(Vector2.ZERO, viewport_size).grow(track_width + 30.0)
	var pulse: float = 0.5 + 0.5 * sin(animation_time * 3.0)
	for i in range(n):
		var prev: Vector2 = route[(i + n - 1) % n]
		var here: Vector2 = route[i]
		var nxt: Vector2 = route[(i + 1) % n]
		var tangent: Vector2 = (nxt - prev).normalized()
		var normal: Vector2 = tangent.rotated(PI * 0.5)
		var a: Vector2 = here - camera_world + center
		if not visible.has_point(a):
			continue
		var next_prev: Vector2 = route[i]
		var next_next: Vector2 = route[(i + 2) % n]
		var next_normal: Vector2 = (next_next - next_prev).normalized().rotated(PI * 0.5)
		var b: Vector2 = nxt - camera_world + center
		# Translucent roadway makes the playable width unambiguous.
		draw_colored_polygon(PackedVector2Array([a + normal * half, b + next_normal * half, b - next_normal * half, a - normal * half]), Color(0.02, 0.34, 0.53, 0.065))
		for sign in [-1.0, 1.0]:
			var edge_a: Vector2 = a + normal * half * sign
			var edge_b: Vector2 = b + next_normal * half * sign
			draw_line(edge_a, edge_b, Color(0.05, 0.62, 0.96, 0.22), 11.0, true)
			draw_line(edge_a, edge_b, Color(0.20, 0.89, 1.0, 0.82), 2.5, true)
			if i % 3 == 0:
				var glow: float = 0.4 + 0.6 * (0.5 + 0.5 * sin(animation_time * 7.0 - float(i) * 0.36))
				draw_circle(edge_a, 4.0 + glow * 1.6, Color(0.27, 0.90, 1.0, glow))
		# A moving dotted centerline continuously points forward.
		if i % 3 == 0:
			var flow: float = 0.25 + 0.75 * (0.5 + 0.5 * sin(animation_time * 7.0 - float(i) * 0.40))
			draw_circle(a, 3.5 + flow * 2.2, Color(0.48, 0.96, 1.0, flow * 0.8))
		if i % 13 == 0:
			var arrow_pos: Vector2 = a + tangent * 7.0
			var side: Vector2 = normal * 11.0
			draw_colored_polygon(PackedVector2Array([arrow_pos + tangent * 18.0, arrow_pos - tangent * 10.0 + side, arrow_pos - tangent * 10.0 - side]), Color(1.0, 0.57, 0.12, 0.80 + pulse * 0.18))
	var tangent: Vector2 = (route[1] - route[n - 1]).normalized()
	var side: Vector2 = tangent.rotated(PI * 0.5)
	var start: Vector2 = start_world - camera_world + center
	var squares: int = 16
	var square_width: float = track_width / float(squares)
	for i in range(squares):
		for j in range(2):
			var base: Vector2 = start + side * (float(i) - float(squares) * 0.5) * square_width + tangent * (float(j) - 1.0) * square_width
			var col: Color = Color.WHITE if (i + j) % 2 == 0 else Color(0.08, 0.12, 0.19)
			draw_colored_polygon(PackedVector2Array([base, base + side * square_width, base + side * square_width + tangent * square_width, base + tangent * square_width]), col)
