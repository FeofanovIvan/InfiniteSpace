extends Node2D
signal progress_changed(value: float)
signal completed

var active: bool = false
var completed_once: bool = false
var _plaque: Array[float] = []
var _time: float = 0.0

const TEETH: Array[Dictionary] = [
	{"center":Vector2(-36.0,-18.0),"size":Vector2(12.0,18.0)},
	{"center":Vector2(-18.0,-18.0),"size":Vector2(12.0,19.0)},
	{"center":Vector2(  0.0,-18.0),"size":Vector2(12.0,20.0)},
	{"center":Vector2( 18.0,-18.0),"size":Vector2(12.0,19.0)},
	{"center":Vector2( 36.0,-18.0),"size":Vector2(12.0,18.0)},
	{"center":Vector2(-36.0, 14.0),"size":Vector2(12.0,17.0)},
	{"center":Vector2(-18.0, 14.0),"size":Vector2(12.0,18.0)},
	{"center":Vector2(  0.0, 14.0),"size":Vector2(12.0,19.0)},
	{"center":Vector2( 18.0, 14.0),"size":Vector2(12.0,18.0)},
	{"center":Vector2( 36.0, 14.0),"size":Vector2(12.0,17.0)}
]

func _ready() -> void:
	position = Vector2(0.0, -248.0)
	visible = false
	set_process(true)
	_stop_internal()

func start_cleaning() -> void:
	active = true
	completed_once = false
	visible = true
	_plaque.clear()
	for _i in range(TEETH.size()):
		_plaque.append(1.0)
	progress_changed.emit(0.0)
	queue_redraw()

func stop_cleaning() -> void:
	_stop_internal()
	queue_redraw()

func _stop_internal() -> void:
	active = false
	completed_once = false
	visible = false
	_plaque.clear()

func get_progress() -> float:
	if _plaque.is_empty():
		return 0.0
	var total := 0.0
	for v in _plaque:
		total += float(v)
	return clampf(1.0 - total / float(_plaque.size()), 0.0, 1.0)

func brush_at(local_point: Vector2, travel: float = 6.0) -> float:
	if not active or completed_once or travel < 1.0:
		return get_progress()
	for i in range(_plaque.size()):
		var tooth: Dictionary = TEETH[i]
		var center: Vector2 = tooth["center"]
		var d: float = local_point.distance_to(center)
		if d <= 18.0:
			var weight: float = 1.0 - d / 18.0
			_plaque[i] = maxf(0.0, float(_plaque[i]) - minf(travel, 24.0) * 0.045 * weight)
	var p := get_progress()
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
	for i in range(TEETH.size()):
		var tooth: Dictionary = TEETH[i]
		var c: Vector2 = tooth["center"]
		var size: Vector2 = tooth["size"]
		var plaque: float = 0.86 * clampf(float(_plaque[i]), 0.0, 1.0)
		_draw_tooth(c, size)
		if plaque > 0.01:
			_draw_grime(c, size, plaque, i)

func _draw_tooth(center: Vector2, size: Vector2) -> void:
	var x0: float = center.x - size.x * 0.5
	var x1: float = center.x + size.x * 0.5
	var top: float = center.y - size.y * 0.5
	var bottom: float = center.y + size.y * 0.5
	var pts := PackedVector2Array([
		Vector2(x0 + 1.3, top), Vector2(x1 - 1.3, top), Vector2(x1, top + 3.2),
		Vector2(x1 - 0.6, bottom - 4.0), Vector2(center.x, bottom), Vector2(x0 + 0.6, bottom - 4.0), Vector2(x0, top + 3.2)
	])
	draw_colored_polygon(pts, Color(0.98, 0.985, 0.975, 0.98))
	draw_polyline(PackedVector2Array([pts[0],pts[1],pts[2],pts[3],pts[4],pts[5],pts[6],pts[0]]), Color(0.84,0.87,0.90,0.56), 1.0, true)
	draw_line(Vector2(x0 + 2.2, top + 3.2), Vector2(x0 + 3.5, bottom - 5.5), Color(1.0,1.0,1.0,0.35), 1.0, true)

func _draw_grime(center: Vector2, size: Vector2, alpha: float, index: int) -> void:
	var left: float = center.x - size.x * 0.5 + 1.8
	var top: float = center.y - size.y * 0.5 + 1.8
	var height: float = size.y - 4.0
	var streak_x: float = left + size.x * (0.35 + 0.10 * sin(float(index) * 1.7))
	var streak_w: float = 2.6 + 1.3 * absf(sin(float(index) * 2.3))
	draw_rect(Rect2(Vector2(streak_x, top), Vector2(streak_w, height)), Color(0.49, 0.34, 0.17, alpha), true)
	if index % 2 == 0:
		draw_circle(Vector2(left + size.x * 0.72, top + height * 0.54), 1.9, Color(0.43,0.28,0.11,alpha*0.88), true)
