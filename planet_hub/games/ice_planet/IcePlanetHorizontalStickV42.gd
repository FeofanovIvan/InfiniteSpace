extends "res://scripts/Joystick.gd"
## Ice Planet v4.2 — same original flight-circle / thumb input mechanics.
## Both joysticks are x-only, identical, with a soft cyan interior track.

func _set_direction(next_direction: Vector2) -> void:
    super._set_direction(Vector2(clampf(next_direction.x, -1.0, 1.0), 0.0))

func _draw() -> void:
    var center: Vector2 = size * 0.5
    draw_circle(center, 83.0, Color(0.02, 0.10, 0.18, 0.36))
    draw_circle(center, 67.0, Color(0.04, 0.17, 0.28, 0.43))
    draw_arc(center, 67.0, 0.0, TAU, 64, Color(0.38, 0.80, 1.0, 0.42), 2.0, true)
    draw_arc(center, 49.0, 0.0, TAU, 64, Color(0.18, 0.51, 0.70, 0.22), 1.0, true)
    # Short rounded guide, soft blue instead of black. Opaque enough to read
    # over the moving starfield, transparent enough for the same flight style.
    draw_line(center + Vector2(-53.0, 0.0), center + Vector2(53.0, 0.0), Color(0.28, 0.71, 0.90, 0.34), 20.0, true)
    draw_line(center + Vector2(-50.0, -1.0), center + Vector2(50.0, -1.0), Color(0.60, 0.90, 1.00, 0.58), 9.0, true)
    for x in [-53.0, 53.0]:
        draw_circle(center + Vector2(x, 0.0), 9.0, Color(0.38, 0.78, 0.96, 0.60))
        draw_circle(center + Vector2(x, -1.0), 3.5, Color(0.73, 0.95, 1.0, 0.80))
    var knob: Vector2 = center + Vector2(direction.x * STICK_RADIUS, 0.0)
    draw_circle(knob, KNOB_RADIUS + 5.0, Color(0.09, 0.49, 0.68, 0.22))
    draw_circle(knob, KNOB_RADIUS, Color(0.09, 0.34, 0.53, 0.95))
    draw_arc(knob, KNOB_RADIUS, 0.0, TAU, 48, Color(0.60, 0.91, 1.0, 0.80), 2.0, true)
    draw_circle(knob + Vector2(-5.0, -6.0), 7.0, Color(0.47, 0.80, 0.93, 0.32))
