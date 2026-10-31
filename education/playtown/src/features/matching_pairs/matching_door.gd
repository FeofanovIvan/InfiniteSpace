class_name MatchingDoor
extends Control

signal selected(door: MatchingDoor)

const DOORS_ATLAS: Texture2D = preload("res://education/playtown/assets/matching_pairs/doors_atlas.png")

var symbol_kind := "circle"
var symbol_color := Color("#ef3f43")
var revealed := false
var matched := false
var _pressed := false
var _closed_texture: AtlasTexture
var _open_texture: AtlasTexture

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	focus_mode = Control.FOCUS_NONE
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	_build_atlas_textures()
	gui_input.connect(_on_gui_input)
	resized.connect(_on_resized)
	_on_resized()

func configure(kind: String, color: Color) -> void:
	symbol_kind = kind
	symbol_color = color
	queue_redraw()

func set_revealed(value: bool, animated := true) -> void:
	if revealed == value or matched:
		return
	if animated:
		var close_tween := create_tween()
		close_tween.tween_property(self, "scale:x", 0.06, 0.12).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		await close_tween.finished
	revealed = value
	queue_redraw()
	if animated:
		var open_tween := create_tween()
		open_tween.tween_property(self, "scale:x", 1.0, 0.18).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		await open_tween.finished

func play_match_animation() -> void:
	matched = true
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	var tween := create_tween().set_parallel(true)
	tween.tween_property(self, "scale", Vector2(1.16, 1.16), 0.16).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "rotation", deg_to_rad(5.0), 0.16)
	tween.chain().tween_property(self, "scale", Vector2(0.1, 0.1), 0.24).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
	tween.tween_property(self, "modulate:a", 0.0, 0.24).set_delay(0.12)

func _build_atlas_textures() -> void:
	_closed_texture = AtlasTexture.new()
	_closed_texture.atlas = DOORS_ATLAS
	_closed_texture.region = Rect2(0, 0, 768, 1024)
	_open_texture = AtlasTexture.new()
	_open_texture.atlas = DOORS_ATLAS
	_open_texture.region = Rect2(768, 0, 768, 1024)

func _on_resized() -> void:
	pivot_offset = size * 0.5
	queue_redraw()

func _on_gui_input(event: InputEvent) -> void:
	if matched:
		return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			_pressed = true
			scale = Vector2(0.96, 0.96)
		else:
			var should_select := _pressed
			_pressed = false
			scale = Vector2.ONE
			if should_select and Rect2(Vector2.ZERO, size).has_point(event.position):
				selected.emit(self)
	elif event is InputEventScreenTouch:
		if event.pressed:
			_pressed = true
			scale = Vector2(0.96, 0.96)
		else:
			var should_select := _pressed
			_pressed = false
			scale = Vector2.ONE
			if should_select and Rect2(Vector2.ZERO, size).has_point(event.position):
				selected.emit(self)

func _draw() -> void:
	if _closed_texture == null or _open_texture == null:
		return
	var texture := _open_texture if revealed else _closed_texture
	draw_texture_rect(texture, Rect2(Vector2.ZERO, size), false)
	if revealed:
		_draw_symbol()

func _draw_symbol() -> void:
	var center := Vector2(size.x * 0.57, size.y * 0.53)
	var radius := minf(size.x, size.y) * 0.135
	var outline := symbol_color.darkened(0.36)
	match symbol_kind:
		"circle":
			draw_circle(center, radius, symbol_color)
			draw_arc(center, radius, 0.0, TAU, 48, outline, maxf(2.0, radius * 0.13), true)
		"square":
			var rect := Rect2(center - Vector2.ONE * radius, Vector2.ONE * radius * 2.0)
			draw_rect(rect, symbol_color, true)
			draw_rect(rect, outline, false, maxf(2.0, radius * 0.13), true)
		"triangle":
			var points := PackedVector2Array([
				center + Vector2(0, -radius * 1.12),
				center + Vector2(radius * 1.08, radius),
				center + Vector2(-radius * 1.08, radius)
			])
			_draw_polygon_shape(points, outline, radius)
		"diamond":
			var points := PackedVector2Array([
				center + Vector2(0, -radius * 1.2),
				center + Vector2(radius, 0),
				center + Vector2(0, radius * 1.2),
				center + Vector2(-radius, 0)
			])
			_draw_polygon_shape(points, outline, radius)
		"star":
			var points := PackedVector2Array()
			for index in range(10):
				var point_radius := radius * (1.18 if index % 2 == 0 else 0.5)
				var angle := -PI * 0.5 + float(index) * PI / 5.0
				points.append(center + Vector2(cos(angle), sin(angle)) * point_radius)
			_draw_polygon_shape(points, outline, radius)
	draw_circle(center - Vector2(radius * 0.28, radius * 0.30), radius * 0.18, Color(1, 1, 1, 0.55))

func _draw_polygon_shape(points: PackedVector2Array, outline: Color, radius: float) -> void:
	draw_colored_polygon(points, symbol_color)
	var closed_points := points.duplicate()
	closed_points.append(points[0])
	draw_polyline(closed_points, outline, maxf(2.0, radius * 0.13), true)
