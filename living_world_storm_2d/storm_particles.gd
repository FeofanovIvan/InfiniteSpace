extends Node2D
## Deterministic lightweight liquid motes, drawn in one 2D canvas node.
## No texture lookups or GPU particle allocation; suitable for Compatibility.

const MAX_MOTES: int = 46
var elapsed: float = 0.0
var planet_radius: float = 175.0
var activity: float = 0.78
var low_quality: bool = false
var cyan: Color = Color("#63dedc")
var violet: Color = Color("#a27deb")

func set_parameters(time_s: float, radius_px: float, strength: float, is_low: bool, cyan_color: Color, violet_color: Color) -> void:
    elapsed = time_s
    planet_radius = radius_px
    activity = strength
    low_quality = is_low
    cyan = cyan_color
    violet = violet_color
    queue_redraw()

func _draw() -> void:
    if activity < 0.001:
        return
    var count: int = 19 if low_quality else MAX_MOTES
    for i in range(count):
        var f: float = float(i)
        var phase: float = f * 2.399963 + 0.21 * sin(f * 0.71)
        var radius_ratio: float = 1.12 + 0.70 * (0.5 + 0.5 * sin(f * 7.37))
        var theta: float = phase + elapsed * (0.068 + 0.029 * sin(f * 2.8))
        radius_ratio += 0.025 * sin(elapsed * 0.31 + f * 4.7)
        var position: Vector2 = Vector2(cos(theta), sin(theta)) * planet_radius * radius_ratio
        var shimmer: float = 0.52 + 0.48 * sin(elapsed * 0.59 + f * 1.83) ** 2
        var opacity: float = minf(0.70, (0.11 + 0.22 * shimmer) * activity)
        var color_value: Color = cyan.lerp(violet, 0.5 + 0.5 * sin(f * 5.32))
        color_value.a = opacity
        var radius_px: float = (0.8 + 1.3 * (0.5 + 0.5 * sin(f * 2.16))) * maxf(0.55, planet_radius / 170.0)
        if not low_quality and i % 4 == 0:
            var halo: Color = color_value
            halo.a *= 0.18
            draw_circle(position, radius_px * 3.0, halo)
        draw_circle(position, radius_px, color_value)
