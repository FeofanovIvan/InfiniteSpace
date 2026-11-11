extends "res://learning/src/features/house_search/fossil_mika_player_v2.gd"
## Fossil Hunt only: shallow 2.5D movement on two collision-safe cave floors.
## Does NOT call the old house physics, which would force Y to a fixed line.

var fossil_current_floor: int = 1
const LOWER_FRONT := 780.0
const LOWER_BACK := 708.0
const UPPER_FRONT := 466.0
const UPPER_BACK := 411.0
const LADDER_LEFT := 708.0
const LADDER_RIGHT := 828.0
const LADDER_LOWER_FRONT := 741.0
const LADDER_UPPER_FRONT := 443.0

func _physics_process(delta: float) -> void:
    if not input_enabled:
        velocity = Vector2.ZERO
        return
    var direction: Vector2 = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down") + touch_direction
    if direction.length() > 1.0:
        direction = direction.normalized()
    var motion: Vector2 = Vector2(direction.x, direction.y * 0.70) * speed * delta
    var proposed: Vector2 = position + motion
    proposed.y = clampf(proposed.y,
            LOWER_BACK if fossil_current_floor == 1 else UPPER_BACK,
            LOWER_FRONT if fossil_current_floor == 1 else UPPER_FRONT)
    var depth_ratio: float = inverse_lerp(
            LOWER_BACK if fossil_current_floor == 1 else UPPER_BACK,
            LOWER_FRONT if fossil_current_floor == 1 else UPPER_FRONT,
            proposed.y)
    # Foreground boulders narrow the bottom shelf. Upper walkway is wider.
    var left_limit: float = (245.0 + 135.0 * depth_ratio) if fossil_current_floor == 1 else (185.0 + 30.0 * depth_ratio)
    var right_limit: float = (1385.0 - 118.0 * depth_ratio) if fossil_current_floor == 1 else (1370.0 - 35.0 * depth_ratio)
    left_limit = maxf(left_limit, floor_left)
    right_limit = minf(right_limit, floor_right)
    proposed.x = clampf(proposed.x, left_limit, maxf(left_limit + 1.0, right_limit))
    # The ladder is a physical obstacle at the FRONT of each walkway. The
    # background lane remains passable (move up on joystick to go behind it).
    var front_threshold: float = LADDER_LOWER_FRONT if fossil_current_floor == 1 else LADDER_UPPER_FRONT
    if position.x >= LADDER_LEFT and position.x <= LADDER_RIGHT and proposed.y > front_threshold:
        proposed.y = front_threshold
    elif proposed.y > front_threshold and proposed.x > LADDER_LEFT and proposed.x < LADDER_RIGHT:
        if position.x <= LADDER_LEFT:
            proposed.x = LADDER_LEFT
        elif position.x >= LADDER_RIGHT:
            proposed.x = LADDER_RIGHT
        else:
            # From the back lane, never enter the solid front ladder volume.
            proposed.y = front_threshold
    velocity = (proposed - position) / maxf(delta, 0.00001)
    position = proposed
    if direction.length_squared() > 0.015 and velocity.length_squared() > 1.0:
        if absf(direction.x) > absf(direction.y) * 0.65:
            animated_sprite.play(&"walk_right" if direction.x > 0.0 else &"walk_left")
        else:
            animated_sprite.play(&"walk_down" if direction.y > 0.0 else &"walk_up")
    else:
        animated_sprite.pause()
        animated_sprite.frame = 0
    _set_side_mirror()
