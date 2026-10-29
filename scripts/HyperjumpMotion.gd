extends RefCounted
## Shared NPC/player hyperspace parameters and movement math.
## Jumping happens only at a world-space rim around the system star.

const OUTER_JUMP_RADIUS: float = 2500.0
const CHARGE_TIME: float = 0.43
const DASH_TIME: float = 0.36
const DASH_INITIAL_SPEED: float = 880.0
const DASH_ACCELERATION: float = 5400.0
const ARRIVAL_OUTSIDE_DISTANCE: float = 650.0

static func exit_world(direction: Vector2) -> Vector2:
	var heading: Vector2 = direction.normalized()
	if heading.length_squared() < 0.001:
		heading = Vector2.RIGHT
	return heading * OUTER_JUMP_RADIUS

static func arrival_world(direction: Vector2) -> Vector2:
	var heading: Vector2 = direction.normalized()
	if heading.length_squared() < 0.001:
		heading = Vector2.RIGHT
	return -heading * (OUTER_JUMP_RADIUS + ARRIVAL_OUTSIDE_DISTANCE)

static func dash_speed(progress: float) -> float:
	var t: float = clampf(progress, 0.0, 1.0)
	return DASH_INITIAL_SPEED + DASH_ACCELERATION * t * t
