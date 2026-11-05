extends Node2D
## Static original background for this test, not an Infinity Space game asset.
func _draw() -> void:
    var sz: Vector2 = get_viewport_rect().size
    for i in range(48):
        var k: float = float(i) / 47.0
        draw_rect(Rect2(0.0, sz.y * k, sz.x, sz.y / 47.0 + 2.0), Color("071529").lerp(Color("17294d"), k))
    var rng := RandomNumberGenerator.new()
    rng.seed = 47120261104
    for i in range(150):
        var x: float = rng.randf_range(1.0, sz.x - 1.0)
        var y: float = rng.randf_range(1.0, sz.y * 0.77)
        draw_circle(Vector2(x, y), rng.randf_range(0.7, 1.7), Color(0.7, 0.83, 1.0, rng.randf_range(0.12, 0.65)))
    draw_rect(Rect2(0.0, sz.y * 0.735, sz.x, sz.y * 0.265), Color(0.06, 0.12, 0.22, 0.8))
    draw_line(Vector2(0.0, sz.y * 0.735), Vector2(sz.x, sz.y * 0.735), Color(0.40, 0.78, 0.96, 0.43), 2.0)
