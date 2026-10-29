extends RefCounted
## Reusable, stateless approach and scale easing for future player landings.
## The planet world position must be supplied again on EVERY frame.

static func smooth_step(value: float) -> float:
	var t: float = clampf(value, 0.0, 1.0)
	return t * t * (3.0 - 2.0 * t)


static func anchored_approach(body_world: Vector2, start_offset: Vector2, destination_offset: Vector2, progress: float) -> Vector2:
	return body_world + start_offset.lerp(destination_offset, smooth_step(progress))
