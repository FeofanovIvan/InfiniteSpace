extends "res://education/playtown/src/features/tilt_maze/mika_magnetic_maze_board_v2.gd"
## Roll the Ball 2.1 — THE EXACT v2 magnetic rails, without its opaque disc/floor.
## All geometry, ring gaps, collisions, scoring and generated maze data are inherited.
## The actual rotating Sun, supplied by the main scene, is visible through the centre.

func _paint_planetarium() -> void:
    # IMPORTANT: remove v2's solid indigo concentric floor. Never draw a new
    # opaque disc: the project starfield and Sun must remain visible underneath.
    pass


func _paint_core() -> void:
    # The physical win target remains the exact 500x500 centre of the old maze.
    # Decorate it as a transparent solar approach ring, not an opaque target.
    var pulse: float = 0.5 + 0.5 * sin(_cosmic_time * 2.3)
    draw_arc(CENTER, 90.0, 0.0, TAU, 100,
        Color(0.28, 0.85, 1.0, 0.22 + 0.10 * pulse), 12.0, true)
    draw_arc(CENTER, 78.0, 0.0, TAU, 100,
        Color(0.69, 0.96, 1.0, 0.72), 4.0, true)
    for j in range(4):
        var angle: float = _cosmic_time * 0.42 + float(j) * TAU / 4.0
        var mark: Vector2 = CENTER + Vector2(cos(angle), sin(angle)) * 84.0
        draw_circle(mark, 3.2 + pulse, Color("#a9eaff") if j % 2 == 0 else Color("#ffcaee"))
