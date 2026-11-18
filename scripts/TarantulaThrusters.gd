extends Node2D
## v58.3.2: precise exit points for the three blue engine exhausts for the new radial Tarantula station art.
## The three real engines are on the REAR side of the station, i.e. on the left
## side of the top-down sprite. This node is a CHILD of the rotating station Sprite2D,
## so all plumes rotate together with the station.
## Coordinates are in the 1254x1254 source-art space, centered at (627, 627).
## Plume starts were moved outward from inside the engine cylinders to the
## visible outlet faces at source-image x = 12; y = 486, 612 and 738.

const NOZZLES: Array[Vector2] = [
	Vector2(-615.0, -141.0),  # upper nozzle: pixel (12, 486)
	Vector2(-615.0, -15.0),   # middle nozzle: pixel (12, 612)
	Vector2(-615.0, 111.0)    # lower nozzle: pixel (12, 738)
]

var _time: float = 0.0

func update_time(seconds: float) -> void:
	_time = seconds
	queue_redraw()

func _draw() -> void:
	# Draw only the three exhaust plumes; never any station-wide halo, ring or mist.
	for i in range(NOZZLES.size()):
		var nozzle: Vector2 = NOZZLES[i]
		var phase: float = float(i) * 1.87
		var pressure: float = clampf(
			0.60 + 0.23 * sin(_time * 1.47 + phase)
			+ 0.10 * sin(_time * 3.6 + phase * 2.7), 0.24, 0.98)
		var flutter: float = 0.93 + 0.07 * sin(_time * 13.0 + phase)
		var length_px: float = (58.0 + 64.0 * pressure) * flutter
		var width_px: float = 16.0 + 6.0 * pressure
		var tip: Vector2 = nozzle + Vector2(-length_px, 0.0)
		# Translucent cyan/blue outer plume, flowing to -X from the nozzle.
		var outer := PackedVector2Array([
			nozzle + Vector2(4.0, -width_px * 0.69),
			nozzle + Vector2(-length_px * 0.45, -width_px * 0.55),
			tip,
			nozzle + Vector2(-length_px * 0.45, width_px * 0.55),
			nozzle + Vector2(4.0, width_px * 0.69)
		])
		draw_colored_polygon(outer, Color(0.03, 0.51, 1.0, 0.28 + 0.25 * pressure))
		var inner := PackedVector2Array([
			nozzle + Vector2(0.0, -width_px * 0.35),
			nozzle + Vector2(-length_px * 0.32, -width_px * 0.28),
			nozzle + Vector2(-length_px * 0.78, 0.0),
			nozzle + Vector2(-length_px * 0.32, width_px * 0.28),
			nozzle + Vector2(0.0, width_px * 0.35)
		])
		draw_colored_polygon(inner, Color(0.28, 0.82, 1.0, 0.40 + 0.37 * pressure))
		draw_circle(nozzle, 11.0 + pressure * 4.0, Color(0.06, 0.67, 1.0, 0.21 + 0.12 * pressure))
		draw_circle(nozzle + Vector2(-5.0, 0.0), 4.0 + 2.8 * pressure,
			Color(0.77, 0.97, 1.0, 0.74 + 0.24 * pressure))
		for j in range(3):
			var run: float = fposmod(_time * (1.1 + float(j) * 0.23) + float(i) * 0.31 + float(j) * 0.33, 1.0)
			var p: Vector2 = nozzle + Vector2(-length_px * run, sin(_time * 5.0 + phase + float(j) * 1.4) * width_px * 0.19)
			draw_circle(p, 1.4 + (1.0 - run) * 2.8,
				Color(0.35, 0.85, 1.0, pressure * (1.0 - run) * 0.68))
