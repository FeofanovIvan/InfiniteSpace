extends Node2D
## Decorative test stage. No original Infinity Space assets used.
func _draw() -> void:
    var size_screen: Vector2 = get_viewport_rect().size
    for i in range(44):
        var f: float = float(i) / 43.0
        draw_rect(Rect2(0.0, size_screen.y * f, size_screen.x, size_screen.y / 43.0 + 1.5), Color("07152d").lerp(Color("1d315a"), f))
    var rand := RandomNumberGenerator.new()
    rand.seed = 47120261104
    for i in range(140):
        var xx: float = rand.randf_range(0.0, size_screen.x)
        var yy: float = rand.randf_range(0.0, size_screen.y * 0.75)
        draw_circle(Vector2(xx, yy), rand.randf_range(0.6, 1.8), Color(0.78, 0.87, 1.0, rand.randf_range(0.12, 0.62)))
    var ground_y: float = size_screen.y * 0.765
    draw_rect(Rect2(0.0, ground_y, size_screen.x, size_screen.y - ground_y), Color(0.045, 0.1, 0.21, 0.94))
    draw_line(Vector2(0.0, ground_y), Vector2(size_screen.x, ground_y), Color("4276a0"), 2.0)
    for k in range(9):
        var x: float = float(k) / 8.0 * size_screen.x
        draw_line(Vector2(x, ground_y), Vector2(x - 52.0, size_screen.y), Color(0.3, 0.6, 0.7, 0.13), 1.0)
