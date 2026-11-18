extends Node2D
class_name MikaBubbleMovement
## Six locomotion actions. Root translation belongs to the demo stage/game controller.
## Purely procedural body and five independently spring-following fluid lobes.
## Eyes/mouth are the unchanged PNG layers; facial animation is deliberately absent.

@export_enum("walk_forward", "walk_backward", "strafe_left", "strafe_right", "accelerate", "brake") var initial_motion: String = "walk_forward"
@export_range(0.4, 2.0, 0.05) var gait_amplitude: float = 1.0
@export_range(0.4, 2.0, 0.05) var spring_responsiveness: float = 1.0
@export_range(0.4, 2.0, 0.05) var visual_intensity: float = 1.0
@export_range(0.5, 2.0, 0.05) var playback_rate: float = 1.0

const CORE_RADIUS: float = 147.0
const BREATH_PERIOD: float = 4.2
const SAT_COUNT: int = 5
const SAT_ANGLES: Array[float] = [-2.66, -0.49, 0.77, 2.44, -1.52]
const SAT_RADII: Array[float] = [52.0, 49.0, 53.0, 46.0, 24.0]
const SAT_KEYS: Array[String] = ["sat0", "sat1", "sat2", "sat3", "sat4"]
# Virtual depth of each lobe. Rotating about the vertical (Y) axis means
# front/back/left/right retain their height and never collapse into a 2D roll.
# All units are local to the original 800x650 liquid canvas.
const SAT_DEPTHS: Array[float] = [-169.0, 160.0, -164.0, 167.0, -114.0]

@onready var body: Node2D = $Body
@onready var surface: ColorRect = $Body/Surface
@onready var face: Node2D = $Body/Face

var motion: String = "walk_forward"
var elapsed: float = 0.0
var stride_phase: float = 0.0
var progress: float = 0.0
var moving: bool = true
var _energy: float = 0.0
# External room drive survives direction changes and actor idle transitions.
var _room_speed: float = -1.0
var _distance_pending: float = 0.0
var _steer_pending: float = 0.0
var _turn_lean: float = 0.0
# Direction is the SAME continuously filtered room heading that drives eyes.
# No negative scale, Sprite replacement, alpha fading, or reset per turn.
var _facing_heading: float = 0.0
# Short turn impulses add elastic twist without resetting the gait or SDF.
var _turn_activity: float = 0.0
var _room_sleep_goal: bool = false
var _room_sleep_blend: float = 0.0
const BED_LOBE_OFFSETS: Array[Vector2] = [
    Vector2(-30.0, 34.0), Vector2(26.0, 28.0),
    Vector2(37.0, 21.0), Vector2(-35.0, 27.0), Vector2(-10.0, 71.0)
]
# MIKA_BUBBLE_SEAMLESS_SLEEP_V8_4_7
var _sat_positions: Array[Vector2] = []
var _sat_velocities: Array[Vector2] = []
var _surface_mat: ShaderMaterial

func _ready() -> void:
    _surface_mat = surface.material.duplicate() as ShaderMaterial
    surface.material = _surface_mat
    for i in range(SAT_COUNT):
        _sat_positions.append(Vector2.ZERO)
        _sat_velocities.append(Vector2.ZERO)
    restart_motion(initial_motion)

func restart_motion(mode_id: String) -> void:
    if mode_id not in ["walk_forward", "walk_backward", "strafe_left", "strafe_right", "accelerate", "brake"]:
        mode_id = "walk_forward"
    motion = mode_id
    initial_motion = mode_id
    elapsed = 0.0
    stride_phase = 0.0
    progress = 0.0
    moving = true
    _energy = 0.22 if mode_id == "accelerate" else 1.0
    _room_speed = -1.0
    _distance_pending = 0.0
    _steer_pending = 0.0
    _turn_lean = 0.0
    _facing_heading = 0.0
    _turn_activity = 0.0
    body.position = Vector2.ZERO
    body.rotation = 0.0
    body.scale = Vector2.ONE
    face.position = Vector2.ZERO
    face.rotation = 0.0
    face.scale = Vector2.ONE
    for i in range(SAT_COUNT):
        _sat_positions[i] = _base_lobe(i)
        _sat_velocities[i] = Vector2.ZERO
    _render_pose(0.0, true)

func set_room_sleep_pose(enabled: bool) -> void:
    # Goal-only change. Do not restart motion/springs/sprite/frame.
    _room_sleep_goal = enabled

func set_facing_heading(heading_rad: float) -> void:
    # The director already smooths yaw with lerp_angle. Never restart a gait
    # or reset spring state just because the heading changes.
    _facing_heading = wrapf(heading_rad, -PI, PI)

func set_turn_activity(amount: float) -> void:
    # Used by explicit 180/360 turns. Does not touch material transparency.
    _turn_activity = clampf(amount, 0.0, 1.0)

func set_locomotion_input(mode_id: String, speed_fraction: float, traveled: float, steer_delta: float) -> void:
    # Do not call restart_motion. Lobe positions, velocities, clock and gait
    # phase continue across forward/back/side/stop and any heading change.
    if mode_id in ["walk_forward", "walk_backward", "strafe_left", "strafe_right"]:
        motion = mode_id
    if _room_speed < 0.0 and speed_fraction <= 0.025:
        _energy = 0.0
    _room_speed = clampf(speed_fraction, 0.0, 1.0)
    moving = _room_speed > 0.025
    _distance_pending += clampf(traveled, 0.0, 48.0)
    _steer_pending += clampf(steer_delta, -0.9, 0.9)

func update_drive(normalized_progress: float, active: bool) -> void:
    progress = clampf(normalized_progress, 0.0, 1.0)
    moving = active

func _process(delta: float) -> void:
    var dt: float = minf(delta, 0.05) * playback_rate
    elapsed += dt
    _render_pose(dt, false)

func _render_pose(dt: float, initial: bool) -> void:
    _room_sleep_blend = move_toward(_room_sleep_blend,
        1.0 if _room_sleep_goal else 0.0, dt * 2.1)
    var target_energy: float = _room_speed if _room_speed >= 0.0 else (1.0 if moving else 0.0)
    if motion == "accelerate":
        target_energy *= 0.20 + 0.80 * progress
    elif motion == "brake":
        target_energy *= pow(1.0 - minf(progress / 0.59, 1.0), 2.0)
    var smooth: float = 1.0 if initial else 1.0 - exp(-7.5 * dt)
    _energy = lerpf(_energy, target_energy, smooth)
    var energy: float = _energy * visual_intensity
    var gait_hz: float = 1.28
    match motion:
        "walk_backward": gait_hz = 1.04
        "strafe_left", "strafe_right": gait_hz = 1.22
        "accelerate": gait_hz = 0.85 + progress * 1.35
        "brake": gait_hz = 1.55 * maxf(0.15, energy)
    if _room_speed >= 0.0:
        # One full elastic stride per 175 world pixels actually walked.
        # A collision / stopped joystick creates no phantom steps.
        stride_phase += TAU * (_distance_pending / 175.0)
        _distance_pending = 0.0
    else:
        stride_phase += dt * TAU * gait_hz * clampf(energy, 0.0, 1.65)
    _turn_lean = lerpf(_turn_lean, clampf(_steer_pending, -0.70, 0.70), 1.0 - exp(-7.0 * dt))
    _steer_pending = 0.0

    var s: float = sin(stride_phase)
    var two_steps: float = cos(stride_phase * 2.0)
    var bounce: float = absf(s)
    var breath: float = sin(elapsed * TAU / BREATH_PERIOD)
    var drift: float = sin(elapsed * 0.62)
    var horizontal: float = 0.0
    var spin: float = 0.0
    var target_scale: Vector2 = Vector2(
        1.0 + 0.018 * breath + 0.009 * sin(elapsed * 0.44),
        1.0 + 0.013 * breath + 0.011 * cos(elapsed * 0.37))
    # Even at rest the mass continues floating, never freezes after actions.
    var target_pos: Vector2 = Vector2(drift * 2.5 + sin(elapsed * 0.29) * 1.5, -3.5 * breath + cos(elapsed * 0.34) * 1.6)
    var face_shift: Vector2 = Vector2.ZERO
    var bounce_scale: float = gait_amplitude * energy

    match motion:
        "walk_forward":
            horizontal = 1.0
            spin = 0.024 * energy + s * 0.019 * bounce_scale
            target_scale += Vector2(0.014 * two_steps, -0.011 * two_steps) * bounce_scale
            target_pos += Vector2(2.8 * s, -7.0 * bounce) * bounce_scale
            face_shift = Vector2(6.0, -2.0) * energy
        "walk_backward":
            horizontal = -1.0
            spin = -0.053 * energy + s * 0.012 * bounce_scale
            target_scale += Vector2(0.008 * two_steps, -0.009 * two_steps) * bounce_scale
            target_pos += Vector2(-2.5 * s, -4.0 * bounce) * bounce_scale
            face_shift = Vector2(-4.0, 1.0) * energy
        "strafe_left":
            horizontal = -1.0
            spin = -0.080 * energy + s * 0.025 * bounce_scale
            target_scale += Vector2(0.014, -0.008) * energy
            target_pos += Vector2(-4.6 * s, -4.0 * bounce) * bounce_scale
            face_shift = Vector2(-5.0, 0.0) * energy
        "strafe_right":
            horizontal = 1.0
            spin = 0.080 * energy - s * 0.025 * bounce_scale
            target_scale += Vector2(0.014, -0.008) * energy
            target_pos += Vector2(4.6 * s, -4.0 * bounce) * bounce_scale
            face_shift = Vector2(5.0, 0.0) * energy
        "accelerate":
            horizontal = 1.0
            spin = (0.036 + 0.093 * progress) * energy
            target_scale += Vector2(0.095 * progress + 0.016 * two_steps, -0.080 * progress - 0.012 * two_steps) * energy
            target_pos += Vector2(7.0 * progress, -6.0 * bounce) * bounce_scale
            face_shift = Vector2(5.0 + 13.0 * progress, -1.0) * energy
        "brake":
            horizontal = 1.0
            # Body squashes first; spring lobes then catch up and overshoot.
            var impact: float = exp(-2.4 * elapsed)
            spin = -0.16 * impact + 0.040 * sin(elapsed * 10.0) * exp(-3.0 * elapsed)
            target_scale += Vector2(-0.105 * impact, 0.090 * impact)
            target_pos += Vector2(-8.0 * impact, -3.0 * bounce * energy)
            face_shift = Vector2(-10.0 * impact, 3.0 * impact)

    # Keep the approved plastic sleep shape (wide and low) on this SAME
    # movement body; the lobes below retain their live spring velocities.
    var bed_breath: float = sin(elapsed * TAU / 5.9)
    target_scale += Vector2(0.16, -0.20) * _room_sleep_blend
    target_scale += Vector2(0.006, 0.006) * bed_breath * _room_sleep_blend
    target_pos += Vector2(-6.0, 56.0) * _room_sleep_blend
    spin += -0.09 * _room_sleep_blend
    # Steering bends a continuous liquid body, not an independent turn scene.
    spin += _turn_lean * 0.18 * maxf(energy, _turn_activity)
    # As the liquid turns in place, an asymmetrical wave travels through it.
    spin += 0.035 * _turn_activity * sin(elapsed * 7.0)
    spin += 0.013 * (1.0 - clampf(energy, 0.0, 1.0)) * sin(elapsed * 0.51)
    var blend: float = 1.0 if initial else 1.0 - exp(-8.0 * dt)
    body.position = body.position.lerp(target_pos, blend)
    body.scale = body.scale.lerp(target_scale, blend)
    body.rotation = lerp_angle(body.rotation, spin, blend)
    # Stable face socket. The FaceRig now places the eyes/lips separately on
    # the curved sphere, so no global squeeze, pop or whole-face visibility.
    face.position = face.position.lerp(face_shift * 0.20 + Vector2(0.0, -1.8 * breath)
        + Vector2(-4.0, 6.0) * _room_sleep_blend, blend)
    var face_compensate: Vector2 = Vector2(
        1.0 / maxf(target_scale.x, 0.20),
        1.0 / maxf(target_scale.y, 0.20))
    face.scale = face.scale.lerp(Vector2.ONE.lerp(face_compensate, _room_sleep_blend), blend)
    face.rotation = lerp_angle(face.rotation, 0.012 * sin(elapsed * 0.41), blend)
    face.visible = true
    face.z_index = 2

    _surface_mat.set_shader_parameter("anim_time", elapsed * (0.73 + energy * 0.28))
    _surface_mat.set_shader_parameter("quiet_level", lerpf(
        lerpf(0.58, 0.06, clampf(energy, 0.0, 1.0)), 0.62, _room_sleep_blend))
    _surface_mat.set_shader_parameter("liquid_activity", lerpf(0.46, 0.96, clampf(energy, 0.0, 1.0)))
    _surface_mat.set_shader_parameter("core_radius", CORE_RADIUS)
    _surface_mat.set_shader_parameter("core_size", Vector2(
        1.0 + 0.014 * breath + 0.007 * sin(elapsed * 0.36),
        1.0 - 0.012 * breath + 0.009 * cos(elapsed * 0.31)))
    _surface_mat.set_shader_parameter("glow_strength", 0.68)

    for i in range(SAT_COUNT):
        var target: Vector2 = _target_lobe(i, energy, horizontal, s)
        if initial:
            _sat_positions[i] = target
            _sat_velocities[i] = Vector2.ZERO
        else:
            # Each bubble has its own damped spring and mass-dependent delay.
            var omega: float = spring_responsiveness * (6.6 - float(i) * 0.28)
            var damping: float = 0.76 if motion == "brake" else 0.88
            var accel: Vector2 = (target - _sat_positions[i]) * omega * omega - _sat_velocities[i] * (2.0 * damping * omega)
            _sat_velocities[i] += accel * dt
            _sat_positions[i] += _sat_velocities[i] * dt
        # Keep lobes on the outside while allowing strong liquid overlap.
        var min_radius: float = CORE_RADIUS + SAT_RADII[i] * 0.27
        if _sat_positions[i].length() < min_radius:
            var outward: Vector2 = _sat_positions[i].normalized()
            if outward.is_zero_approx():
                outward = _base_lobe(i).normalized()
            _sat_positions[i] = outward * min_radius
            _sat_velocities[i] *= 0.65
        var t: float = elapsed
        var radius_float: float = 0.96 + 0.095 * sin(t * (0.75 + float(i) * 0.19) + float(i) * 1.9)
        var merge_softness: float = 57.0 if i < 4 else 39.0
        _surface_mat.set_shader_parameter(SAT_KEYS[i], Vector4(_sat_positions[i].x, _sat_positions[i].y, SAT_RADII[i] * radius_float, merge_softness))

func _base_lobe(index: int) -> Vector2:
    var angle: float = SAT_ANGLES[index]
    # More overlap with central volume: lobes look born from its membrane.
    var radius: float = CORE_RADIUS + SAT_RADII[index] * 0.46 + 1.5
    return Vector2(cos(angle), sin(angle)) * radius

func _target_lobe(index: int, energy: float, horizontal: float, stride: float) -> Vector2:
    var j: float = float(index)
    var calmness: float = 1.0 - clampf(energy, 0.0, 1.0)
    # Slow fluid circulation runs when standing, sleeping or watching the room.
    # The moving lobe has a changing angular home, not a fixed static socket.
    var orbit_angle: float = SAT_ANGLES[index] + (
        0.13 * sin(elapsed * (0.28 + 0.037 * j) + j * 1.13) +
        0.065 * sin(elapsed * (0.43 + 0.029 * j) - j * 0.78)) * (0.70 + 0.45 * calmness)
    var target: Vector2 = Vector2(cos(orbit_angle), sin(orbit_angle)) * _base_lobe(index).length()
    # Phase-independent organic drift, including when Bubble is standing.
    target += Vector2(8.0 * sin(elapsed * (0.48 + 0.06 * j) + j * 1.1),
                      8.5 * cos(elapsed * (0.52 + 0.08 * j) - j * 0.91))
    target += target.normalized() * (8.0 * sin(elapsed * 0.68 + j * 2.27))
    var walking: float = energy * gait_amplitude
    var step_phase: float = stride_phase + (0.0 if index == 2 else PI)
    if index == 2 or index == 3:
        var lift: float = maxf(0.0, sin(step_phase))
        if motion == "walk_forward":
            target += Vector2(16.0 * horizontal * sin(step_phase), -27.0 * lift) * walking
        elif motion == "walk_backward":
            target += Vector2(12.0 * horizontal * sin(step_phase), -16.0 * lift) * walking
        elif motion == "strafe_left" or motion == "strafe_right":
            # One rounded foot anchors while the other slides laterally.
            target += Vector2(23.0 * horizontal * lift, -17.0 * lift) * walking
        elif motion == "accelerate":
            target += Vector2((13.0 + 13.0 * progress) * sin(step_phase), -23.0 * lift) * walking
        elif motion == "brake":
            target += Vector2(11.0 * exp(-elapsed * 2.0), -9.0 * lift) * walking
    else:
        var time_shift: float = elapsed * (0.78 + float(index) * 0.06) - float(index) * 0.78
        target += Vector2(2.5 * sin(time_shift), 3.0 * cos(time_shift)) * walking

    # Inertia is visible throughout the body, not just the feet.
    if motion == "walk_forward":
        target.x -= 7.0 * energy
    elif motion == "walk_backward":
        target.x += 7.0 * energy
    elif motion == "strafe_left" or motion == "strafe_right":
        target.x -= 11.0 * horizontal * energy
        if index < 2:
            target.y += 5.0 * energy
    elif motion == "accelerate":
        target.x -= (10.0 + 28.0 * progress) * energy
        if index == 4:
            target.y -= 12.0 * progress * energy
    elif motion == "brake":
        var overshoot: float = 26.0 * exp(-1.6 * elapsed)
        target.x += overshoot * (1.0 + 0.22 * sin(elapsed * 8.0))
    target += BED_LOBE_OFFSETS[index] * _room_sleep_blend
    # Rotate lobe *positions* around a virtual vertical 3D axis. A gentle
    # distance-driven roll adds sliding over the membrane while travelling.
    # This is not a screen-space roll: feet do not rotate onto the head.
    var walk_roll: float = 0.13 * sin(stride_phase * 0.72 + float(index) * 1.37) * clampf(energy, 0.0, 1.0)
    var idle_orbit: float = (0.12 + 0.08 * calmness) * sin(elapsed * (0.24 + 0.026 * j) + j * 1.06)
    var yaw: float = _facing_heading + walk_roll + idle_orbit
    var old_x: float = target.x
    target.x = old_x * cos(yaw) + SAT_DEPTHS[index] * sin(yaw)
    # Small Y parallax supports visible orbit without changing the body scale.
    target.y += 4.0 * sin(yaw) * (1.0 if index % 2 == 0 else -1.0)
    return target
