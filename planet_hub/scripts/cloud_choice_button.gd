@tool
extends Button
## A native-drawn soft speech cloud with a tiny tail toward the character.
## Same palette as Planet Hub: beige Launch when selected, blue Simulator otherwise.
## No raster texture; scales with the viewport.
@export var chosen: bool = false:
	set(value):
		chosen = value
		queue_redraw()

var _text_label: Label

func _ready() -> void:
	flat = true
	focus_mode = Control.FOCUS_NONE
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	mouse_filter = Control.MOUSE_FILTER_STOP
	clip_contents = false
	for state in ["normal", "hover", "pressed", "disabled", "focus"]:
		add_theme_stylebox_override(state, StyleBoxEmpty.new())
		add_theme_color_override("font_" + state + "_color", Color.TRANSPARENT)
	# The label is deliberately separate: Button's built-in baseline does
	# not center long translated sentences reliably inside cloud silhouettes.
	_text_label = Label.new()
	_text_label.name = "CloudText"
	_text_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_text_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_text_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_text_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_text_label.add_theme_color_override("font_color", Color("092a42"))
	add_child(_text_label)
	resized.connect(_layout_text)
	_layout_text()

func set_phrase(phrase: String) -> void:
	# Store the phrase for accessibility and automated checks as well.
	text = ""
	if _text_label == null:
		return
	_text_label.text = phrase
	tooltip_text = phrase
	queue_redraw()

func get_phrase() -> String:
	return _text_label.text if _text_label != null else ""

func _layout_text() -> void:
	if _text_label == null:
		return
	_text_label.position = Vector2(size.x * 0.085, size.y * 0.12)
	_text_label.size = Vector2(size.x * 0.83, size.y * 0.67)
	_text_label.add_theme_font_size_override("font_size", clampi(roundi(size.y * 0.225), 12, 21))
	queue_redraw()

func _outline(body: PackedVector2Array, tint: Color, width: float) -> void:
	var loop: PackedVector2Array = body.duplicate()
	loop.append(body[0])
	draw_polyline(loop, tint, width, true)

func _cloud_points(bounds: Rect2) -> PackedVector2Array:
	var pts := PackedVector2Array()
	var center: Vector2 = bounds.position + bounds.size * 0.5
	for i in range(80):
		var angle: float = TAU * float(i) / 80.0
		# Seven broad, rounded lobes: a cloud rather than an ellipse or badge.
		var wobble: float = 1.0 + 0.058 * cos(7.0 * angle) + 0.026 * sin(5.0 * angle)
		pts.append(center + Vector2(cos(angle) * bounds.size.x * 0.48 * wobble,
			sin(angle) * bounds.size.y * 0.455 * wobble))
	return pts

func _draw() -> void:
	if size.x < 20.0 or size.y < 20.0:
		return
	var base: Color = Color("edddc8") if chosen else Color("cbeaf4")
	var bright: Color = Color("f9efdf") if chosen else Color("ecf9fd")
	if is_hovered() or button_pressed:
		base = bright
	var bounds := Rect2(Vector2(size.x * 0.035, size.y * 0.045),
		Vector2(size.x * 0.93, size.y * 0.82))
	var shadow := _cloud_points(bounds.translated(Vector2(0, size.y * 0.035)))
	draw_colored_polygon(shadow, Color(0.02, 0.08, 0.17, 0.40))
	var halo := _cloud_points(bounds.grow(size.y * 0.04))
	if chosen:
		_outline(halo, Color(0.26, 0.83, 1.0, 0.23), 6.0)
	# Tiny liquid drop tail points at the character below the floating choices.
	var tail := PackedVector2Array([
		Vector2(size.x * 0.62, size.y * 0.73),
		Vector2(size.x * 0.73, size.y * 0.73),
		Vector2(size.x * 0.67, size.y * 0.975)
	])
	draw_colored_polygon(tail, Color("063153"))
	var inner_tail := PackedVector2Array([
		Vector2(size.x * 0.635, size.y * 0.74),
		Vector2(size.x * 0.711, size.y * 0.74),
		Vector2(size.x * 0.67, size.y * 0.94)
	])
	draw_colored_polygon(inner_tail, base)
	var shell := _cloud_points(bounds)
	draw_colored_polygon(shell, Color("063153"))
	_outline(shell, Color("5bd2ff"), 2.5 if chosen else 1.8)
	var center_cloud := _cloud_points(bounds.grow(-size.y * 0.040))
	draw_colored_polygon(center_cloud, base)
	_outline(center_cloud, Color(1, 1, 1, 0.48), 1.3)
	draw_arc(Vector2(size.x * 0.43, size.y * 0.225), size.y * 0.12, 3.7, 5.65,
		18, Color(1, 1, 1, 0.30), 1.5, true)
