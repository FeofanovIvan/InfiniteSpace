extends Node2D
class_name MikaBubbleTurn
## Turn engine: 2.5D yaw (front -> profile -> back), inertial lobes, pivot feet.
## This node manages local deformation only. Parent scene controls world translation.
## Face PNG assets remain unchanged; 2.5D compression is NOT a facial expression.

@export_enum("turn_45_left", "turn_45_right", "turn_90_left", "turn_90_right", "turn_180_left", "turn_180_right", "turn_move_left", "turn_move_right") var initial_action: String = "turn_45_right"
@export var standalone_autoplay: bool = false
@export_range(0.4, 2.0, 0.05) var spring_responsiveness: float = 1.0
@export_range(0.4, 2.0, 0.05) var pose_amplitude: float = 1.0
@export_range(0.5, 2.0, 0.05) var playback_rate: float = 1.0

const CORE_RADIUS: float = 147.0
const SAT_COUNT: int = 5
const SAT_RADII: Array[float] = [52.0, 49.0, 53.0, 46.0, 24.0]
const SAT_ANGLES: Array[float] = [-2.66, -0.49, 0.77, 2.44, -1.52]
const SAT_DEPTH: Array[float] = [-25.0, 38.0, -29.0, 31.0, -14.0]
const SAT_KEYS: Array[String] = ["sat0", "sat1", "sat2", "sat3", "sat4"]
const ACTIONS: Array[String] = ["turn_45_left", "turn_45_right", "turn_90_left", "turn_90_right", "turn_180_left", "turn_180_right", "turn_move_left", "turn_move_right"]

@onready var body: Node2D = $Body
@onready var face: Node2D = $Body/Face
@onready var surface: ColorRect = $Body/Surface

var action: String = "turn_45_right"
var elapsed: float = 0.0
var duration: float = 0.6
var turn_progress: float = 0.0
var turn_heading: float = 0.0
var has_finished: bool = false
var _last_lobe_target: Array[Vector2] = []
var _lobe_pos: Array[Vector2] = []
var _lobe_vel: Array[Vector2] = []
var _mat: ShaderMaterial
var _auto_cooldown: float = 0.0

func _ready() -> void:
    _mat = surface.material.duplicate() as ShaderMaterial
    surface.material = _mat
    for i in range(SAT_COUNT):
        _last_lobe_target.append(Vector2.ZERO)
        _lobe_pos.append(Vector2.ZERO)
        _lobe_vel.append(Vector2.ZERO)
    start_turn(initial_action)

func _process(delta: float) -> void:
    if not standalone_autoplay:
        return
    if has_finished:
        _auto_cooldown += delta
        if _auto_cooldown > 1.05:
            _auto_cooldown = 0.0
            start_turn(action)
    else:
        advance(delta)

func start_turn(action_id: String) -> void:
    action = action_id if action_id in ACTIONS else "turn_45_right"
    elapsed = 0.0
    turn_progress = 0.0
    turn_heading = 0.0
    has_finished = false
    _auto_cooldown = 0.0
    match action:
        "turn_45_left", "turn_45_right": duration = 0.50
        "turn_90_left", "turn_90_right": duration = 0.77
        "turn_180_left", "turn_180_right": duration = 1.13
        "turn_move_left", "turn_move_right": duration = 2.30
    body.position = Vector2.ZERO
    body.scale = Vector2.ONE
    body.rotation = 0.0
    face.position = Vector2.ZERO
    face.scale = Vector2.ONE
    face.modulate.a = 1.0
    for i in range(SAT_COUNT):
        _lobe_pos[i] = _base_lobe(i)
        _lobe_vel[i] = Vector2.ZERO
    _apply_frame(0.0, true)

func advance(delta: float) -> void:
    if has_finished:
        return
    var dt: float = minf(delta, 0.05) * playback_rate
    elapsed = minf(elapsed + dt, duration)
    turn_progress = clampf(elapsed / duration, 0.0, 1.0)
    _apply_frame(dt, false)
    if turn_progress >= 1.0:
        has_finished = true

func _target_angle() -> float:
    var sign_angle: float = -1.0 if action.ends_with("left") else 1.0
    if action.begins_with("turn_45"):
        return sign_angle * PI / 4.0
    if action.begins_with("turn_90"):
        return sign_angle * PI / 2.0
    return sign_angle * PI

func _ease_smooth(u: float) -> float:
    var t: float = clampf(u, 0.0, 1.0)
    return t * t * t * (t * (t * 6.0 - 15.0) + 10.0)

func _apply_frame(dt: float, reset: bool) -> void:
    var u: float = turn_progress
    var turning_part: float = u
    var pivot_part: float = u
    if action.begins_with("turn_move"):
        turning_part = clampf(u / 0.52, 0.0, 1.0)
        pivot_part = turning_part
    var ease: float = _ease_smooth(turning_part)
    var target_angle: float = _target_angle()
    # Visual yaw is 2.5D orbit projection; NOT Node2D rotation of the entire image.
    var overshoot: float = sin(PI * turning_part) * sin(TAU * turning_part) * 0.034 * pose_amplitude
    turn_heading = target_angle * (ease + overshoot)
    var cos_heading: float = cos(turn_heading)
    var sin_heading: float = sin(turn_heading)
    var exertion: float = sin(PI * turning_part)
    var anticipation: float = pow(maxf(0.0, 1.0 - turning_part * 5.0), 2.0)
    var aftershock: float = pow(maxf(0.0, turning_part - 0.73) / 0.27, 1.5)
    var settle: float = sin((turning_part - 0.73) * 19.0) * exp(-8.0 * (turning_part - 0.73)) * aftershock
    var sign_turn: float = -1.0 if target_angle < 0.0 else 1.0
    var breath: float = sin(elapsed * TAU / 4.2)
    var move_phase: float = 0.0
    var move_energy: float = 0.0
    if action.begins_with("turn_move"):
        move_energy = _ease_smooth(clampf((u - 0.48) / 0.28, 0.0, 1.0))
        move_phase = elapsed * TAU * 1.36

    var compression: float = 0.10 * exertion * pose_amplitude
    var target_scale: Vector2 = Vector2(1.0 + 0.04 * exertion, 1.0 - compression)
    target_scale += Vector2(0.007 * breath, 0.007 * breath)
    target_scale += Vector2(0.023 * settle, -0.017 * settle)
    if move_energy > 0.0:
        target_scale += Vector2(0.024, -0.018) * absf(sin(move_phase)) * move_energy
    var sway: float = 0.022 * sign_turn * exertion * pose_amplitude + 0.013 * settle
    var target_pos: Vector2 = Vector2(9.0 * sign_turn * exertion - 5.0 * sign_turn * anticipation, 18.0 * exertion + 6.0 * settle)
    if move_energy > 0.0:
        target_pos.y -= 7.0 * absf(sin(move_phase)) * move_energy

    var b: float = 1.0 if reset else 1.0 - exp(-12.0 * dt)
    body.position = body.position.lerp(target_pos, b)
    body.scale = body.scale.lerp(target_scale, b)
    body.rotation = lerp_angle(body.rotation, sway, b)

    # The PNG face visibly rotates around an imaginary spherical front surface.
    # It gets narrower in 3/4 view and disappears when looking from behind.
    var visible_front: float = clampf((cos_heading + 0.07) / 0.29, 0.0, 1.0)
    var face_scale_x: float = maxf(0.018, absf(cos_heading))
    face.position = face.position.lerp(Vector2(42.0 * sin_heading, -2.0 * exertion), b)
    face.scale = face.scale.lerp(Vector2(face_scale_x, 1.0), b)
    face.modulate.a = lerpf(face.modulate.a, visible_front, b)

    _mat.set_shader_parameter("anim_time", elapsed * 0.67)
    _mat.set_shader_parameter("quiet_level", 0.63 - 0.40 * exertion)
    _mat.set_shader_parameter("core_radius", CORE_RADIUS)
    _mat.set_shader_parameter("core_size", Vector2(1.0 + 0.004 * breath, 1.0 - 0.005 * breath))
    _mat.set_shader_parameter("glow_strength", 0.68)

    for i in range(SAT_COUNT):
        var target: Vector2 = _target_lobe(i, sin_heading, cos_heading, exertion, pivot_part, move_phase, move_energy)
        _last_lobe_target[i] = target
        if reset:
            _lobe_pos[i] = target
            _lobe_vel[i] = Vector2.ZERO
        else:
            # Unequal spring constants create staggered motion after the main pivot.
            var frequency: float = (8.8 - i * 0.60) * spring_responsiveness
            var damping: float = (0.76 if i < 2 else 0.82)
            var acc: Vector2 = (target - _lobe_pos[i]) * frequency * frequency - _lobe_vel[i] * (2.0 * damping * frequency)
            _lobe_vel[i] += acc * dt
            _lobe_pos[i] += _lobe_vel[i] * dt
        var merge: float = 36.0 if i < 4 else 24.0
        _mat.set_shader_parameter(SAT_KEYS[i], Vector4(_lobe_pos[i].x, _lobe_pos[i].y, SAT_RADII[i], merge))

func _base_lobe(i: int) -> Vector2:
    var a: float = SAT_ANGLES[i]
    var orbit: float = CORE_RADIUS + SAT_RADII[i] * 0.79 + 6.2
    return Vector2(cos(a), sin(a)) * orbit

func _target_lobe(i: int, sin_h: float, cos_h: float, exertion: float, p: float, gait_phase: float, gait: float) -> Vector2:
    var base: Vector2 = _base_lobe(i)
    var turn_direction: float = -1.0 if _target_angle() < 0.0 else 1.0
    # 3D-like x/z orbit around the central membrane. y remains vertical.
    var xrot: float = base.x * cos_h + SAT_DEPTH[i] * sin_h
    var target: Vector2 = Vector2(xrot, base.y)
    # Compression + anchoring: lower lobes alternately lift and redistribute load.
    if i == 2 or i == 3:
        var step_phase: float = PI * p * (2.0 if absf(_target_angle()) >= PI * 0.9 else 1.0) + (PI if i == 3 else 0.0)
        var lift: float = maxf(0.0, sin(step_phase))
        target += Vector2(turn_direction * (14.0 + 15.0 * exertion) * lift, -28.0 * lift * pose_amplitude)
        target.y -= 11.0 * exertion
        if gait > 0.0:
            var foot_lift: float = maxf(0.0, sin(gait_phase + (PI if i == 3 else 0.0)))
            target += Vector2(-13.0 * turn_direction * sin(gait_phase + (PI if i == 3 else 0.0)), -19.0 * foot_lift) * gait
    elif i < 2:
        target += Vector2(-turn_direction * 19.0 * exertion, -7.0 * exertion + 4.0 * sin(elapsed * 2.3 + i))
    else:
        target.y -= 8.0 * exertion
        target.x += 10.0 * sin(elapsed * 1.5)
    return target

func get_turn_degrees() -> float:
    return rad_to_deg(turn_heading)

func get_movement_fraction() -> float:
    if not action.begins_with("turn_move"):
        return 0.0
    return _ease_smooth(clampf((turn_progress - 0.49) / 0.51, 0.0, 1.0))
