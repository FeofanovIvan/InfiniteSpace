extends Node2D
## Contact shadow tracks horizontal movement but stays on floor when jumping/floating.
var character_pos: Vector2 = Vector2(1030, 510)
var actor_scale: float = 0.78
var lift: float = 0.0
var current_action: String = "wave"

func refresh(at: Vector2, height: float, scale_factor: float, id: String) -> void:
    character_pos = at
    lift = height
    actor_scale = scale_factor
    current_action = id
    queue_redraw()

func _draw() -> void:
    var ground_y: float = get_viewport_rect().size.y * 0.766
    var foot: Vector2 = Vector2(character_pos.x, ground_y + 5.0)
    var spread: float = 1.0 + (lift / 300.0)
    for i in range(8):
        var f: float = 1.0 - float(i) / 8.0
        var points := PackedVector2Array()
        for k in range(44):
            var a: float = TAU * float(k) / 44.0
            points.append(foot + Vector2(cos(a) * 148.0 * actor_scale * f * spread, sin(a) * 21.0 * actor_scale * f * spread))
        draw_colored_polygon(points, Color(0.28, 0.74, 0.95, 0.022 * (1.0 - lift / 480.0)))
    if current_action == "float" or current_action == "jump":
        draw_line(foot + Vector2(-120.0 * actor_scale, 31.0), foot + Vector2(120.0 * actor_scale, 31.0), Color(0.49, 0.86, 0.98, 0.12), 2.0)
