extends Node2D
## Player craft from the supplied transparent top-down artwork.
## Locally faces -Y; engine glow is generated at runtime, never baked into PNG.

const PLAYER_TEXTURE: Texture2D = preload("res://assets/ships/miko_player_ship.png")
var throttle: float = 0.0
var _clock: float = 0.0


func _process(delta: float) -> void:
	_clock += delta
	queue_redraw()


func _draw() -> void:
	# Exhaust is drawn BEFORE the body, anchored to its two rear nozzles.
	if throttle > 0.03:
		var pulse: float = 0.87 + 0.13 * sin(_clock * 24.0)
		var length_px: float = (12.0 + 21.0 * throttle) * pulse
		for nozzle_x in [-16.5, 16.5]:
			var base: Vector2 = Vector2(nozzle_x, 28.5)
			draw_circle(base, 7.0, Color(0.08, 0.65, 1.0, 0.24 * throttle))
			draw_colored_polygon(PackedVector2Array([
				base + Vector2(-5.0, 0.0),
				base + Vector2(0.0, length_px),
				base + Vector2(5.0, 0.0)
			]), Color(0.08, 0.56, 1.0, 0.42 * throttle))
			draw_colored_polygon(PackedVector2Array([
				base + Vector2(-2.2, 1.0),
				base + Vector2(0.0, length_px * 0.72),
				base + Vector2(2.2, 1.0)
			]), Color(0.68, 0.97, 1.0, 0.82 * throttle))
	draw_circle(Vector2.ZERO, 42.0, Color(0.13, 0.49, 0.89, 0.018))
	draw_texture_rect(PLAYER_TEXTURE, Rect2(Vector2(-47.0, -47.0), Vector2(94.0, 94.0)), false)
