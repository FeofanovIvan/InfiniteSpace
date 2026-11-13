extends Control
var route: PackedVector2Array = PackedVector2Array()
var map_source: Control
var rival_positions: Array[Vector2] = []

func _draw() -> void:
	if route.size() < 2 or map_source == null:
		return
	var n: int = route.size()
	for i in range(n):
		var a: Vector2 = map_source.call("_world_to_map", route[i])
		var b: Vector2 = map_source.call("_world_to_map", route[(i + 1) % n])
		if a.distance_to(Vector2(130, 130)) < 123.0 and b.distance_to(Vector2(130, 130)) < 123.0:
			draw_line(a, b, Color(0.06, 0.89, 1.0, 0.94), 1.9, true)
	var start: Vector2 = map_source.call("_world_to_map", route[0])
	if start.distance_to(Vector2(130, 130)) < 122.0:
		draw_circle(start, 3.8, Color(1.0, 0.63, 0.14))

	for i in range(rival_positions.size()):
		var p: Vector2 = map_source.call("_world_to_map", rival_positions[i])
		if p.distance_to(Vector2(130, 130)) < 121.0:
			var colors := [Color(0.52, 1.0, 0.43), Color(0.37, 0.68, 1.0), Color(0.43, 1.0, 0.84), Color(1.0, 0.40, 0.71)]
			draw_circle(p, 3.7, colors[i % colors.size()])
