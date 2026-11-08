extends Node2D
## Static star field and a simple walking track. Does not move the character.
func _draw() -> void:
    var sz: Vector2 = get_viewport_rect().size
    for i in range(44):
        var t: float = float(i) / 43.0
        draw_rect(Rect2(0.0, sz.y * t, sz.x, sz.y / 43.0 + 2.0), Color("07182d").lerp(Color("24375a"), t))
    var rng := RandomNumberGenerator.new()
    rng.seed = 2026110401
    for j in range(160):
        var x: float = rng.randf_range(5.0, sz.x - 5.0)
        var y: float = rng.randf_range(5.0, sz.y * 0.76)
        draw_circle(Vector2(x, y), rng.randf_range(0.6, 1.75), Color(0.68, 0.84, 1.0, rng.randf_range(0.12, 0.61)))
    draw_rect(Rect2(0.0, sz.y * 0.72, sz.x, sz.y * 0.28), Color(0.055, 0.11, 0.20, 0.90))
    draw_line(Vector2(0.0, sz.y * 0.72), Vector2(sz.x, sz.y * 0.72), Color(0.36, 0.67, 0.85, 0.42), 2.0)
    draw_line(Vector2(0.0, sz.y * 0.88), Vector2(sz.x, sz.y * 0.88), Color(0.18, 0.35, 0.50, 0.35), 2.0)
