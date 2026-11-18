extends Node2D
## Registered interactable hotspots. Does NOT capture input.
var zones: Array[Dictionary] = []
var nearby_id: String = ""
var debug_visible: bool = false
var time_passed: float = 0.0

func _process(delta: float) -> void:
    time_passed += delta
    if nearby_id != "" or debug_visible:
        queue_redraw()

func _draw() -> void:
    for item in zones:
        var id: String = str(item["id"])
        if id != nearby_id and not debug_visible:
            continue
        var center: Vector2 = item["point"]
        var radius: float = float(item["radius"])
        var selected: bool = id == nearby_id
        var color := Color(0.5, 0.95, 1.0, 0.91) if selected else Color(0.95, 0.72, 0.42, 0.48)
        if debug_visible:
            draw_arc(center, radius, 0, TAU, 64, color * Color(1, 1, 1, 0.75), 2.0, true)
            draw_line(center + Vector2(-10, 0), center + Vector2(10, 0), color, 1.0, true)
            draw_line(center + Vector2(0, -10), center + Vector2(0, 10), color, 1.0, true)
        if selected:
            var pulse: float = 1.0 + 0.05 * sin(time_passed * 3.0)
            draw_arc(center, 20.0 * pulse, 0, TAU, 36, color, 3.0, true)
            draw_circle(center, 5.0, Color(1,1,1,0.85))
