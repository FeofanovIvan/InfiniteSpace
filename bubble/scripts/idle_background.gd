extends Node2D
## Fixed cosmic backdrop, no travel lane: this laboratory demonstrates only idle.

func _draw() -> void:
    var s: Vector2 = get_viewport_rect().size
    for i in range(36):
        var q: float = float(i) / 35.0
        var c: Color = Color("07182d").lerp(Color("142e4a"), q)
        draw_rect(Rect2(0.0, q * s.y, s.x, s.y / 35.0 + 2.0), c)

    var rng := RandomNumberGenerator.new()
    rng.seed = 20261104
    for i in range(104):
        var p := Vector2(rng.randf_range(6.0, s.x - 6.0), rng.randf_range(8.0, s.y - 8.0))
        var r: float = rng.randf_range(0.4, 1.6)
        draw_circle(p, r, Color(0.75, 0.92, 1.0, rng.randf_range(0.15, 0.55)))

    var center: Vector2 = Vector2(s.x * (0.66 if s.x >= 950.0 else 0.52), s.y * 0.53)
    var scale_factor: float = clampf(minf(s.x / 1450.0, s.y / 950.0), 0.43, 0.88)
    var seat: Vector2 = center + Vector2(0.0, 195.0 * scale_factor)
    # Still shadow/landing halo to make vertical breathing perceptible.
    for i in range(9):
        var f: float = 1.0 - float(i) / 9.0
        draw_ellipse(seat, 205.0 * scale_factor * f, 32.0 * scale_factor * f, Color(0.24, 0.71, 0.94, 0.025))
    draw_arc(seat, 180.0 * scale_factor, 0.13, PI - 0.13, 52, Color(0.45, 0.80, 0.98, 0.21), 1.5, true)

func draw_ellipse(center: Vector2, rx: float, ry: float, color: Color) -> void:
    var points := PackedVector2Array()
    for i in range(48):
        var a: float = TAU * float(i) / 48.0
        points.append(center + Vector2(cos(a) * rx, sin(a) * ry))
    draw_colored_polygon(points, color)
