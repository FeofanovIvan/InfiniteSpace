extends "res://education/playtown/src/features/tracing/shape_trace_grid.gd"
## MIKA Build Shapes 1.2: truly square, white, proportionally padded paper.
## The interactive ShapeTraceGrid parent continues to own input, demo,
## drawing recognition, painting coverage, and game-state logic.

const PAPER_V12 := Color.WHITE
const RULE_V12 := Color("#d9e3ee")
const RULE_BORDER_V12 := Color("#96afc5")
const PAPER_BORDER_V12 := Color("#c4d2df")
const COORD_V12 := Color("#42647b")
const SHAPE_INK_V12 := Color("#214c6f")
const TRACE_PREVIEW_V12 := Color("#24bde7")
const TRACE_DOT_V12 := Color("#235f89")
const DEMO_V12 := Color("#fa778c")

const PAPER_MARGIN_RATIO := 0.115
var _paper_side: float = 0.0

func set_layout(rect: Rect2) -> void:
	# The original class subtracts just ONE margin before dividing by 6.
	# This made the white paper extend beyond its actual square. We reserve
	# an equal margin on all FOUR sides instead.
	_paper_side = minf(rect.size.x, rect.size.y)
	position = rect.position + (rect.size - Vector2.ONE * _paper_side) * 0.5
	margin = _paper_side * PAPER_MARGIN_RATIO
	cell = (_paper_side - 2.0 * margin) / float(GRID_N)
	grid_origin = Vector2.ONE * margin
	if coloring_mode:
		_build_coverage()
	queue_redraw()

func _draw() -> void:
	if _paper_side <= 0.0 or cell <= 0.0:
		return
	# The only paper background. No overlapping translucent panels.
	var paper := Rect2(Vector2.ZERO, Vector2.ONE * _paper_side)
	draw_rect(paper, PAPER_V12, true)
	var grid_end: Vector2 = grid_origin + Vector2.ONE * cell * float(GRID_N)
	var rule_thickness: float = maxf(1.0, cell * 0.026)
	for k in range(GRID_N + 1):
		var xx: float = grid_origin.x + float(k) * cell
		var yy: float = grid_origin.y + float(k) * cell
		draw_line(Vector2(xx, grid_origin.y), Vector2(xx, grid_end.y), RULE_V12, rule_thickness, true)
		draw_line(Vector2(grid_origin.x, yy), Vector2(grid_end.x, yy), RULE_V12, rule_thickness, true)
	draw_rect(Rect2(grid_origin, Vector2.ONE * cell * float(GRID_N)), RULE_BORDER_V12, false, maxf(1.0, cell * 0.034), true)
	draw_rect(paper, PAPER_BORDER_V12, false, maxf(1.0, _paper_side * 0.004), true)

	var font: Font = ThemeDB.fallback_font
	var label_px: int = maxi(8, roundi(cell * 0.31))
	for i in range(GRID_N):
		var coord: String = str(i + 1)
		var cx: float = grid_origin.x + (float(i) + 0.5) * cell
		var cy: float = grid_origin.y + (float(i) + 0.5) * cell
		draw_string(font, Vector2(cx - label_px * 0.25, margin * 0.62), coord, HORIZONTAL_ALIGNMENT_CENTER, -1, label_px, COORD_V12)
		draw_string(font, Vector2(margin * 0.22, cy + label_px * 0.32), coord, HORIZONTAL_ALIGNMENT_CENTER, -1, label_px, COORD_V12)

	if points.size() < 2:
		return
	var shape_polygon: PackedVector2Array = _shape_polygon()
	if solid_fill_visible or fill_complete:
		draw_colored_polygon(shape_polygon, fill_color)
	elif coloring_mode:
		for paint_polygon in paint_polygons:
			draw_colored_polygon(paint_polygon, fill_color)

	var ink_width: float = maxf(1.0, cell * 0.11)
	if not interactive:
		for edge in edges:
			var p0: Vector2 = _grid_to_local(points[edge[0]])
			var p1: Vector2 = _grid_to_local(points[edge[1]])
			draw_line(p0, p1, SHAPE_INK_V12, ink_width, true)
		for point in points:
			draw_circle(_grid_to_local(point), maxf(2.0, cell * 0.085), SHAPE_INK_V12)
		if demo_active and not edges.is_empty():
			var active: Array = edges[demo_edge_i]
			var p0: Vector2 = _grid_to_local(points[active[0]])
			var p1: Vector2 = _grid_to_local(points[active[1]])
			var t: float = clampf(demo_timer / DEMO_MOVE_TIME, 0.0, 1.0) if demo_moving else 1.0
			var cursor: Vector2 = p0.lerp(p1, t)
			draw_circle(p0, maxf(2.0, cell * 0.11), DEMO_V12)
			draw_circle(p1, maxf(2.0, cell * 0.11), DEMO_V12)
			draw_circle(cursor, maxf(3.0, cell * 0.15), DEMO_V12)
	else:
		for edge in drawn_edges:
			var p0: Vector2 = _grid_to_local(points[edge[0]])
			var p1: Vector2 = _grid_to_local(points[edge[1]])
			draw_line(p0, p1, SHAPE_INK_V12, ink_width, true)
		if dragging and drag_from >= 0 and not coloring_mode:
			draw_line(_grid_to_local(points[drag_from]), drag_pos, TRACE_PREVIEW_V12, ink_width * 0.85, true)
		if not coloring_mode:
			for point in points:
				var dot: Vector2 = _grid_to_local(point)
				draw_circle(dot, maxf(3.0, cell * 0.15), TRACE_DOT_V12)
				draw_circle(dot, maxf(1.5, cell * 0.067), Color.WHITE)
