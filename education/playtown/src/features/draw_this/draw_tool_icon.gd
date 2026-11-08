class_name DrawToolIcon
extends Control

enum Tool { ERASER, CLEAR }

@export var tool := Tool.ERASER:
	set(value):
		tool = value
		queue_redraw()


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func _draw() -> void:
	var side := minf(size.x, size.y)
	if tool == Tool.ERASER:
		_draw_eraser(side)
	else:
		_draw_clear(side)


func _draw_eraser(side: float) -> void:
	var center := size * 0.5
	var body := PackedVector2Array([
		center + Vector2(-0.28, 0.10) * side,
		center + Vector2(0.02, -0.27) * side,
		center + Vector2(0.29, -0.05) * side,
		center + Vector2(-0.02, 0.31) * side,
	])
	draw_colored_polygon(body, Color("#f06e86"))
	draw_polyline(body + PackedVector2Array([body[0]]), Color("#9d4660"), maxf(2.0, side * 0.045), true)
	draw_line(center + Vector2(-0.12, -0.09) * side, center + Vector2(0.15, 0.13) * side, Color("#fff5d8"), maxf(3.0, side * 0.10), true)


func _draw_clear(side: float) -> void:
	var center := size * 0.5
	var paper := Rect2(center - Vector2.ONE * side * 0.25, Vector2.ONE * side * 0.50)
	draw_style_box(_paper_style(side), paper)
	var width := maxf(3.0, side * 0.055)
	draw_line(center + Vector2(-0.13, -0.13) * side, center + Vector2(0.13, 0.13) * side, Color("#e04a42"), width, true)
	draw_line(center + Vector2(0.13, -0.13) * side, center + Vector2(-0.13, 0.13) * side, Color("#e04a42"), width, true)


func _paper_style(side: float) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color("#ffffff")
	style.border_color = Color("#d29b45")
	style.set_border_width_all(maxi(2, roundi(side * 0.035)))
	style.set_corner_radius_all(maxi(3, roundi(side * 0.06)))
	return style
