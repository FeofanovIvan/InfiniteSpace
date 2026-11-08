extends Node2D
## v46: sparse electrical arcs and traveling energy on Triangulum's Last Gate.
## Local coordinate system: station centre = (0, 0); independent from sprite spin.
var simulation_time: float = 0.0

func update_time(value: float) -> void:
	simulation_time = value
	queue_redraw()

func _draw() -> void:
	var t: float = simulation_time
	# Small orbiting glints, no opaque disc over the transparent portal texture.
	for index in range(8):
		var phase: float = t * (0.18 + 0.013 * float(index % 3)) + TAU * float(index) / 8.0
		var radius: float = 170.0 + float(index % 3) * 29.0
		var p: Vector2 = Vector2.from_angle(phase) * radius
		var shimmer: float = 0.5 + 0.5 * sin(t * 2.7 + float(index) * 2.1)
		draw_circle(p, 3.0 + shimmer * 2.8, Color(0.58, 0.88, 1.0, 0.30 + shimmer * 0.32))
		draw_line(p - Vector2.from_angle(phase + 0.4) * 9.0, p + Vector2.from_angle(phase + 0.4) * 9.0, Color(0.82, 0.68, 1.0, 0.14 + shimmer * 0.18), 1.5, true)
	# Electrical discharges appear only for a brief fraction of each cycle.
	for arc_index in range(3):
		var cycle: float = fposmod(t * (0.34 + float(arc_index) * 0.04) + float(arc_index) * 0.39, 1.0)
		if cycle > 0.105:
			continue
		var strength: float = sin(PI * cycle / 0.105)
		var angle: float = float(arc_index) * TAU / 3.0 + t * 0.075
		var from_p: Vector2 = Vector2.from_angle(angle) * 140.0
		var outward: Vector2 = Vector2.from_angle(angle)
		var cross: Vector2 = Vector2(-outward.y, outward.x)
		for step in range(10):
			var f0: float = float(step) / 10.0
			var f1: float = float(step + 1) / 10.0
			var wobble0: float = 10.0 * sin(float(step) * 5.27 + float(arc_index) * 3.2 + floorf(t * 13.0))
			var wobble1: float = 10.0 * sin(float(step + 1) * 5.27 + float(arc_index) * 3.2 + floorf(t * 13.0))
			var p0: Vector2 = from_p + outward * (f0 * 160.0) + cross * wobble0
			var p1: Vector2 = from_p + outward * (f1 * 160.0) + cross * wobble1
			draw_line(p0, p1, Color(0.28, 0.62, 1.0, 0.27 * strength), 5.0, true)
			draw_line(p0, p1, Color(0.88, 0.92, 1.0, 0.77 * strength), 1.4, true)
	var beat: float = 0.20 + 0.16 * (0.5 + 0.5 * sin(t * 1.26))
	draw_arc(Vector2.ZERO, 77.0 + 3.0 * sin(t * 0.8), 0.0, TAU, 72, Color(0.43, 0.78, 1.0, beat), 2.1, true)
