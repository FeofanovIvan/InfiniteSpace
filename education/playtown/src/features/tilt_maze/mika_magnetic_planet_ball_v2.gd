extends Node2D
## A tiny living liquid-metal PLANET. Pure CanvasItem drawing; no shader or art assets.
## The parent ball_root provides position/size, and all original movement is intact.

var _clock: float = 0.0
var _draw_delay: float = 0.0


func _process(delta: float) -> void:
    _clock += delta
    _draw_delay += delta
    if _draw_delay > 0.036:
        _draw_delay = 0.0
        queue_redraw()


func _draw() -> void:
    # Bright orbital toy-ring behind the planet: an intentional Saturn silhouette.
    var orbit_back := PackedVector2Array()
    for i in range(47):
        var a: float = lerpf(PI * 1.01, TAU * 0.995, float(i) / 46.0)
        orbit_back.append(Vector2(cos(a) * 1.33, sin(a) * 0.43).rotated(-0.28))
    draw_polyline(orbit_back, Color("#ffbdea"), 0.17, true)
    draw_circle(Vector2(0.0, 0.15), 1.22, Color(0.13, 0.76, 1.0, 0.16))
    draw_circle(Vector2.ZERO, 1.08, Color("#08152c"))
    draw_circle(Vector2.ZERO, 1.01, Color("#a5ebff"))
    draw_circle(Vector2(0.10, 0.09), 0.91, Color("#23285d"))
    draw_circle(Vector2(-0.13, -0.13), 0.79, Color("#3a4691"))
    # Giant liquid magnetic islands move across the visible face as it spins.
    for i in range(3):
        var phase: float = _clock * 1.4 + float(i) * 2.10
        var x: float = 0.46 * sin(phase)
        var y: float = -0.36 + float(i) * 0.35
        var depth: float = 0.28 + 0.33 * (0.5 + 0.5 * cos(phase))
        var paint: Color = Color("#59e9f4") if i % 2 == 0 else Color("#f4a6ff")
        draw_circle(Vector2(x, y), depth, Color(paint.r, paint.g, paint.b, 0.88))
    # Cute luminous eddies, glassy moonstone reflection and a small sparkle.
    draw_circle(Vector2(0.34, 0.43), 0.24, Color(0.92, 0.44, 0.97, 0.58))
    draw_circle(Vector2(-0.38, -0.40), 0.29, Color(0.93, 0.98, 1.0, 0.70))
    draw_circle(Vector2(-0.45, -0.45), 0.13, Color.WHITE)
    var front := PackedVector2Array()
    for i in range(39):
        var a: float = lerpf(0.0, PI, float(i) / 38.0)
        front.append(Vector2(cos(a) * 1.33, sin(a) * 0.43).rotated(-0.28))
    draw_polyline(front, Color("#f2ddff"), 0.15, true)
    draw_arc(Vector2.ZERO, 1.01, 0.07, PI * 0.94, 36, Color(0.52, 0.98, 1.0, 0.63), 0.07, true)
