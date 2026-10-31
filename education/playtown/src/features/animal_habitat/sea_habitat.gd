extends Control

@export var foreground_only := false
var phase := 0.0

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	clip_contents = true
	set_process(true)

func _process(delta: float) -> void:
	phase = fmod(phase + delta, TAU * 10.0)
	queue_redraw()

func _draw() -> void:
	if foreground_only:
		_draw_wave_layer(size.y * 0.72, 12.0, 0.036, phase * 0.62 + 1.7, Color("#0879bd"))
		return
	draw_rect(Rect2(Vector2.ZERO, size), Color("#aee6ff"))
	var sun_radius: float = minf(size.x, size.y) * 0.10
	draw_circle(Vector2(size.x * 0.78, size.y * 0.22), sun_radius, Color("#ffe56f"))
	_draw_cloud(Vector2(size.x * 0.23, size.y * 0.22), minf(size.x, size.y) * 0.055)
	_draw_wave_layer(size.y * 0.43, 13.0, 0.030, phase * 1.15, Color("#55c9ef"))
	_draw_wave_layer(size.y * 0.57, 17.0, 0.024, -phase * 0.82, Color("#269fd9"))

func _draw_cloud(center: Vector2, radius: float) -> void:
	var cloud_color := Color(1, 1, 1, 0.88)
	draw_circle(center + Vector2(-radius, radius * 0.25), radius * 0.78, cloud_color)
	draw_circle(center, radius, cloud_color)
	draw_circle(center + Vector2(radius, radius * 0.28), radius * 0.72, cloud_color)
	draw_rect(Rect2(center + Vector2(-radius * 1.65, radius * 0.20), Vector2(radius * 3.2, radius * 0.85)), cloud_color)

func _draw_wave_layer(base_y: float, amplitude: float, frequency: float, offset: float, color: Color) -> void:
	var polygon := PackedVector2Array()
	polygon.append(Vector2(0.0, size.y))
	polygon.append(Vector2(0.0, base_y + sin(offset) * amplitude))
	var steps: int = maxi(24, int(size.x / 10.0))
	for step in range(1, steps + 1):
		var x: float = size.x * float(step) / float(steps)
		var y: float = base_y + sin(x * frequency + offset) * amplitude
		polygon.append(Vector2(x, y))
	polygon.append(Vector2(size.x, size.y))
	draw_colored_polygon(polygon, color)
	var crest := PackedVector2Array()
	for step in range(steps + 1):
		var x: float = size.x * float(step) / float(steps)
		var y: float = base_y + sin(x * frequency + offset) * amplitude
		crest.append(Vector2(x, y))
	draw_polyline(crest, Color(1, 1, 1, 0.65), 4.0, true)
