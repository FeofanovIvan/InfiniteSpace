extends Node2D
class_name MikaBubbleGesture
## Self-contained procedural body + imported face PNGs. No facial expression assets added.
## Host stage should call advance(delta). Standalone action scenes set standalone_autoplay=true.

const ACTIONS: Array[String] = ["wave", "jump", "roll", "float", "spin", "look"]
const SAT_COUNT: int = 5
const CORE_RADIUS: float = 147.0
const SAT_KEYS: Array[String] = ["sat0", "sat1", "sat2", "sat3", "sat4"]
const SAT_RADII: Array[float] = [52.0, 49.0, 53.0, 46.0, 24.0]
const BASE_POINTS: Array[Vector2] = [
    Vector2(-157.0, -76.0),
    Vector2(160.0, -86.0),
    Vector2(130.0, 120.0),
    Vector2(-138.0, 118.0),
    Vector2(22.0, -171.0)
]
const SAT_DEPTH: Array[float] = [-29.0, 34.0, -24.0, 31.0, -12.0]

@export_enum("wave", "jump", "roll", "float", "spin", "look") var initial_action: String = "wave"
@export var standalone_autoplay: bool = false
@export_range(0.4, 2.0, 0.05) var spring_responsiveness: float = 1.0
@export_range(0.4, 1.8, 0.05) var pose_amplitude: float = 1.0
@export_range(0.5, 2.0, 0.05) var playback_rate: float = 1.0

@onready var body: Node2D = $Body
@onready var face: Node2D = $Body/Face
@onready var surface: ColorRect = $Body/Surface

var action: String = "wave"
var elapsed: float = 0.0
var duration: float = 2.5
var progress: float = 0.0
var has_finished: bool = false
var motion_offset: Vector2 = Vector2.ZERO
var lift_height: float = 0.0
var face_yaw: float = 0.0
var _cooldown: float = 0.0
var _mat: ShaderMaterial
var _sat_pos: Array[Vector2] = []
var _sat_vel: Array[Vector2] = []

func _ready() -> void:
    _mat = surface.material.duplicate() as ShaderMaterial
    surface.material = _mat
    for i in range(SAT_COUNT):
        _sat_pos.append(BASE_POINTS[i])
        _sat_vel.append(Vector2.ZERO)
    start_gesture(initial_action)

func _process(delta: float) -> void:
    if not standalone_autoplay:
        return
    if has_finished:
        _cooldown += delta
        if _cooldown >= 1.05:
            start_gesture(action)
    else:
        advance(delta)

func start_gesture(id: String) -> void:
    action = id if id in ACTIONS else "wave"
    elapsed = 0.0
    progress = 0.0
    _cooldown = 0.0
    has_finished = false
    duration = _duration_for(action)
    motion_offset = Vector2.ZERO
    lift_height = 0.0
    face_yaw = 0.0
    body.position = Vector2.ZERO
    body.rotation = 0.0
    body.scale = Vector2.ONE
    face.position = Vector2.ZERO
    face.rotation = 0.0
    face.scale = Vector2.ONE
    face.modulate.a = 1.0
    for i in range(SAT_COUNT):
        _sat_pos[i] = BASE_POINTS[i]
        _sat_vel[i] = Vector2.ZERO
    _apply_frame(0.0, true)

func _duration_for(id: String) -> float:
    match id:
        "wave": return 2.65
        "jump": return 1.62
        "roll": return 2.38
        "float": return 3.50
        "spin": return 2.45
        "look": return 3.10
    return 2.5

func advance(delta: float) -> void:
    if has_finished:
        return
    var dt: float = minf(delta, 0.04) * playback_rate
    elapsed = minf(elapsed + dt, duration)
    progress = clampf(elapsed / duration, 0.0, 1.0)
    _apply_frame(dt, false)
    if elapsed >= duration:
        has_finished = true

func _ease(t: float) -> float:
    var x: float = clampf(t, 0.0, 1.0)
    return x * x * (3.0 - 2.0 * x)

func _pulse(t: float, a: float, b: float) -> float:
    # Smooth raised hump between relative timeline positions a and b.
    if t <= a or t >= b:
        return 0.0
    return sin(PI * ((t - a) / (b - a)))

func _window(t: float, start: float, rise: float, fall: float, end: float) -> float:
    return _ease((t - start) / rise) * (1.0 - _ease((t - fall) / (end - fall)))

func _apply_frame(dt: float, reset: bool) -> void:
    var u: float = progress
    var amp: float = pose_amplitude
    var breath: float = sin(elapsed * TAU / 4.2)
    var core_target: Vector2 = Vector2.ONE + Vector2.ONE * breath * 0.005
    var body_position: Vector2 = Vector2.ZERO
    var body_rotation: float = 0.0
    var face_target: Vector2 = Vector2.ZERO
    var face_target_scale: Vector2 = Vector2.ONE
    var face_alpha: float = 1.0
    var bridge_on: float = 0.0
    var bridge_data: Vector4 = Vector4.ZERO
    var lobe_targets: Array[Vector2] = []
    for i in range(SAT_COUNT):
        lobe_targets.append(BASE_POINTS[i] + Vector2(2.0 * sin(elapsed * 2.0 + i * 1.8), 2.6 * cos(elapsed * 1.6 + i)))
    lift_height = 0.0
    motion_offset = Vector2.ZERO
    face_yaw = 0.0

    match action:
        "wave":
            # One lateral lobe works as the arm; a temporary membrane bridge keeps it connected.
            var activity: float = _window(u, 0.08, 0.16, 0.82, 0.96)
            var flutter: float = sin(u * TAU * 3.0)
            body_rotation = -0.025 * activity * amp
            core_target += Vector2(-0.025, 0.015) * activity * amp
            body_position.x = -9.0 * activity * amp
            lobe_targets[1] += Vector2(70.0 + 15.0 * flutter, -84.0 + 40.0 * flutter) * activity * amp
            lobe_targets[0] += Vector2(-14.0, 8.0) * activity
            lobe_targets[4] += Vector2(9.0, -13.0) * activity
            bridge_on = 1.0 if activity > 0.02 else 0.0
            var bridge_point: Vector2 = (Vector2(126.0, -65.0) + lobe_targets[1]) * 0.5
            bridge_data = Vector4(bridge_point.x, bridge_point.y, 47.0, 51.0)
        "jump":
            # Anticipation -> takeoff -> airborne -> squash landing -> settle.
            var crouch: float = _pulse(u, 0.0, 0.22)
            var airborne: float = _pulse(u, 0.16, 0.76)
            var impact: float = _pulse(u, 0.74, 0.91)
            var rebound: float = _pulse(u, 0.88, 1.0)
            lift_height = 168.0 * airborne * amp + 17.0 * rebound * amp
            body_position.y = -lift_height + 16.0 * crouch + 24.0 * impact
            core_target += Vector2(0.10 * crouch - 0.05 * airborne + 0.13 * impact,
                                   -0.12 * crouch + 0.08 * airborne - 0.14 * impact) * amp
            for i in range(SAT_COUNT):
                lobe_targets[i] += Vector2(0.0, 19.0 * crouch - 20.0 * airborne + 10.0 * impact)
            lobe_targets[2] += Vector2(26.0 * airborne, 31.0 * crouch - 24.0 * airborne)
            lobe_targets[3] += Vector2(-26.0 * airborne, 31.0 * crouch - 24.0 * airborne)
        "roll":
            # A full somersault / 2D roll. Unlike spin, the face rolls together with the body.
            var step: float = _ease(u)
            body_rotation = TAU * step
            motion_offset.x = (step * 2.0 - 1.0) * 165.0 * amp
            var compress: float = 0.07 * absf(sin(TAU * step))
            core_target += Vector2(-compress, compress * 0.75)
            body_position.y = 15.0 * absf(sin(PI * step))
            for i in range(SAT_COUNT):
                lobe_targets[i] += Vector2(cos(elapsed * 6.0 + i) * 8.0, sin(elapsed * 6.0 + i * 0.8) * 8.0) * amp
        "float":
            # Weightless drift: central core ascends while the satellites trail at different phases.
            var ascent: float = _ease(clampf(u / 0.30, 0.0, 1.0))
            var descent: float = 1.0 - _ease(clampf((u - 0.70) / 0.30, 0.0, 1.0))
            var flight: float = ascent * descent
            lift_height = 120.0 * flight * amp
            body_position.y = -lift_height - 8.0 * sin(elapsed * 3.4) * flight
            body_rotation = 0.075 * sin(elapsed * 1.8) * flight
            motion_offset.x = 17.0 * sin(PI * u) * amp
            core_target += Vector2(0.024, 0.018) * flight
            for i in range(SAT_COUNT):
                lobe_targets[i] += Vector2(13.0 * sin(elapsed * 2.0 + i * 1.7),
                                          11.0 * sin(elapsed * 2.5 + i * 0.7)) * flight * amp
            lobe_targets[2] += Vector2(0.0, 17.0 * flight)
            lobe_targets[3] += Vector2(0.0, 17.0 * flight)
        "spin":
            # Full upright yaw (360°) with face vanishing on rear hemisphere.
            var yaw: float = TAU * _ease(u)
            face_yaw = yaw
            var cs: float = cos(yaw)
            var sn: float = sin(yaw)
            body_rotation = 0.025 * sin(2.0 * yaw)
            core_target += Vector2(-0.07 * absf(sn), 0.02 * absf(sn))
            body_position.y = -8.0 * absf(sn) * amp
            face_target.x = 46.0 * sn
            face_target_scale.x = maxf(0.035, absf(cs))
            face_alpha = _ease(clampf((cs + 0.18) / 0.36, 0.0, 1.0))
            for i in range(SAT_COUNT):
                var p: Vector2 = BASE_POINTS[i]
                lobe_targets[i] = Vector2(p.x * cs + SAT_DEPTH[i] * sn, p.y)
                lobe_targets[i] += Vector2(0.0, 6.0 * sin(elapsed * 6.0 + i * 0.6) * amp)
        "look":
            # Look left, right, upwards without changing eyes/mouth textures.
            var look_x: float = 0.0
            var look_y: float = 0.0
            if u < 0.30:
                look_x = -_ease(u / 0.19)
            elif u < 0.54:
                look_x = lerpf(-1.0, 1.0, _ease((u - 0.30) / 0.22))
            elif u < 0.77:
                look_x = 1.0
            else:
                look_x = 1.0 - _ease((u - 0.77) / 0.21)
            if u > 0.60 and u < 0.86:
                look_y = _pulse(u, 0.60, 0.86)
            face_target = Vector2(29.0 * look_x, -17.0 * look_y)
            body_rotation = -0.042 * look_x * amp
            core_target += Vector2(0.013 * absf(look_x), -0.012 * look_y)
            lobe_targets[0] += Vector2(-13.0 * look_x, 0.0)
            lobe_targets[1] += Vector2(-13.0 * look_x, 0.0)
            lobe_targets[4] += Vector2(0.0, -18.0 * look_y)
            body_position.x = 5.0 * look_x * amp

    # Dynamic physics lag: local masses follow their targets at unequal speeds.
    var smoothing: float = 1.0 if reset else 1.0 - exp(-12.0 * dt)
    body.position = body.position.lerp(body_position, smoothing)
    body.scale = body.scale.lerp(core_target, smoothing)
    # Roll needs direct rotation, rather than lerp_angle shortest path (which skips 360°).
    if action == "roll":
        body.rotation = body_rotation
    else:
        body.rotation = lerpf(body.rotation, body_rotation, smoothing)
    face.position = face.position.lerp(face_target, smoothing)
    face.scale = face.scale.lerp(face_target_scale, smoothing)
    face.modulate.a = lerpf(face.modulate.a, face_alpha, smoothing)

    _mat.set_shader_parameter("anim_time", elapsed * 0.7)
    _mat.set_shader_parameter("quiet_level", 0.22)
    _mat.set_shader_parameter("core_radius", CORE_RADIUS)
    _mat.set_shader_parameter("core_size", Vector2.ONE + (core_target - Vector2.ONE) * 0.10)
    _mat.set_shader_parameter("glow_strength", 0.68)
    _mat.set_shader_parameter("bridge_enabled", bridge_on)
    _mat.set_shader_parameter("bridge", bridge_data)

    for i in range(SAT_COUNT):
        if reset:
            _sat_pos[i] = lobe_targets[i]
            _sat_vel[i] = Vector2.ZERO
        else:
            var freq: float = (9.0 - 0.65 * float(i)) * spring_responsiveness
            var damping: float = 0.77 if i < 2 else 0.84
            var force: Vector2 = (lobe_targets[i] - _sat_pos[i]) * freq * freq - _sat_vel[i] * (2.0 * damping * freq)
            _sat_vel[i] += force * dt
            _sat_pos[i] += _sat_vel[i] * dt
        var merge_width: float = 35.0 if i < 4 else 26.0
        _mat.set_shader_parameter(SAT_KEYS[i], Vector4(_sat_pos[i].x, _sat_pos[i].y, SAT_RADII[i], merge_width))
