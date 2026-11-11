extends "res://learning/src/features/matching_pairs/matching_door.gd"
## Matching Pairs v2: temporary door skin from user-provided image.
## Touch, symbol matching, sounds and the existing flip animation are inherited.

const NEW_NEON_DOOR: Texture2D = preload("res://learning/assets/matching_pairs/mika_neon_double_door_v2.png")


func _draw() -> void:
    if NEW_NEON_DOOR == null or size.x <= 0.0 or size.y <= 0.0:
        return
    draw_texture_rect(NEW_NEON_DOOR, Rect2(Vector2.ZERO, size), false)
    if revealed:
        # Visual placeholder only: final sliding animation can be designed later.
        # A dark translucent field makes the existing match symbol legible.
        var marker: Vector2 = Vector2(size.x * 0.57, size.y * 0.53)
        draw_circle(marker, minf(size.x, size.y) * 0.225, Color(0.015, 0.08, 0.16, 0.92))
        draw_arc(marker, minf(size.x, size.y) * 0.23, 0.0, TAU, 48, Color("#5deaff"), maxf(1.0, minf(size.x, size.y) * 0.012), true)
        _draw_symbol()
