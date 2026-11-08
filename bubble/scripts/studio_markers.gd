extends Node2D
## Ground shadows plus a simple demo mat for sleeping, no original game backgrounds.
var actor_pos: Vector2 = Vector2(1040.0, 470.0)
var size_factor: float = 0.82
var current_action: String = "detach"

func refresh(at: Vector2, scale_factor: float, state: String) -> void:
    actor_pos = at
    size_factor = scale_factor
    current_action = state
    queue_redraw()

func _draw() -> void:
    var floor_y: float = get_viewport_rect().size.y * 0.765
    var center: Vector2 = Vector2(actor_pos.x, floor_y + 7.0)
    if current_action == "sleep":
        draw_circle(center + Vector2(0, -10.0), 140.0 * size_factor, Color(0.26, 0.4, 0.76, 0.17))
    for i in range(7):
        var factor: float = (7.0 - float(i)) / 7.0
        var poly := PackedVector2Array()
        for j in range(42):
            var a: float = TAU * float(j) / 42.0
            poly.append(center + Vector2(cos(a) * 144.0 * size_factor * factor, sin(a) * 19.0 * size_factor * factor))
        draw_colored_polygon(poly, Color(0.23, 0.77, 0.96, 0.021))
