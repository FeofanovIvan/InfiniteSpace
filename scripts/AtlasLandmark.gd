extends Node2D
## Replaces placeholder geometric markers with soft orbital-satellite icons.
## The atlas still varies small details by motif, but nothing appears as a flat
## green square or triangle in flight anymore.
var motif: int = 0
var accent: Color = Color(0.40, 0.84, 1.0)

func configure(style_id: int, tint: Color) -> void:
	motif = posmod(style_id, 5)
	accent = tint
	queue_redraw()

func _draw() -> void:
	var glow: Color = Color(accent.r, accent.g, accent.b, 0.10)
	var metal: Color = Color(0.15, 0.22, 0.34, 0.96)
	var light: Color = Color(0.88, 0.96, 1.0, 0.98)
	draw_circle(Vector2.ZERO, 28.0, glow)
	draw_arc(Vector2.ZERO, 16.0, 0.0, TAU, 48, Color(accent.r, accent.g, accent.b, 0.32), 2.0, true)
	# Ringed orbital body.
	draw_circle(Vector2.ZERO, 8.5, metal)
	draw_arc(Vector2.ZERO, 14.0, -0.65, PI + 0.65, 32, accent, 2.4, true)
	draw_arc(Vector2.ZERO, 14.0, PI - 0.65, TAU + 0.65, 32, Color(1.0, 1.0, 1.0, 0.45), 1.2, true)
	# Antenna mast and top beacon.
	var mast_top: Vector2 = Vector2(0.0, -17.0)
	draw_line(Vector2.ZERO + Vector2(0.0, -7.0), mast_top, accent, 1.8)
	draw_circle(mast_top, 3.3, light)
	# Small side pods vary subtly per motif, but remain rounded.
	var left_pod: Vector2 = Vector2(-12.0, 3.0)
	var right_pod: Vector2 = Vector2(12.0, -2.0)
	match motif:
		0:
			draw_circle(left_pod, 3.0, accent)
			draw_circle(right_pod, 3.8, light)
		1:
			draw_circle(left_pod + Vector2(-2.0, -4.0), 2.8, light)
			draw_circle(right_pod + Vector2(1.0, 4.0), 3.0, accent)
		2:
			draw_circle(left_pod, 2.6, accent)
			draw_circle(Vector2(15.0, 5.0), 2.6, accent)
			draw_circle(right_pod, 3.2, light)
		3:
			draw_circle(Vector2(-14.0, -5.0), 3.2, light)
			draw_circle(Vector2(14.0, 6.0), 3.2, light)
		4:
			for angle in range(3):
				var position: Vector2 = Vector2.from_angle(-0.7 + float(angle) * 0.7) * 13.5
				draw_circle(position, 2.7, accent if angle != 1 else light)
	# Front window highlight.
	draw_circle(Vector2(-2.0, -2.0), 2.0, Color(0.98, 1.0, 1.0, 0.88))
