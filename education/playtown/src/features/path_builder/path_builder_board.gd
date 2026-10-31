extends Control

signal layout_changed

const RIVER_TEXTURE: Texture2D = preload("res://education/playtown/assets/path_builder/river_rocks.webp")
const BRIDGE_TEXTURE: Texture2D = preload("res://education/playtown/assets/path_builder/bridge.webp")

var nodes: Dictionary = {}
var edges: Array[Dictionary] = []
var blocked_edges: Dictionary = {}
var bridge_rows := [-1, -1]
var start_node := "0:0"
var goal_node := "8:0"
var interactive := true
var column_x := PackedFloat32Array([0.075, 0.18, 0.285, 0.405, 0.515, 0.625, 0.745, 0.85, 0.925])
var row_y := PackedFloat32Array([0.16, 0.385, 0.61, 0.835])

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	resized.connect(_rebuild_geometry)
	_rebuild_geometry()

func configure(start_row: int, goal_row: int) -> void:
	start_node = _grid_id(0, start_row)
	goal_node = _grid_id(8, goal_row)
	clear_items()
	queue_redraw()

func clear_items() -> void:
	blocked_edges.clear()
	bridge_rows = [-1, -1]
	queue_redraw()

func clear_bridge(river: int) -> void:
	if river < 0 or river >= bridge_rows.size():
		return
	bridge_rows[river] = -1
	queue_redraw()

func place_bridge_from_global(river: int, global_point: Vector2) -> bool:
	if not interactive or river < 0 or river >= 2:
		return false
	var local_point := get_global_transform_with_canvas().affine_inverse() * global_point
	var nearest_row := -1
	var nearest_distance := maxf(42.0, minf(size.x, size.y) * 0.09)
	for row in range(4):
		var distance := local_point.distance_to(_bridge_center(river, row))
		if distance < nearest_distance:
			nearest_distance = distance
			nearest_row = row
	if nearest_row < 0:
		return false
	bridge_rows[river] = nearest_row
	queue_redraw()
	return true

func place_bridge_any_from_global(global_point: Vector2) -> Dictionary:
	if not interactive:
		return {}
	var local_point := get_global_transform_with_canvas().affine_inverse() * global_point
	var nearest_river := -1
	var nearest_row := -1
	var nearest_distance := maxf(42.0, minf(size.x, size.y) * 0.09)
	for river in range(2):
		for row in range(4):
			var distance := local_point.distance_to(_bridge_center(river, row))
			if distance < nearest_distance:
				nearest_distance = distance
				nearest_river = river
				nearest_row = row
	if nearest_river < 0:
		return {}
	bridge_rows[nearest_river] = nearest_row
	queue_redraw()
	return {"river": nearest_river, "row": nearest_row}

func get_bridge_global_center(river: int) -> Vector2:
	if river < 0 or river >= 2 or bridge_rows[river] < 0:
		return Vector2.ZERO
	return get_global_transform_with_canvas() * _bridge_center(river, bridge_rows[river])

func place_stop_from_global(global_point: Vector2) -> bool:
	if not interactive:
		return false
	var local_point := get_global_transform_with_canvas().affine_inverse() * global_point
	var nearest_key := _nearest_edge_key(local_point)
	if nearest_key.is_empty():
		return false
	blocked_edges[nearest_key] = true
	queue_redraw()
	return true

func get_node_position(node_id: String) -> Vector2:
	return nodes.get(node_id, Vector2.ZERO)

func simulate_route() -> Dictionary:
	var route: Array[String] = [start_node]
	var visited: Dictionary = {start_node: true}
	var previous := ""
	var current := start_node
	for step in range(80):
		if current == goal_node:
			return {"won": true, "route": route}
		var options := _available_neighbors(current, previous)
		if options.is_empty():
			return {"won": false, "route": route}
		options.sort_custom(func(left: Dictionary, right: Dictionary) -> bool: return int(left["priority"]) < int(right["priority"]))
		var next_node: String = options[0]["node"]
		if visited.has(next_node):
			return {"won": false, "route": route}
		previous = current
		current = next_node
		visited[current] = true
		route.append(current)
	return {"won": false, "route": route}

func _rebuild_geometry() -> void:
	nodes.clear()
	edges.clear()
	for column in range(9):
		for row in range(4):
			nodes[_grid_id(column, row)] = Vector2(size.x * column_x[column], size.y * row_y[row])
	for row in range(4):
		_add_grid_edge(0, row, 1, row)
		_add_grid_edge(1, row, 2, row)
		_add_grid_edge(3, row, 4, row)
		_add_grid_edge(4, row, 5, row)
		_add_grid_edge(6, row, 7, row)
		_add_grid_edge(7, row, 8, row)
	for row in range(3):
		_add_grid_edge(1, row, 1, row + 1)
		_add_grid_edge(4, row, 4, row + 1)
		_add_grid_edge(7, row, 7, row + 1)
	_add_grid_edge(2, 0, 2, 1)
	_add_grid_edge(2, 2, 2, 3)
	_add_grid_edge(3, 1, 3, 2)
	_add_grid_edge(5, 0, 5, 1)
	_add_grid_edge(5, 2, 5, 3)
	_add_grid_edge(6, 1, 6, 2)
	_add_trap("trap_r_top", Vector2(get_node_position(_grid_id(7, 0)).x, size.y * 0.045), _grid_id(7, 0))
	_add_trap("trap_r_bottom", Vector2(get_node_position(_grid_id(7, 3)).x, size.y * 0.955), _grid_id(7, 3))
	_add_trap("trap_c_top", Vector2(get_node_position(_grid_id(4, 0)).x, size.y * 0.045), _grid_id(4, 0))
	_add_trap("trap_c_right", Vector2(size.x * 0.585, get_node_position(_grid_id(4, 2)).y), _grid_id(4, 2))
	_add_trap("trap_l_top", Vector2(get_node_position(_grid_id(1, 0)).x, size.y * 0.045), _grid_id(1, 0))
	_add_trap("trap_l_bottom", Vector2(get_node_position(_grid_id(1, 3)).x, size.y * 0.955), _grid_id(1, 3))
	queue_redraw()
	layout_changed.emit()

func _add_grid_edge(column_a: int, row_a: int, column_b: int, row_b: int) -> void:
	_add_edge(_grid_id(column_a, row_a), _grid_id(column_b, row_b), false)

func _add_trap(node_id: String, position: Vector2, parent_id: String) -> void:
	nodes[node_id] = position
	_add_edge(parent_id, node_id, true)

func _add_edge(a: String, b: String, trap: bool) -> void:
	edges.append({"a": a, "b": b, "trap": trap, "key": _edge_key(a, b)})

func _available_neighbors(node_id: String, previous: String) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for edge in edges:
		if blocked_edges.has(edge["key"]):
			continue
		var other := ""
		if edge["a"] == node_id:
			other = edge["b"]
		elif edge["b"] == node_id:
			other = edge["a"]
		if other.is_empty() or other == previous:
			continue
		result.append({"node": other, "priority": _choice_priority(node_id, other, bool(edge["trap"]))})
	for river in range(2):
		var row: int = bridge_rows[river]
		if row < 0:
			continue
		var left_column := 2 if river == 0 else 5
		var right_column := 3 if river == 0 else 6
		var a := _grid_id(left_column, row)
		var b := _grid_id(right_column, row)
		var other := b if node_id == a else a if node_id == b else ""
		if not other.is_empty() and other != previous:
			result.append({"node": other, "priority": _choice_priority(node_id, other, false)})
	return result

func _choice_priority(from_id: String, to_id: String, trap: bool) -> int:
	if trap:
		return 0
	var delta: Vector2 = nodes[to_id] - nodes[from_id]
	if absf(delta.y) > absf(delta.x):
		return 1 if delta.y > 0.0 else 2
	return 3 if delta.x > 0.0 else 4

func _gui_input(event: InputEvent) -> void:
	if not interactive:
		return
	var point := Vector2.ZERO
	var released := false
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		point = event.position
		released = true
	elif event is InputEventScreenTouch and event.pressed:
		point = event.position
		released = true
	if not released:
		return
	var nearest_key := _nearest_edge_key(point)
	if not nearest_key.is_empty() and blocked_edges.has(nearest_key):
		blocked_edges.erase(nearest_key)
		queue_redraw()
		accept_event()

func _nearest_edge_key(point: Vector2) -> String:
	var nearest_key := ""
	var nearest_distance := maxf(25.0, minf(size.x, size.y) * 0.045)
	for edge in edges:
		var distance := _distance_to_segment(point, nodes[edge["a"]], nodes[edge["b"]])
		if distance < nearest_distance:
			nearest_distance = distance
			nearest_key = edge["key"]
	return nearest_key

func _bridge_center(river: int, row: int) -> Vector2:
	var left_column := 2 if river == 0 else 5
	var right_column := 3 if river == 0 else 6
	return (nodes[_grid_id(left_column, row)] + nodes[_grid_id(right_column, row)]) * 0.5

func _distance_to_segment(point: Vector2, a: Vector2, b: Vector2) -> float:
	var segment := b - a
	var length_squared := segment.length_squared()
	if length_squared <= 0.001:
		return point.distance_to(a)
	var t: float = clampf((point - a).dot(segment) / length_squared, 0.0, 1.0)
	return point.distance_to(a + segment * t)

func _draw() -> void:
	var field_style := StyleBoxFlat.new()
	field_style.bg_color = Color("#79c950")
	field_style.set_corner_radius_all(maxi(18, int(minf(size.x, size.y) * 0.035)))
	draw_style_box(field_style, Rect2(Vector2.ZERO, size))
	_draw_grass_details()
	_draw_river(size.x * 0.345, RIVER_TEXTURE)
	_draw_river(size.x * 0.685, RIVER_TEXTURE)
	for edge in edges:
		_draw_road_outline(nodes[edge["a"]], nodes[edge["b"]])
	for edge in edges:
		_draw_road_surface(nodes[edge["a"]], nodes[edge["b"]])
	_draw_road_junctions()
	for row in range(4):
		draw_circle(nodes[_grid_id(0, row)], 12.0, Color("#f5d98c"))
		draw_circle(nodes[_grid_id(8, row)], 12.0, Color("#f5d98c"))
	for river in range(2):
		for row in range(4):
			_draw_bridge_slot(river, row, bridge_rows[river] == row)
	for edge in edges:
		if blocked_edges.has(edge["key"]):
			_draw_stop((nodes[edge["a"]] + nodes[edge["b"]]) * 0.5)

func _draw_grass_details() -> void:
	for index in range(26):
		var x := fmod(41.0 + float(index) * 137.0, maxf(1.0, size.x))
		var y := fmod(31.0 + float(index * 83), maxf(1.0, size.y))
		draw_circle(Vector2(x, y), 3.0, Color("#f6e76f"))

func _draw_river(center_x: float, texture: Texture2D) -> void:
	var river_width: float = size.x * 0.092
	var rect := Rect2(center_x - river_width * 0.5, -size.y * 0.02, river_width, size.y * 1.04)
	draw_texture_rect(texture, rect, false)

func _road_width() -> float:
	return maxf(14.0, minf(size.x, size.y) * 0.031)

func _draw_road_outline(a: Vector2, b: Vector2) -> void:
	var width := _road_width()
	draw_line(a, b, Color("#a76833"), width + 7.0, true)

func _draw_road_surface(a: Vector2, b: Vector2) -> void:
	var width := _road_width()
	draw_line(a, b, Color("#f5d98c"), width, true)

func _draw_road_junctions() -> void:
	var width := _road_width()
	for position: Vector2 in nodes.values():
		draw_circle(position, (width + 7.0) * 0.5, Color("#a76833"))
		draw_circle(position, width * 0.5, Color("#f5d98c"))

func _draw_road(a: Vector2, b: Vector2) -> void:
	var width: float = maxf(14.0, minf(size.x, size.y) * 0.031)
	draw_line(a, b, Color("#a76833"), width + 7.0, true)
	draw_line(a, b, Color("#f5d98c"), width, true)
	draw_circle(a, width * 0.5, Color("#f5d98c"))
	draw_circle(b, width * 0.5, Color("#f5d98c"))

func _draw_bridge_slot(river: int, row: int, active: bool) -> void:
	var center := _bridge_center(river, row)
	var slot_size := Vector2(size.x * 0.077, maxf(28.0, size.y * 0.078))
	if active:
		var texture_size := BRIDGE_TEXTURE.get_size()
		var fit_scale := minf(slot_size.x / texture_size.x, slot_size.y / texture_size.y)
		var draw_size := texture_size * fit_scale
		draw_texture_rect(BRIDGE_TEXTURE, Rect2(center - draw_size * 0.5, draw_size), false)
	else:
		draw_dashed_line(Vector2(center.x - slot_size.x * 0.42, center.y), Vector2(center.x + slot_size.x * 0.42, center.y), Color(1, 1, 1, 0.75), 4.0, 8.0)

func _draw_stop(center: Vector2) -> void:
	var radius := maxf(13.0, minf(size.x, size.y) * 0.025)
	draw_circle(center + Vector2(2.0, 3.0), radius + 4.0, Color(0, 0, 0, 0.20))
	draw_circle(center, radius + 3.0, Color.WHITE)
	draw_circle(center, radius, Color("#e3483f"))
	draw_line(center + Vector2(-radius * 0.48, -radius * 0.48), center + Vector2(radius * 0.48, radius * 0.48), Color.WHITE, radius * 0.28, true)
	draw_line(center + Vector2(radius * 0.48, -radius * 0.48), center + Vector2(-radius * 0.48, radius * 0.48), Color.WHITE, radius * 0.28, true)

func _grid_id(column: int, row: int) -> String:
	return "%d:%d" % [column, row]

func _edge_key(a: String, b: String) -> String:
	return "%s|%s" % [a, b] if a < b else "%s|%s" % [b, a]
