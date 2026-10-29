extends Node2D
## Tiny anchored schematic orbital station, following Earth on a local orbit.
## Can be replaced with a proper station art asset later.

func _draw() -> void:
    draw_circle(Vector2.ZERO, 24.0, Color(0.17, 0.65, 0.96, 0.06))
    draw_line(Vector2(-24, 0), Vector2(24, 0), Color(0.75, 0.89, 0.99), 3.5, true)
    draw_rect(Rect2(-38, -12, 18, 24), Color(0.11, 0.37, 0.69), true)
    draw_rect(Rect2(20, -12, 18, 24), Color(0.11, 0.37, 0.69), true)
    for x in [-34.0, -27.0, 24.0, 31.0]:
        draw_line(Vector2(x, -10), Vector2(x, 10), Color(0.48, 0.84, 1.0, 0.75), 1.0)
    draw_rect(Rect2(-12, -9, 24, 18), Color(0.74, 0.77, 0.82), true)
    draw_circle(Vector2.ZERO, 7.0, Color(0.98, 0.76, 0.27))
    draw_circle(Vector2(-3.0, -3.0), 2.0, Color(1.0, 1.0, 0.85, 0.92))
