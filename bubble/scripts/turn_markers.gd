extends Node2D
## Floor shadow, compass rings, heading vector, start and destination markers.
var actor: Vector2 = Vector2(1110.0, 480.0)
var center: Vector2 = Vector2(1110.0, 480.0)
var heading: float = 0.0
var left_to_right: float = 1.0
var is_walking: bool = false
var visual_scale: float = 0.76

func refresh(current: Vector2, origin: Vector2, angle: float, walking: bool, direction: float, s: float) -> void:
    actor = current
    center = origin
    heading = angle
    is_walking = walking
    left_to_right = direction
    visual_scale = s
    queue_redraw()

func _draw() -> void:
    var floor_y: float = center.y + 196.0 * visual_scale
    # Pivot marker and compass arcs; each turn should have a grounded visual frame.
    for i in range(4):
        draw_arc(Vector2(center.x, floor_y + 8.0), 48.0 + i * 24.0, 0.05, PI - 0.05, 35, Color(0.23, 0.58, 0.76, 0.13 + 0.06 * float(i)), 2.0)
    draw_circle(Vector2(center.x, floor_y + 6.0), 6.0, Color(0.46, 0.82, 1.0, 0.65))
    # Stable projected shadow follows the actor, not its body bounce.
    for i in range(8):
        var k: float = 1.0 - float(i) / 8.0
        var poly := PackedVector2Array()
        for j in range(42):
            var a: float = TAU * float(j) / 42.0
            poly.append(Vector2(actor.x + cos(a) * 139.0 * visual_scale * k, floor_y + sin(a) * 24.0 * visual_scale * k))
        draw_colored_polygon(poly, Color(0.32, 0.83, 0.96, 0.027))
    # Direction indicator at floor height provides an unambiguous 180° turn reference.
    var vec: Vector2 = Vector2(sin(heading), -cos(heading) * 0.45).normalized()
    var orig: Vector2 = Vector2(actor.x, floor_y - 3.0)
    var tip: Vector2 = orig + vec * 77.0 * visual_scale
    draw_line(orig, tip, Color(0.96, 0.72, 0.39, 0.75), 3.0)
    draw_colored_polygon(PackedVector2Array([tip, tip - vec * 12.0 + Vector2(-vec.y, vec.x) * 6.0, tip - vec * 12.0 - Vector2(-vec.y, vec.x) * 6.0]), Color(0.96, 0.72, 0.39, 0.75))
    if is_walking:
        var end: Vector2 = Vector2(center.x + 280.0 * left_to_right * visual_scale, floor_y + 20.0)
        draw_dashed_line(Vector2(center.x, floor_y + 20.0), end, Color(0.40, 0.81, 0.9, 0.52), 2.0, 14.0)
        draw_circle(end, 8.0, Color(0.83, 0.59, 0.97, 0.75))
