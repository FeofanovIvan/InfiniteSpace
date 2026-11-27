extends RefCounted
## Prologue-only cinematic trajectory. No NPC landing, planet hub or controls.
## World rendering, camera, ship and the existing black-hole visual stay in Main.

const BLACK_HOLE_WORLD: Vector2 = Vector2(6500.0, -2950.0)
const CONTROL_ONE: Vector2 = Vector2(4780.0, -2450.0)
const CONTROL_TWO: Vector2 = Vector2(2320.0, -550.0)
const EARTH_APPROACH_OFFSET: Vector2 = Vector2(-177.0, -103.0)
const EARTH_SAFE_OFFSET: Vector2 = Vector2(-210.0, -120.0)
const CRUISE_SECONDS: float = 9.7
const BRAKE_SECONDS: float = 1.25
const HOLD_SECONDS: float = 0.85
const TOTAL_SECONDS: float = CRUISE_SECONDS + BRAKE_SECONDS + HOLD_SECONDS


static func earth_hold_position(earth_world: Vector2) -> Vector2:
	# Earth is 120 px across in this world. The ship stops ~242 px away.
	return earth_world + EARTH_SAFE_OFFSET


static func world_position(seconds: float, earth_world: Vector2) -> Vector2:
	if seconds >= CRUISE_SECONDS:
		var t: float = clampf((seconds - CRUISE_SECONDS) / BRAKE_SECONDS, 0.0, 1.0)
		var smooth: float = t * t * (3.0 - 2.0 * t)
		return earth_world + EARTH_APPROACH_OFFSET.lerp(EARTH_SAFE_OFFSET, smooth)
	var u: float = clampf(seconds / CRUISE_SECONDS, 0.0, 1.0)
	var accelerated: float = 0.84 * u + 0.16 * u * u
	var v: float = 1.0 - accelerated
	var arrival: Vector2 = earth_world + EARTH_APPROACH_OFFSET
	return (v * v * v * BLACK_HOLE_WORLD
		+ 3.0 * v * v * accelerated * CONTROL_ONE
		+ 3.0 * v * accelerated * accelerated * CONTROL_TWO
		+ accelerated * accelerated * accelerated * arrival)


static func visual_scale(seconds: float) -> float:
	return lerpf(0.28, 1.0, clampf(seconds / 1.15, 0.0, 1.0))


static func heading_after_step(seconds: float, current_heading: float, displacement: Vector2, delta: float) -> float:
	if seconds >= CRUISE_SECONDS:
		return lerp_angle(current_heading, 0.0, minf(1.0, delta * 2.0))
	if displacement.length_squared() < 0.000001:
		return current_heading
	var desired: float = displacement.angle() + PI * 0.5
	var wobble: float = 0.115 * sin(seconds * 7.6) + 0.058 * sin(seconds * 3.1 + 0.4)
	var unstable: float = pow(1.0 - clampf(seconds / 2.9, 0.0, 1.0), 2.0)
	var heading_error: float = wrapf(desired + wobble - current_heading, -PI, PI)
	return current_heading + 17.0 * unstable * delta + heading_error * (1.0 - unstable) * minf(1.0, delta * 5.0)


static func camera_shake(seconds: float) -> Vector2:
	if seconds >= 3.0:
		return Vector2.ZERO
	var strength: float = pow(1.0 - seconds / 3.0, 1.5) * 13.0
	return Vector2(sin(seconds * 31.0), cos(seconds * 26.0)) * strength
