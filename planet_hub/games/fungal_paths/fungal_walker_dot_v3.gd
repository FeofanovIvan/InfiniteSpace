extends Node2D
## Simple temporary glowing probe instead of a pet/animal.
func _draw() -> void:
    draw_circle(Vector2(2,3),18,Color(0.0,0.0,0.0,0.25))
    draw_circle(Vector2.ZERO,21,Color(0.37,0.91,1.0,0.13))
    draw_circle(Vector2.ZERO,14,Color(0.29,0.94,1.0,0.27))
    draw_circle(Vector2.ZERO,8,Color("#1faeea"))
    draw_circle(Vector2.ZERO,4.7,Color("#edffff"))
