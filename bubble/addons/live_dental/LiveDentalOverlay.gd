extends Node2D
## Lightweight mouth/teeth overlay attached to the SAME Bubble instance.
## No separate full-screen face scene; camera simply zooms closer to Bubble.

signal progress_changed(value: float)
signal completed

var active: bool = false
var completed_once: bool = false
var _time: float = 0.0
var _plaque: Array[float] = []

const TOOTH_CENTERS: Array[Vector2] = [
	Vector2(-48.0, -26.0), Vector2(-24.0, -26.0), Vector2(0.0, -26.0), Vector2(24.0, -26.0), Vector2(48.0, -26.0),
	Vector2(-48.0, 6.0), Vector2(-24.0, 6.0), Vector2(0.0, 6.0), Vector2(24.0, 6.0), Vector2(48.0, 6.0)
]

func _ready() -> void:
	position = Vector2(0.0, -252.0)
	visible = false
	set_process(true)
	reset_dirty_teeth()

func reset_dirty_teeth() -> void:
	active = true
	completed_once = false
	visible = true
	_plaque.clear()
	for _i in range(TOOTH_CENTERS.size()):
		_plaque.append(1.0)
	progress_changed.emit(0.0)
	queue_redraw()

func clear_overlay() -> void:
	active = false
	completed_once = false
	visible = false
	_plaque.clear()
	queue_redraw()

func get_progress() -> float:
	if _plaque.is_empty():
		return 0.0
	var total: float = 0.0
	for value in _plaque:
		total += float(value)
	return clampf(1.0 - total / float(_plaque.size()), 0.0, 1.0)

func brush_at(local_point: Vector2, travel: float = 6.0) -> float:
	if not active or completed_once or travel < 0.8:
		return get_progress()
	for i in range(_plaque.size()):
		var center: Vector2 = TOOTH_CENTERS[i]
		var d: float = local_point.distance_to(center)
		if d <= 28.0:
			var weight: float = 1.0 - d / 28.0
			_plaque[i] = maxf(0.0, float(_plaque[i]) - minf(travel, 30.0) * 0.035 * weight)
	var p: float = get_progress()
	progress_changed.emit(p)
	if p >= 0.92 and not completed_once:
		completed_once = true
		active = false
		completed.emit()
	queue_redraw()
	return p

func _process(delta: float) -> void:
	_time += delta
	if visible:
		queue_redraw()

func _draw() -> void:
	if not visible:
		return
	# Soft face patch so the mouth sits naturally on the same Bubble body.
	_ellipse(Vector2(0.0, -10.0), 106.0, 72.0, Color(0.82, 0.68, 0.95, 0.86))
	_ellipse_outline(Vector2(0.0, -10.0), 106.0, 72.0, Color(0.95, 0.90, 1.0, 0.30), 2.0)
	# Open mouth.
	_ellipse(Vector2(0.0, -8.0), 86.0, 54.0, Color(0.28, 0.02, 0.11, 0.92))
	_ellipse_outline(Vector2(0.0, -8.0), 86.0, 54.0, Color(0.90, 0.52, 0.66, 0.68), 3.0)
	# Gums.
	_ellipse(Vector2(0.0, -36.0), 66.0, 17.0, Color(0.92, 0.64, 0.78, 0.92))
	_ellipse(Vector2(0.0, 15.0), 66.0, 17.0, Color(0.92, 0.64, 0.78, 0.92))
	# Teeth.
	for i in range(TOOTH_CENTERS.size()):
		var c: Vector2 = TOOTH_CENTERS[i]
		var top: bool = i < 5
		var tooth_h: float = 24.0 if top else 23.0
		var rect := Rect2(c - Vector2(10.0, 11.0), Vector2(20.0, tooth_h))
		draw_rect(rect, Color(0.98, 0.98, 0.97, 0.98), true)
		draw_rect(rect, Color(0.84, 0.85, 0.86, 0.55), false, 1.4)
		var grime: float = 0.85 * clampf(float(_plaque[i]), 0.0, 1.0)
		if grime > 0.01:
			var gx: float = rect.position.x + rect.size.x * (0.24 + 0.12 * sin(float(i) * 1.7))
			var gw: float = 4.0 + 2.0 * absf(sin(float(i) * 2.1))
			var gy: float = rect.position.y + (2.0 if top else 1.0)
			var gh: float = rect.size.y - 4.0
			draw_rect(Rect2(Vector2(gx, gy), Vector2(gw, gh)), Color(0.48, 0.32, 0.17, grime), true)
			if i % 2 == 0:
				draw_circle(Vector2(rect.position.x + rect.size.x * 0.72, rect.position.y + rect.size.y * 0.52), 2.8, Color(0.43, 0.28, 0.12, grime * 0.85))
	# Saliva highlight.
	for j in range(3):
		var p: float = fposmod(_time * 0.42 + float(j) * 0.33, 1.0)
		draw_arc(Vector2(0.0, -1.0 + float(j) * 3.0), 23.0 + p * 18.0, 0.25, PI - 0.25, 16, Color(0.86, 0.98, 1.0, (1.0 - p) * 0.11), 1.1, true)

func _ellipse(center: Vector2, rx: float, ry: float, color: Color) -> void:
	var points := PackedVector2Array()
	for i in range(49):
		var a: float = TAU * float(i) / 48.0
		points.append(center + Vector2(cos(a) * rx, sin(a) * ry))
	draw_colored_polygon(points, color)

func _ellipse_outline(center: Vector2, rx: float, ry: float, color: Color, width: float) -> void:
	var points := PackedVector2Array()
	for i in range(49):
		var a: float = TAU * float(i) / 48.0
		points.append(center + Vector2(cos(a) * rx, sin(a) * ry))
	draw_polyline(points, color, width, true)
