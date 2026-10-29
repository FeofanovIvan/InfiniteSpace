extends Node2D
## Visible, lightweight multi-puff crash plume attached to the moving Earth.
var _progress: float = 0.0

func set_progress(value: float) -> void:
	_progress = clampf(value, 0.0, 1.0)
	visible = _progress < 0.99
	queue_redraw()

func _draw() -> void:
	var fade: float = pow(1.0 - _progress, 1.15)
	if fade <= 0.003:
		return
	# Small impact flash, followed by grey-blue smoke billowing upwards.
	if _progress < 0.18:
		var flash: float = 1.0 - _progress / 0.18
		draw_circle(Vector2.ZERO, 23.0 + 10.0 * _progress, Color(1.0, 0.84, 0.48, 0.58 * flash))
	for i in range(11):
		var a: float = float(i) * TAU / 11.0
		var outward: float = 11.0 + float((i * 7) % 5) * 3.0 + 36.0 * _progress
		var drift: Vector2 = Vector2(cos(a) * outward, sin(a) * outward * 0.47 - 44.0 * _progress)
		var size: float = 10.0 + float(i % 4) * 3.0 + 20.0 * _progress
		# Multiple concentric translucent circles soften the edge without GPU particles.
		draw_circle(drift, size * 1.35, Color(0.16, 0.22, 0.32, 0.21 * fade))
		draw_circle(drift, size * 1.08, Color(0.30, 0.39, 0.49, 0.34 * fade))
		draw_circle(drift + Vector2(-3.0, -4.0), size * 0.72, Color(0.66, 0.73, 0.79, 0.24 * fade))
