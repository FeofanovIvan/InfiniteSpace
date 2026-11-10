extends "res://scripts/Joystick.gd"
## Original MIKA flight joystick, horizontally constrained for orbital steering.
## Keep the original touch, mouse, joystick scale and ring artwork.

func _set_direction(next_direction: Vector2) -> void:
    super._set_direction(Vector2(clampf(next_direction.x, -1.0, 1.0), 0.0))

func _draw() -> void:
    super._draw()
    var center: Vector2 = size * 0.5
    for sign_dir in [-1.0, 1.0]:
        var anchor: Vector2 = center + Vector2(86.0 * sign_dir, 0.0)
        var direction: float = sign_dir
        var points: PackedVector2Array = PackedVector2Array([
            anchor + Vector2(8.0 * direction, -11.0),
            anchor + Vector2(-7.0 * direction, 0.0),
            anchor + Vector2(8.0 * direction, 11.0)
        ])
        draw_polyline(points, Color(0.10, 0.67, 0.94, 0.34), 7.0, true)
        draw_polyline(points, Color("ecffff"), 3.2, true)
