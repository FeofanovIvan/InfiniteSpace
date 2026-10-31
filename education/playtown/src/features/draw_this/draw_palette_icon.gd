class_name DrawPaletteIcon
extends Control

var selected_color := Color("#168fd0")


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func set_selected_color(color: Color) -> void:
	selected_color = color
	queue_redraw()


func _draw() -> void:
	var unit := minf(size.x, size.y)
	var center := size * Vector2(0.49, 0.52)
	draw_set_transform(center + Vector2(0.0, unit * 0.035), 0.0, Vector2(1.10, 0.83))
	draw_circle(Vector2.ZERO, unit * 0.34, Color(0.31, 0.18, 0.06, 0.20))
	draw_set_transform(center, 0.0, Vector2(1.10, 0.83))
	draw_circle(Vector2.ZERO, unit * 0.34, Color("#f0bd62"))
	draw_arc(Vector2.ZERO, unit * 0.34, 0.0, TAU, 48, Color("#9b5a1b"), maxf(2.0, unit * 0.035), true)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

	var blob_radius := unit * 0.064
	var blobs: Array[Dictionary] = [
		{"p": Vector2(0.32, 0.34), "c": Color("#ed3b45")},
		{"p": Vector2(0.48, 0.27), "c": Color("#f1c62a")},
		{"p": Vector2(0.64, 0.34), "c": Color("#4aaa45")},
		{"p": Vector2(0.67, 0.54), "c": Color("#168fd0")},
		{"p": Vector2(0.53, 0.66), "c": Color("#9754c8")},
	]
	for blob in blobs:
		var point: Vector2 = size * (blob["p"] as Vector2)
		var color: Color = blob["c"] as Color
		draw_circle(point + Vector2(0.0, unit * 0.012), blob_radius, Color(0.2, 0.1, 0.0, 0.16))
		draw_circle(point, blob_radius, color)
		draw_circle(point - Vector2.ONE * blob_radius * 0.28, blob_radius * 0.22, Color(1, 1, 1, 0.65))

	var hole_center := size * Vector2(0.31, 0.62)
	draw_circle(hole_center, unit * 0.078, Color("#fff6d8"))
	draw_arc(hole_center, unit * 0.078, 0.0, TAU, 32, Color("#9b5a1b"), maxf(2.0, unit * 0.025), true)
	draw_circle(size * Vector2(0.76, 0.68), unit * 0.078, selected_color)
	draw_arc(size * Vector2(0.76, 0.68), unit * 0.088, 0.0, TAU, 32, Color.WHITE, maxf(2.0, unit * 0.025), true)
