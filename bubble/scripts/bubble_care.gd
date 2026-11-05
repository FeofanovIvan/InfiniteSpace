extends Node2D
class_name MikaBubbleCare
## Four body-only care animations; mouth/eyes remain unchanged texture sprites.
## Bowl and bath are temporary procedural props, not production assets.

const ACTIONS: Array[String] = ["eat", "drink", "brush_teeth", "bath"]
const SAT_KEYS: Array[String] = ["sat0", "sat1", "sat2", "sat3", "sat4"]
const SAT_RADII: Array[float] = [52.0, 49.0, 53.0, 46.0, 24.0]
const BASE_POINTS: Array[Vector2] = [
    Vector2(-157.0, -76.0), Vector2(160.0, -86.0),
    Vector2(130.0, 120.0), Vector2(-138.0, 118.0), Vector2(22.0, -171.0)
]

@export_enum("eat", "drink", "brush_teeth", "bath") var initial_action: String = "eat"
@export var standalone_autoplay: bool = false
@export_range(0.5, 2.0, 0.05) var playback_rate: float = 1.0
@export_range(0.4, 1.8, 0.05) var pose_amplitude: float = 1.0
@export_range(0.4, 2.0, 0.05) var spring_responsiveness: float = 1.0

@onready var body: Node2D = $Body
@onready var face: Node2D = $Body/Face
@onready var surface: ColorRect = $Body/Surface
@onready var back: Node2D = $Behind
@onready var front: Node2D = $Front

var action: String = "eat"
var elapsed: float = 0.0
var duration: float = 5.0
var progress: float = 0.0
var has_finished: bool = false
var _sat_positions: Array[Vector2] = []
var _sat_velocities: Array[Vector2] = []
var _mat: ShaderMaterial

func _ready() -> void:
    _mat = surface.material.duplicate() as ShaderMaterial
    surface.material = _mat
    for i in range(5):
        _sat_positions.append(BASE_POINTS[i])
        _sat_velocities.append(Vector2.ZERO)
    start_care(initial_action)

func _process(delta: float) -> void:
    if standalone_autoplay:
        if has_finished:
            start_care(action)
        else:
            advance(delta)

func start_care(id: String) -> void:
    action = id if id in ACTIONS else "eat"
    match action:
        "eat": duration = 5.6
        "drink": duration = 5.2
        "brush_teeth": duration = 4.5
        "bath": duration = 6.5
    elapsed = 0.0
    progress = 0.0
    has_finished = false
    body.position = Vector2.ZERO
    body.rotation = 0.0
    body.scale = Vector2.ONE
    face.position = Vector2.ZERO
    face.rotation = 0.0
    face.scale = Vector2.ONE
    for i in range(5):
        _sat_positions[i] = BASE_POINTS[i]
        _sat_velocities[i] = Vector2.ZERO
    _apply_frame(0.0, true)

func advance(delta: float) -> void:
    if has_finished:
        return
    var dt: float = minf(delta, 0.04) * playback_rate
    elapsed = minf(elapsed + dt, duration)
    progress = clampf(elapsed / duration, 0.0, 1.0)
    _apply_frame(dt, false)
    if elapsed >= duration:
        has_finished = true

func _ease(x: float) -> float:
    var t: float = clampf(x, 0.0, 1.0)
    return t * t * (3.0 - 2.0 * t)

func _envelope(u: float, start: float, up_end: float, down_start: float, end: float) -> float:
    return _ease((u - start) / (up_end - start)) * (1.0 - _ease((u - down_start) / (end - down_start)))

func _apply_frame(dt: float, reset: bool) -> void:
    var u: float = progress
    var breath: float = sin(elapsed * TAU / 4.2)
    var amount: float = pose_amplitude
    var pose: float = _envelope(u, 0.055, 0.23, 0.82, 0.97)
    var body_target: Vector2 = Vector2(0.0, -2.0 * breath)
    var scale_target: Vector2 = Vector2.ONE * (1.0 + 0.006 * breath)
    var rot_target: float = 0.0
    var face_pos: Vector2 = Vector2.ZERO
    var lobes: Array[Vector2] = []
    for i in range(5):
        lobes.append(BASE_POINTS[i] + Vector2(1.7 * sin(elapsed * 1.4 + i), 2.5 * cos(elapsed * 1.6 + i * 0.8)))
    match action:
        "eat":
            var chew: float = sin(elapsed * TAU * 1.32) * pose
            body_target += Vector2(63.0, 68.0 + 6.0 * chew) * pose * amount
            scale_target += Vector2(0.060, -0.18) * pose * amount
            rot_target = 0.145 * pose * amount
            face_pos += Vector2(0.0, 20.0 * pose)
            lobes[1] += Vector2(50.0, 35.0) * pose * amount
            lobes[2] += Vector2(37.0, -16.0) * pose * amount
            lobes[3] += Vector2(12.0, -2.0) * pose * amount
            lobes[4] += Vector2(22.0, 28.0) * pose * amount
        "drink":
            var sip: float = maxf(0.0, sin(elapsed * TAU * 2.4)) * pose
            body_target += Vector2(55.0, 73.0 + 3.6 * sip) * pose * amount
            scale_target += Vector2(0.045, -0.165) * pose * amount
            rot_target = 0.115 * pose * amount
            face_pos += Vector2(0.0, 22.0 * pose)
            lobes[1] += Vector2(50.0, 36.0) * pose * amount
            lobes[2] += Vector2(38.0, -12.0) * pose * amount
            lobes[3] += Vector2(15.0, 0.0) * pose * amount
            lobes[4] += Vector2(17.0, 30.0) * pose * amount
        "brush_teeth":
            # Stabilize body, no face animation yet. Brush is animated separately.
            body_target += Vector2(-5.0, 8.0) * pose * amount
            scale_target += Vector2(0.015, -0.026) * pose * amount
            lobes[2] += Vector2(0.0, 11.0) * pose * amount
            lobes[3] += Vector2(0.0, 8.0) * pose * amount
            lobes[1] += Vector2(9.0, -13.0) * pose * amount
        "bath":
            # Lower the center of mass, wide soft resting pose inside a tub.
            var drift: float = 3.0 * sin(elapsed * 1.35)
            body_target += Vector2(0.0, 67.0 + drift) * pose * amount
            scale_target += Vector2(0.21, -0.25) * pose * amount
            rot_target = -0.035 * pose * amount
            face_pos += Vector2(0.0, -8.0 * pose)
            lobes[0] += Vector2(-31.0, 42.0) * pose * amount
            lobes[1] += Vector2(31.0, 40.0) * pose * amount
            lobes[2] += Vector2(40.0, 9.0) * pose * amount
            lobes[3] += Vector2(-42.0, 8.0) * pose * amount
            lobes[4] += Vector2(0.0, 40.0) * pose * amount

    var smooth: float = 1.0 if reset else 1.0 - exp(-9.0 * dt)
    body.position = body.position.lerp(body_target, smooth)
    body.scale = body.scale.lerp(scale_target, smooth)
    body.rotation = lerp_angle(body.rotation, rot_target, smooth)
    face.position = face.position.lerp(face_pos, smooth)
    _mat.set_shader_parameter("core_radius", 147.0)
    _mat.set_shader_parameter("core_size", Vector2.ONE + (scale_target - Vector2.ONE) * 0.15)
    _mat.set_shader_parameter("anim_time", elapsed)
    _mat.set_shader_parameter("quiet_level", 0.65 if action == "bath" else 0.43)
    _mat.set_shader_parameter("glow_strength", 0.72 if action == "bath" else 0.67)
    for i in range(5):
        if reset:
            _sat_positions[i] = lobes[i]
            _sat_velocities[i] = Vector2.ZERO
        else:
            var omega: float = (6.4 + i * 0.43) * spring_responsiveness
            var acceleration: Vector2 = (lobes[i] - _sat_positions[i]) * omega * omega - _sat_velocities[i] * (2.0 * 0.83 * omega)
            _sat_velocities[i] += acceleration * dt
            _sat_positions[i] += _sat_velocities[i] * dt
        var smoothness: float = 39.0 if i < 4 else 24.0
        _mat.set_shader_parameter(SAT_KEYS[i], Vector4(_sat_positions[i].x, _sat_positions[i].y, SAT_RADII[i], smoothness))
    back.queue_redraw()
    front.queue_redraw()
