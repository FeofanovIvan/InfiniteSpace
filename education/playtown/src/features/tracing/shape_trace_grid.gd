extends Node2D
signal edge_attempt(from_idx: int, to_idx: int)
signal interaction_started
signal coloring_progress(value: float)
signal coloring_completed
const GRID_N := 6
const GRID_LINE_COLOR := Color(0.80, 0.72, 0.58)
const GRID_BORDER_COLOR := Color(0.47, 0.34, 0.20)
const LABEL_COLOR := Color(0.35, 0.25, 0.15)
const SHAPE_COLOR := Color(0.28, 0.18, 0.10)
const PREVIEW_COLOR := Color(0.55, 0.42, 0.26, 0.85)
const DOT_COLOR := Color(0.28, 0.18, 0.10)
const DOT_INNER_COLOR := Color(1.0, 1.0, 1.0)
const HIT_RADIUS := 46.0
const DEMO_COLOR := Color(0.82, 0.27, 0.24)
const DEMO_MOVE_TIME := 0.9
const DEMO_PAUSE_TIME := 0.45
var interactive: bool = false
var margin: float = 0.0
var cell: float = 0.0
var grid_origin: Vector2 = Vector2.ZERO
var points: PackedVector2Array = []
var edges: Array = []
var drawn_edges: Array = []
var dragging: bool = false
var drag_from: int = -1
var drag_pos: Vector2 = Vector2.ZERO
var demo_active: bool = false
var demo_edge_i: int = 0
var demo_moving: bool = true
var demo_timer: float = 0.0
var coloring_mode: bool = false
var coloring_allowed: bool = false
var coloring_dragging: bool = false
var fill_color := Color.TRANSPARENT
var solid_fill_visible: bool = false
var fill_complete: bool = false
var brush_points: Array[Vector2] = []
var paint_polygons: Array[PackedVector2Array] = []
var coverage_points: Array[Vector2] = []
var coverage_flags: Array[bool] = []
var last_brush_point := Vector2.ZERO
func _ready() -> void:
	set_process(false)
func set_layout(rect: Rect2) -> void:
	position = rect.position
	margin = rect.size.x * 0.14
	cell = (rect.size.x - margin) / float(GRID_N)
	grid_origin = Vector2(margin, margin)
	if coloring_mode:
		_build_coverage()
	queue_redraw()
func set_shape(pts: PackedVector2Array, edge_list: Array) -> void:
	points = pts
	edges = edge_list
	drawn_edges.clear()
	dragging = false
	drag_from = -1
	coloring_mode = false
	coloring_allowed = false
	coloring_dragging = false
	solid_fill_visible = false
	fill_complete = false
	brush_points.clear()
	paint_polygons.clear()
	coverage_points.clear()
	coverage_flags.clear()
	queue_redraw()
func mark_edge_drawn(i: int, j: int) -> void:
	drawn_edges.append([mini(i, j), maxi(i, j)])
	queue_redraw()
func start_demo() -> void:
	if interactive:
		return
	demo_active = true
	demo_edge_i = 0
	demo_moving = true
	demo_timer = 0.0
	set_process(true)
	queue_redraw()
func stop_demo() -> void:
	demo_active = false
	set_process(false)
	queue_redraw()
func set_solid_fill(color: Color, visible: bool = true) -> void:
	fill_color = color
	solid_fill_visible = visible
	queue_redraw()
func prepare_coloring(color: Color) -> void:
	fill_color = color
	coloring_mode = true
	coloring_allowed = false
	coloring_dragging = false
	fill_complete = false
	brush_points.clear()
	paint_polygons.clear()
	_build_coverage()
	queue_redraw()
func enable_coloring() -> void:
	if coloring_mode and not fill_complete:
		coloring_allowed = true
func _shape_polygon() -> PackedVector2Array:
	var polygon := PackedVector2Array()
	for point in points:
		polygon.append(_grid_to_local(point))
	return polygon
func _build_coverage() -> void:
	coverage_points.clear()
	coverage_flags.clear()
	if points.size() < 3 or cell <= 0.0:
		return
	var polygon := _shape_polygon()
	var bounds := Rect2(polygon[0], Vector2.ZERO)
	for point in polygon:
		bounds = bounds.expand(point)
	var step_size := maxf(8.0, cell * 0.20)
	var y := bounds.position.y
	while y <= bounds.end.y:
		var x := bounds.position.x
		while x <= bounds.end.x:
			var sample := Vector2(x, y)
			if Geometry2D.is_point_in_polygon(sample, polygon):
				coverage_points.append(sample)
				coverage_flags.append(false)
			x += step_size
		y += step_size
func _process(delta: float) -> void:
	if not demo_active or edges.is_empty():
		return
	demo_timer += delta
	if demo_moving:
		if demo_timer >= DEMO_MOVE_TIME:
			demo_timer = 0.0
			demo_moving = false
	else:
		if demo_timer >= DEMO_PAUSE_TIME:
			demo_timer = 0.0
			demo_moving = true
			demo_edge_i = (demo_edge_i + 1) % edges.size()
	queue_redraw()
func _grid_to_local(p: Vector2) -> Vector2:
	return grid_origin + p * cell
func _draw() -> void:
	if cell <= 0.0:
		return
	for k in range(GRID_N + 1):
		var x := grid_origin.x + k * cell
		draw_line(Vector2(x, grid_origin.y), Vector2(x, grid_origin.y + GRID_N * cell), GRID_LINE_COLOR, 2.0)
		var y := grid_origin.y + k * cell
		draw_line(Vector2(grid_origin.x, y), Vector2(grid_origin.x + GRID_N * cell, y), GRID_LINE_COLOR, 2.0)
	draw_rect(Rect2(grid_origin, Vector2(GRID_N * cell, GRID_N * cell)), GRID_BORDER_COLOR, false, 3.0)
	var font := ThemeDB.fallback_font
	var font_size := int(clampf(cell * 0.34, 14.0, 40.0))
	for i in range(GRID_N):
		var label := str(i + 1)
		var cx := grid_origin.x + (i + 0.5) * cell
		draw_string(font, Vector2(cx - font_size * 0.28, margin * 0.66), label, HORIZONTAL_ALIGNMENT_CENTER, -1, font_size, LABEL_COLOR)
		var cy := grid_origin.y + (i + 0.5) * cell
		draw_string(font, Vector2(margin * 0.24, cy + font_size * 0.34), label, HORIZONTAL_ALIGNMENT_CENTER, -1, font_size, LABEL_COLOR)
	if points.size() < 2:
		return
	var polygon := _shape_polygon()
	if solid_fill_visible or fill_complete:
		draw_colored_polygon(polygon, fill_color)
	elif coloring_mode:
		for paint_polygon in paint_polygons:
			draw_colored_polygon(paint_polygon, fill_color)
	if not interactive:
		for e in edges:
			var a: Vector2 = _grid_to_local(points[e[0]])
			var b: Vector2 = _grid_to_local(points[e[1]])
			draw_line(a, b, SHAPE_COLOR, 9.0, true)
		for p in points:
			draw_circle(_grid_to_local(p), 7.0, SHAPE_COLOR)
		if demo_active and not edges.is_empty():
			var e: Array = edges[demo_edge_i]
			var a: Vector2 = _grid_to_local(points[e[0]])
			var b: Vector2 = _grid_to_local(points[e[1]])
			var t: float = clampf(demo_timer / DEMO_MOVE_TIME, 0.0, 1.0) if demo_moving else 1.0
			var puck: Vector2 = a.lerp(b, t)
			draw_circle(a, 11.0, DEMO_COLOR)
			draw_circle(b, 11.0, DEMO_COLOR)
			draw_circle(puck, 15.0, DEMO_COLOR)
	else:
		for e in drawn_edges:
			var a: Vector2 = _grid_to_local(points[e[0]])
			var b: Vector2 = _grid_to_local(points[e[1]])
			draw_line(a, b, SHAPE_COLOR, 9.0, true)
		if dragging and drag_from >= 0 and not coloring_mode:
			draw_line(_grid_to_local(points[drag_from]), drag_pos, PREVIEW_COLOR, 7.0, true)
		if not coloring_mode:
			for p in points:
				var c := _grid_to_local(p)
				draw_circle(c, 13.0, DOT_COLOR)
				draw_circle(c, 6.5, DOT_INNER_COLOR)
func _unhandled_input(event: InputEvent) -> void:
	if not interactive:
		return
	if coloring_mode:
		_handle_coloring_input(event)
		return
	var local_pos: Vector2
	var is_press := false
	var is_release := false
	var is_move := false
	if event is InputEventScreenTouch:
		local_pos = to_local(event.position)
		is_press = event.pressed
		is_release = not event.pressed
	elif event is InputEventScreenDrag:
		local_pos = to_local(event.position)
		is_move = true
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		local_pos = to_local(event.position)
		is_press = event.pressed
		is_release = not event.pressed
	elif event is InputEventMouseMotion:
		local_pos = to_local(event.position)
		is_move = true
	else:
		return
	if is_press:
		var idx := _nearest_dot(local_pos)
		if idx >= 0:
			dragging = true
			drag_from = idx
			drag_pos = local_pos
			queue_redraw()
			interaction_started.emit()
	elif is_move and dragging:
		drag_pos = local_pos
		queue_redraw()
	elif is_release and dragging:
		var idx := _nearest_dot(local_pos)
		var from_idx := drag_from
		dragging = false
		drag_from = -1
		queue_redraw()
		if idx >= 0 and idx != from_idx:
			edge_attempt.emit(from_idx, idx)
func _handle_coloring_input(event: InputEvent) -> void:
	if not coloring_allowed or fill_complete:
		return
	var local_pos := Vector2.ZERO
	var is_press := false
	var is_release := false
	var is_move := false
	if event is InputEventScreenTouch:
		local_pos = to_local(event.position)
		is_press = event.pressed
		is_release = not event.pressed
	elif event is InputEventScreenDrag:
		local_pos = to_local(event.position)
		is_move = true
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		local_pos = to_local(event.position)
		is_press = event.pressed
		is_release = not event.pressed
	elif event is InputEventMouseMotion:
		local_pos = to_local(event.position)
		is_move = true
	else:
		return
	if is_press and _inside_shape(local_pos):
		coloring_dragging = true
		last_brush_point = local_pos
		_add_brush_point(local_pos)
		interaction_started.emit()
	elif is_move and coloring_dragging:
		_add_brush_segment(last_brush_point, local_pos)
		last_brush_point = local_pos
	elif is_release:
		if coloring_dragging:
			_add_brush_segment(last_brush_point, local_pos)
		coloring_dragging = false
func _inside_shape(point: Vector2) -> bool:
	return points.size() >= 3 and Geometry2D.is_point_in_polygon(point, _shape_polygon())
func _add_brush_segment(from: Vector2, to: Vector2) -> void:
	var distance := from.distance_to(to)
	var spacing := maxf(5.0, cell * 0.12)
	var steps := maxi(1, ceili(distance / spacing))
	for index in range(1, steps + 1):
		_add_brush_point(from.lerp(to, float(index) / float(steps)))
func _add_brush_point(point: Vector2) -> void:
	if not _inside_shape(point):
		return
	brush_points.append(point)
	var radius := maxf(14.0, cell * 0.38)
	var brush_polygon := PackedVector2Array()
	for vertex_index in range(18):
		var angle := TAU * float(vertex_index) / 18.0
		brush_polygon.append(point + Vector2(cos(angle), sin(angle)) * radius)
	var clipped_polygons := Geometry2D.intersect_polygons(brush_polygon, _shape_polygon())
	for clipped_polygon in clipped_polygons:
		paint_polygons.append(clipped_polygon)
	var covered_count := 0
	for index in range(coverage_points.size()):
		if not coverage_flags[index] and coverage_points[index].distance_to(point) <= radius:
			coverage_flags[index] = true
		if coverage_flags[index]:
			covered_count += 1
	var progress := float(covered_count) / float(maxi(coverage_points.size(), 1))
	coloring_progress.emit(progress)
	queue_redraw()
	if progress >= 0.98:
		fill_complete = true
		coloring_allowed = false
		coloring_dragging = false
		queue_redraw()
		coloring_completed.emit()
func _nearest_dot(pos: Vector2) -> int:
	var best := -1
	var best_d := HIT_RADIUS
	for i in range(points.size()):
		var d: float = pos.distance_to(_grid_to_local(points[i]))
		if d < best_d:
			best_d = d
			best = i
	return best
