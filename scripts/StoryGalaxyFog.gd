extends Control
## Procedural mist over unavailable story galaxies; no new image asset.

var cloud_seed: int = 0
var _clouds: Array[Dictionary] = []

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = 71843 + cloud_seed * 3191
	for i in range(29):
		_clouds.append({
			"center": Vector2(rng.randf_range(0.15, 0.85), rng.randf_range(0.18, 0.82)),
			"radius": rng.randf_range(0.15, 0.32),
			"alpha": rng.randf_range(0.06, 0.16),
			"blue": rng.randf_range(0.50, 0.95)
		})
	resized.connect(queue_redraw)


func _draw() -> void:
	var unit: float = minf(size.x, size.y)
	var center: Vector2 = size * 0.5
	# A dim central void masks both the sun and its clickable visual target.
	draw_circle(center, unit * 0.28, Color(0.015, 0.031, 0.085, 0.73))
	for cloud in _clouds:
		var pos: Vector2 = size * (cloud["center"] as Vector2)
		var radius: float = unit * float(cloud["radius"])
		var blue: float = float(cloud["blue"])
		draw_circle(pos, radius, Color(0.20 * blue, 0.30 * blue, 0.49 * blue, float(cloud["alpha"])))
	# Translucent rings keep this looking like nebular fog rather than a flat lock.
	draw_arc(center, unit * 0.39, 0.18, 5.6, 56, Color(0.42, 0.58, 0.77, 0.28), 1.7, true)
