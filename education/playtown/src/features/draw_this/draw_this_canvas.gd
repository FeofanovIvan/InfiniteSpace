class_name DrawThisCanvas
extends Control

const BEE: Texture2D = preload("res://education/playtown/assets/draw_this/bee.webp")
const HIVE: Texture2D = preload("res://education/playtown/assets/draw_this/hive.webp")
const BUTTERFLY: Texture2D = preload("res://education/playtown/assets/draw_this/butterfly.webp")
const FLOWER: Texture2D = preload("res://education/playtown/assets/draw_this/flower.webp")
const BEETLE: Texture2D = preload("res://education/playtown/assets/draw_this/beetle.webp")
const CLOUD: Texture2D = preload("res://education/playtown/assets/draw_this/cloud.webp")
const SNAIL_BODY: Texture2D = preload("res://education/playtown/assets/draw_this/snail_body.webp")
const SNAIL_COMPLETE: Texture2D = preload("res://education/playtown/assets/draw_this/snail_complete.webp")

var exercise_index := 0
var draw_color := Color("#168fd0")
var strokes: Array[Dictionary] = []
var active_points := PackedVector2Array()
var pointer_active := false
var preview_time := 0.0
var eraser_enabled := false


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	clip_contents = true
	gui_input.connect(_on_gui_input)
	set_process(true)


func set_exercise(index: int) -> void:
	exercise_index = clampi(index, 0, 4)
	clear_drawing()
	preview_time = 0.0
	queue_redraw()


func set_draw_color(color: Color) -> void:
	draw_color = color
	eraser_enabled = false


func set_eraser_enabled(enabled: bool) -> void:
	eraser_enabled = enabled
	pointer_active = false
	active_points = PackedVector2Array()
	queue_redraw()


func clear_drawing() -> void:
	strokes.clear()
	active_points = PackedVector2Array()
	pointer_active = false
	queue_redraw()


func _process(delta: float) -> void:
	preview_time = fmod(preview_time + delta, 4.0)
	if exercise_index in [0, 2, 3]:
		queue_redraw()


func _on_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		accept_event()
		if event.pressed:
			_begin_stroke(event.position)
		else:
			_end_stroke()
	elif event is InputEventMouseMotion and pointer_active and Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		accept_event()
		_add_point(event.position)
	elif event is InputEventScreenTouch:
		accept_event()
		if event.pressed:
			_begin_stroke(event.position)
		else:
			_end_stroke()
	elif event is InputEventScreenDrag and pointer_active:
		accept_event()
		_add_point(event.position)


func _begin_stroke(point: Vector2) -> void:
	if not _is_drawable_point(point):
		return
	pointer_active = true
	if eraser_enabled:
		active_points = PackedVector2Array()
		_erase_at(point)
		return
	active_points = PackedVector2Array([point])
	queue_redraw()


func _add_point(point: Vector2) -> void:
	if not _is_drawable_point(point):
		_end_stroke()
		return
	if eraser_enabled:
		_erase_at(point)
		return
	if active_points.is_empty() or active_points[-1].distance_to(point) >= 2.5:
		active_points.append(point)
		queue_redraw()


func _end_stroke() -> void:
	if not pointer_active:
		return
	pointer_active = false
	if eraser_enabled:
		active_points = PackedVector2Array()
		return
	if active_points.size() > 1:
		strokes.append({"points": active_points, "color": draw_color})
	active_points = PackedVector2Array()
	queue_redraw()


func _is_drawable_point(point: Vector2) -> bool:
	return Rect2(Vector2.ZERO, size).grow(-4.0).has_point(point) and not _preview_rect().grow(8.0).has_point(point)


func _draw() -> void:
	_draw_paper()
	_draw_exercise(false, Rect2(Vector2.ZERO, size))
	_draw_user_strokes()
	_draw_preview()


func _draw_paper() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), Color("#fffef9"))
	var spacing := clampf(minf(size.x, size.y) * 0.045, 20.0, 38.0)
	var grid_color := Color(0.53, 0.72, 0.78, 0.20)
	var x := spacing
	while x < size.x:
		draw_line(Vector2(x, 0.0), Vector2(x, size.y), grid_color, 1.0)
		x += spacing
	var y := spacing
	while y < size.y:
		draw_line(Vector2(0.0, y), Vector2(size.x, y), grid_color, 1.0)
		y += spacing


func _draw_exercise(preview: bool, area: Rect2) -> void:
	match exercise_index:
		0:
			_draw_route_exercise(BEE, HIVE, area, preview, 0)
		1:
			_draw_snail(area, preview)
		2:
			_draw_route_exercise(BUTTERFLY, FLOWER, area, preview, 1)
		3:
			_draw_route_exercise(BEETLE, FLOWER, area, preview, 3)
		4:
			_draw_cloud(area, preview)


func _draw_route_exercise(actor: Texture2D, target: Texture2D, area: Rect2, preview: bool, kind: int) -> void:
	var actor_size := area.size * (Vector2(0.14, 0.28) if preview else Vector2(0.16, 0.32))
	var target_size := area.size * (Vector2(0.17, 0.34) if preview else Vector2(0.19, 0.38))
	var start := area.position + area.size * Vector2(0.11, 0.61)
	var finish := area.position + area.size * Vector2(0.84, 0.57 if kind != 1 else 0.43)
	var path := _route_points(start, finish, kind, 80, area.size.y)
	if preview:
		_draw_polyline(path, Color("#80888c"), maxf(1.8, area.size.y * 0.018), false)
		var phase := _ping_pong_phase()
		var moving_pos := _point_at(path, phase)
		var moving_size := actor_size * 0.56
		_draw_texture_fitted(actor, Rect2(moving_pos - moving_size * 0.5, moving_size))
	else:
		_draw_dotted_portion(path, 0.52, Color("#96999c"), maxf(3.0, area.size.y * 0.008))
		_draw_texture_fitted(actor, Rect2(start - actor_size * 0.5, actor_size))
	_draw_texture_fitted(target, Rect2(finish - target_size * 0.5, target_size))


func _draw_snail(area: Rect2, preview: bool) -> void:
	if preview:
		_draw_texture_fitted(SNAIL_COMPLETE, area.grow(-area.size.y * 0.08))
		return
	var body_rect := Rect2(area.position + area.size * Vector2(0.08, 0.18), area.size * Vector2(0.67, 0.70))
	_draw_texture_fitted(SNAIL_BODY, body_rect)


func _draw_cloud(area: Rect2, preview: bool) -> void:
	var cloud_rect := Rect2(area.position + area.size * Vector2(0.25, 0.12), area.size * Vector2(0.50, 0.46))
	_draw_texture_fitted(CLOUD, cloud_rect)
	if preview:
		for index in range(5):
			var x := area.position.x + area.size.x * (0.34 + index * 0.08)
			draw_line(Vector2(x, area.position.y + area.size.y * 0.58), Vector2(x - area.size.x * 0.035, area.position.y + area.size.y * 0.84), Color("#278dcc"), maxf(2.0, area.size.y * 0.02), true)
		return
	for index in range(7):
		var x := area.position.x + area.size.x * (0.26 + index * 0.08)
		var rain := PackedVector2Array([Vector2(x, area.position.y + area.size.y * 0.57), Vector2(x - area.size.x * 0.045, area.position.y + area.size.y * 0.77)])
		_draw_dotted_portion(rain, 0.52, Color("#96999c"), maxf(3.0, area.size.y * 0.008))


func _draw_preview() -> void:
	var rect := _preview_rect()
	draw_style_box(_panel_style(Color("#fff0cfee"), Color("#62bd28"), 3, 18), rect)
	_draw_exercise(true, rect.grow(-rect.size.y * 0.08))


func _preview_rect() -> Rect2:
	var preview_size := Vector2(minf(size.x * 0.24, size.y * 0.39), minf(size.y * 0.27, size.x * 0.18))
	preview_size.x = maxf(preview_size.x, preview_size.y * 1.35)
	return Rect2(Vector2(size.x - preview_size.x - size.x * 0.018, size.y * 0.025), preview_size)


func _draw_user_strokes() -> void:
	var width := clampf(minf(size.x, size.y) * 0.020, 8.0, 22.0)
	for stroke in strokes:
		_draw_stroke(stroke["points"] as PackedVector2Array, stroke["color"] as Color, width)
	if not active_points.is_empty():
		_draw_stroke(active_points, draw_color, width)


func _erase_at(point: Vector2) -> void:
	var radius := clampf(minf(size.x, size.y) * 0.045, 18.0, 46.0)
	var remaining: Array[Dictionary] = []
	for stroke in strokes:
		var points := stroke["points"] as PackedVector2Array
		var color := stroke["color"] as Color
		var part := PackedVector2Array()
		for stroke_point in points:
			if stroke_point.distance_to(point) <= radius:
				if part.size() > 1:
					remaining.append({"points": part, "color": color})
				part = PackedVector2Array()
			else:
				part.append(stroke_point)
		if part.size() > 1:
			remaining.append({"points": part, "color": color})
	strokes = remaining
	queue_redraw()


func _draw_stroke(points: PackedVector2Array, color: Color, width: float) -> void:
	if points.size() == 1:
		draw_circle(points[0], width * 0.5, color)
		return
	draw_polyline(points, color, width, true)
	draw_circle(points[0], width * 0.5, color)
	draw_circle(points[-1], width * 0.5, color)


func _route_points(start: Vector2, finish: Vector2, kind: int, count: int, height_scale: float) -> PackedVector2Array:
	var result := PackedVector2Array()
	for index in range(count):
		var t := float(index) / float(count - 1)
		var point := start.lerp(finish, t)
		if kind == 0:
			point.y += sin(t * TAU * 4.0) * height_scale * 0.065
		elif kind == 1:
			point.y += sin(t * TAU * 2.5) * height_scale * 0.085 + sin(t * TAU) * height_scale * 0.035
		else:
			var step_t := fmod(t * 6.0, 1.0)
			point.y += (absf(step_t * 2.0 - 1.0) - 0.5) * height_scale * 0.12
		result.append(point)
	return result


func _spiral_points(center: Vector2, radius: float, count: int) -> PackedVector2Array:
	var result := PackedVector2Array()
	for index in range(count):
		var t := float(index) / float(count - 1)
		var angle := t * TAU * 3.15
		var r := radius * (0.08 + t * 0.92)
		result.append(center + Vector2(cos(angle), sin(angle)) * r)
	return result


func _draw_dotted_portion(points: PackedVector2Array, portion: float, color: Color, width: float) -> void:
	var end_index := mini(points.size() - 1, maxi(1, floori(float(points.size() - 1) * portion)))
	for index in range(end_index):
		if index % 4 < 2:
			draw_line(points[index], points[index + 1], color, width, true)


func _draw_polyline(points: PackedVector2Array, color: Color, width: float, dotted: bool) -> void:
	if dotted:
		_draw_dotted_portion(points, 1.0, color, width)
	else:
		draw_polyline(points, color, width, true)


func _point_at(points: PackedVector2Array, phase: float) -> Vector2:
	if points.is_empty():
		return Vector2.ZERO
	var scaled := phase * float(points.size() - 1)
	var index := mini(points.size() - 2, floori(scaled))
	return points[index].lerp(points[index + 1], scaled - float(index))


func _ping_pong_phase() -> float:
	var t := preview_time / 4.0
	return t * 2.0 if t <= 0.5 else (1.0 - t) * 2.0


func _draw_texture_fitted(texture: Texture2D, rect: Rect2) -> void:
	if texture == null or rect.size.x <= 0.0 or rect.size.y <= 0.0:
		return
	var texture_size := Vector2(texture.get_width(), texture.get_height())
	var scale_factor := minf(rect.size.x / texture_size.x, rect.size.y / texture_size.y)
	var fitted_size := texture_size * scale_factor
	var fitted_rect := Rect2(rect.position + (rect.size - fitted_size) * 0.5, fitted_size)
	draw_texture_rect(texture, fitted_rect, false)


func _panel_style(fill: Color, border: Color, border_width: int, radius: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.border_color = border
	style.set_border_width_all(border_width)
	style.set_corner_radius_all(radius)
	return style
