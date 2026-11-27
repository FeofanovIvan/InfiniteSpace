extends "res://learning/src/features/draw_this/draw_this_canvas.gd"
## Story-only paper; inherits the original touch, mouse, pencil and eraser API.
var _paper_size := Vector2.ZERO
var corner_radius: float = 0.0
func _ready() -> void:
	super._ready()
	set_process(false)
	resized.connect(_resize_ink)
	_resize_ink()

func _is_drawable_point(point: Vector2) -> bool:
	if not Rect2(Vector2.ZERO, size).has_point(point):
		return false
	# Same rounded inner aperture as the native blue frame, including input.
	var r: float = clampf(corner_radius, 0.0, minf(size.x, size.y) * 0.5)
	if r <= 0.0:
		return true
	var nearest := Vector2(clampf(point.x, r, size.x - r), clampf(point.y, r, size.y - r))
	return point.distance_squared_to(nearest) <= r * r

func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), Color.WHITE)
	_draw_user_strokes()

func _end_stroke() -> void:
	if not pointer_active:
		return
	pointer_active = false
	if not eraser_enabled and not active_points.is_empty():
		strokes.append({"points": active_points, "color": draw_color})
	active_points = PackedVector2Array()
	queue_redraw()

func _erase_at(point: Vector2) -> void:
	var radius: float = clampf(minf(size.x, size.y) * 0.045, 18.0, 46.0)
	var remaining: Array[Dictionary] = []
	for stroke in strokes:
		var part := PackedVector2Array()
		for p in stroke["points"]:
			if p.distance_to(point) <= radius:
				if not part.is_empty():
					remaining.append({"points": part, "color": stroke["color"]})
				part = PackedVector2Array()
			else:
				part.append(p)
		if not part.is_empty():
			remaining.append({"points": part, "color": stroke["color"]})
	strokes = remaining
	queue_redraw()

func _resize_ink() -> void:
	if size.x <= 0.0 or size.y <= 0.0:
		return
	if _paper_size.x > 0.0 and _paper_size.y > 0.0 and _paper_size != size:
		_end_stroke()
		var factor: Vector2 = size / _paper_size
		for stroke in strokes:
			var points: PackedVector2Array = stroke["points"]
			for i in range(points.size()):
				points[i] *= factor
			stroke["points"] = points
	_paper_size = size
	queue_redraw()
