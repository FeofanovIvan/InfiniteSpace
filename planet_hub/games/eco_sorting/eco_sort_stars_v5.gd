extends Control
## Decorative fallback starfield, drawn only; reused cosmic background textures take precedence.
var _seed: int = 41319

func _ready() -> void:
    mouse_filter = Control.MOUSE_FILTER_IGNORE
    resized.connect(queue_redraw)
    queue_redraw()

func _draw() -> void:
    var area: Vector2 = size
    if area.x < 1.0 or area.y < 1.0:
        return
    draw_rect(Rect2(Vector2.ZERO, area), Color("#060e27"))
    var generator: RandomNumberGenerator = RandomNumberGenerator.new()
    generator.seed = _seed
    var count: int = mini(380, maxi(50, roundi(area.x * area.y / 4200.0)))
    for n in range(count):
        var point: Vector2 = Vector2(generator.randf_range(0.0, area.x), generator.randf_range(0.0, area.y))
        var twinkle: float = generator.randf_range(0.18, 0.65)
        var radius: float = generator.randf_range(0.5, 1.45)
        draw_circle(point, radius, Color(0.75, 0.89, 1.0, twinkle), true, -1.0, true)
    for n in range(7):
        var x: float = (float(n) + 0.5) / 7.0 * area.x
        var y: float = (0.28 + 0.24 * sin(float(n) * 1.63)) * area.y
        draw_circle(Vector2(x, y), minf(area.x, area.y) * 0.13, Color(0.13, 0.18, 0.37, 0.026))
