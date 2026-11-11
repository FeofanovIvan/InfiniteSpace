extends "res://learning/src/features/tracing/shape_trace_grid.gd"
## White squared paper for the sample/drawing canvases.
## The original touch, line recognition, colouring and demonstration logic
## remain inherited from the Safe City Kids ShapeTraceGrid script.

const PAPER := Color("#fffefd")
const RULE := Color("#d7e6f2")
const RULE_BORDER := Color("#92bbd2")
const GRID_TEXT := Color("#416882")
const INK := Color("#184265")
const PREVIEW := Color("#45c8ee")
const DOT := Color("#24658a")
const DEMO := Color("#f47d8f")

func _draw() -> void:
	if cell <= 0.0:
		return
	# A whole sheet, not merely an opaque texture behind the figure.
	var paper_size: Vector2 = grid_origin + Vector2.ONE * float(GRID_N) * cell
	draw_rect(Rect2(Vector2.ZERO, paper_size), PAPER, true)
	for k in range(GRID_N + 1):
		var x: float = grid_origin.x + float(k) * cell
		var y: float = grid_origin.y + float(k) * cell
		draw_line(Vector2(x, grid_origin.y), Vector2(x, grid_origin.y + GRID_N * cell), RULE, 1.7, true)
		draw_line(Vector2(grid_origin.x, y), Vector2(grid_origin.x + GRID_N * cell, y), RULE, 1.7, true)
	draw_rect(Rect2(grid_origin, Vector2.ONE * GRID_N * cell), RULE_BORDER, false, 2.5, true)
	var font: Font = ThemeDB.fallback_font
	var font_size: int = roundi(clampf(cell * 0.34, 11.0, 33.0))
	for i in range(GRID_N):
		var s: String = str(i + 1)
		var cx: float = grid_origin.x + (float(i) + 0.5) * cell
		var cy: float = grid_origin.y + (float(i) + 0.5) * cell
		draw_string(font, Vector2(cx - font_size * 0.28, margin * 0.66), s, HORIZONTAL_ALIGNMENT_CENTER, -1, font_size, GRID_TEXT)
		draw_string(font, Vector2(margin * 0.24, cy + font_size * 0.34), s, HORIZONTAL_ALIGNMENT_CENTER, -1, font_size, GRID_TEXT)
	if points.size() < 2:
		return
	var polygon: PackedVector2Array = _shape_polygon()
	if solid_fill_visible or fill_complete:
		draw_colored_polygon(polygon, fill_color)
	elif coloring_mode:
		for paint_polygon in paint_polygons:
			draw_colored_polygon(paint_polygon, fill_color)
	if not interactive:
		for e in edges:
			var a: Vector2 = _grid_to_local(points[e[0]])
			var b: Vector2 = _grid_to_local(points[e[1]])
			draw_line(a, b, INK, 7.0, true)
		for p in points:
			draw_circle(_grid_to_local(p), 6.0, INK)
		if demo_active and not edges.is_empty():
			var e: Array = edges[demo_edge_i]
			var a: Vector2 = _grid_to_local(points[e[0]])
			var b: Vector2 = _grid_to_local(points[e[1]])
			var t: float = clampf(demo_timer / DEMO_MOVE_TIME, 0.0, 1.0) if demo_moving else 1.0
			var cursor: Vector2 = a.lerp(b, t)
			draw_circle(a, 9.0, DEMO)
			draw_circle(b, 9.0, DEMO)
			draw_circle(cursor, 13.0, DEMO)
	else:
		for e in drawn_edges:
			var a: Vector2 = _grid_to_local(points[e[0]])
			var b: Vector2 = _grid_to_local(points[e[1]])
			draw_line(a, b, INK, 7.0, true)
		if dragging and drag_from >= 0 and not coloring_mode:
			draw_line(_grid_to_local(points[drag_from]), drag_pos, PREVIEW, 6.0, true)
		if not coloring_mode:
			for p in points:
				var pos: Vector2 = _grid_to_local(p)
				draw_circle(pos, 11.0, DOT)
				draw_circle(pos, 5.4, Color.WHITE)
