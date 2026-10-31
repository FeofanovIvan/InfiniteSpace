extends Button

const WHITE := Color(1.0, 1.0, 1.0, 0.97)
var door_mode: bool = false
var stairs_up: bool = true

func _ready() -> void:
	flat = true
	focus_mode = Control.FOCUS_NONE
	add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	button_down.connect(queue_redraw)
	button_up.connect(queue_redraw)
	mouse_entered.connect(queue_redraw)
	mouse_exited.connect(queue_redraw)

func set_stairs_up(value: bool) -> void:
	if stairs_up == value:
		return
	stairs_up = value
	if door_mode:
		queue_redraw()

func set_door_mode(value: bool) -> void:
	if door_mode == value:
		return
	door_mode = value
	queue_redraw()

func _draw() -> void:
	var radius: float = minf(size.x, size.y) * 0.45
	var center: Vector2 = size * 0.5
	var fill := Color("#59bce6")
	if is_hovered():
		fill = Color("#83d8f7")
	if is_pressed():
		fill = Color("#238dbf")
	draw_circle(center + Vector2(0.0, 3.0), radius, Color(0.07, 0.23, 0.43, 0.25))
	draw_circle(center, radius, fill)
	draw_arc(center, radius - 2.0, 0.0, TAU, 64, Color("#dff7ff"), 2.0, true)
	if door_mode:
		_draw_stairs(center, radius)
	else:
		_draw_hand(center, radius)

func _draw_hand(center: Vector2, radius: float) -> void:

	# Simple outlined hand/finger symbol: a child can read it as “touch/use”.
	var hand := PackedVector2Array([
		center + Vector2(-22, 12), center + Vector2(-29, 2),
		center + Vector2(-27, -4), center + Vector2(-21, -5),
		center + Vector2(-11, 3), center + Vector2(-11, -31),
		center + Vector2(-7, -38), center + Vector2(-1, -38),
		center + Vector2(4, -32), center + Vector2(4, -10),
		center + Vector2(9, -23), center + Vector2(15, -23),
		center + Vector2(19, -18), center + Vector2(19, -7),
		center + Vector2(23, -15), center + Vector2(29, -13),
		center + Vector2(31, -7), center + Vector2(29, 12),
		center + Vector2(18, 29), center + Vector2(-7, 29),
		center + Vector2(-22, 12)
	])
	draw_polyline(hand, WHITE, 4.0, true)

	var label_position := Vector2(center.x - 22.0, center.y + radius - 12.0)
	draw_string(ThemeDB.fallback_font, label_position, "USE", HORIZONTAL_ALIGNMENT_CENTER, 44.0, 18, WHITE)


func _draw_stairs(center: Vector2, r: float) -> void:
	# White stair silhouette on the left; separate arrow on the right.
	var left: float = center.x - r * 0.68
	var base_y: float = center.y + r * 0.46
	var step: float = r * 0.33
	var stairs: PackedVector2Array = PackedVector2Array([
		Vector2(left, base_y),
		Vector2(left + step, base_y),
		Vector2(left + step, base_y - step),
		Vector2(left + step * 2.0, base_y - step),
		Vector2(left + step * 2.0, base_y - step * 2.0),
		Vector2(left + step * 2.8, base_y - step * 2.0),
	])
	draw_polyline(stairs, WHITE, 4.5, true)
	# Same straight-arrow language as the D-pad, but up on floor 1 and down on floor 2.
	var axis_x: float = center.x + r * 0.52
	var wings_dx: float = r * 0.18
	if stairs_up:
		var tail_up: Vector2 = Vector2(axis_x, center.y + r * 0.24)
		var tip_up: Vector2 = Vector2(axis_x, center.y - r * 0.50)
		var wings_y_up: float = tip_up.y + r * 0.22
		draw_line(tail_up, tip_up, WHITE, 4.5, true)
		draw_line(tip_up, Vector2(axis_x - wings_dx, wings_y_up), WHITE, 4.5, true)
		draw_line(tip_up, Vector2(axis_x + wings_dx, wings_y_up), WHITE, 4.5, true)
	else:
		var tail_down: Vector2 = Vector2(axis_x, center.y - r * 0.24)
		var tip_down: Vector2 = Vector2(axis_x, center.y + r * 0.50)
		var wings_y_down: float = tip_down.y - r * 0.22
		draw_line(tail_down, tip_down, WHITE, 4.5, true)
		draw_line(tip_down, Vector2(axis_x - wings_dx, wings_y_down), WHITE, 4.5, true)
		draw_line(tip_down, Vector2(axis_x + wings_dx, wings_y_down), WHITE, 4.5, true)
