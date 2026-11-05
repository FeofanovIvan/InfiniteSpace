extends Node2D
## An intentionally stylized, fully procedural gas puff (no new PNG assets).
## Coordinates are local to the BubblePlastic root.

var active: bool = false
var action_progress: float = 0.0
var strength: float = 1.0

func update_phase(gas_active: bool, phase: float, power: float) -> void:
    active = gas_active
    action_progress = phase
    strength = power
    queue_redraw()

func _draw() -> void:
    if not active:
        return
    # Two overlapping pulses; each particle is drawn with translucent soft rings.
    for i in range(22):
        var release_t: float = 0.37 + float(i % 11) * 0.034 + float(i / 11) * 0.09
        var age: float = (action_progress - release_t) / 0.48
        if age <= 0.0 or age >= 1.0:
            continue
        var phase: float = float(i)
        var side: float = sin(phase * 2.33)
        var px: float = 175.0 + age * (155.0 + 42.0 * sin(phase * 1.7)) * strength
        var py: float = 63.0 + side * 42.0 - age * (45.0 + 23.0 * cos(phase))
        var radius: float = (8.0 + 13.0 * (0.5 + 0.5 * cos(phase * 1.3))) * (0.75 + age * 0.85)
        var alpha: float = minf(age * 8.0, 1.0) * pow(1.0 - age, 1.35) * 0.28
        var center: Vector2 = Vector2(px, py)
        draw_circle(center, radius * 1.55, Color(0.31, 0.96, 0.80, alpha * 0.15))
        draw_circle(center, radius * 1.18, Color(0.38, 0.96, 0.82, alpha * 0.29))
        draw_circle(center, radius * 0.78, Color(0.66, 1.0, 0.94, alpha * 0.38))
        draw_arc(center, radius * 0.88, -2.3, -1.3, 14, Color(0.95, 1.0, 0.98, alpha * 0.9), 1.3, true)
