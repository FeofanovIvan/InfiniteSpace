extends Node2D
@export var width: float = 66.0
@export var height: float = 15.0
func _draw() -> void:
    var pts := PackedVector2Array()
    for i in range(33):
        var a := TAU * float(i) / 32.0
        pts.append(Vector2(cos(a) * width, sin(a) * height))
    draw_colored_polygon(pts, Color(0.09, 0.10, 0.32, 0.27))
    draw_arc(Vector2.ZERO, width, 0.15, PI-0.15, 40, Color(0.67, 0.9, 1, 0.32), 1.1, true)
