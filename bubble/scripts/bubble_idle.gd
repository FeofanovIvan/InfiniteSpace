extends Node2D
class_name MikaBubbleIdle
## Single action: idle / покой. No locomotion, expressions or random impulses.
## 5 satellites are spring-followers, while the SDF shader smoothly fuses them.

@export_range(0.5, 1.75, 0.05) var time_scale: float = 1.0
@export_range(0.0, 2.0, 0.05) var breathing_amount: float = 1.0
@export_range(0.0, 2.0, 0.05) var satellite_motion: float = 1.0
@export_range(0.5, 2.0, 0.05) var follower_responsiveness: float = 1.0
@export var subtle_reposition: bool = true

const CORE_RADIUS: float = 147.0
const BREATH_PERIOD: float = 4.2
const SAT_COUNT: int = 5
const SAT_ANGLES: Array[float] = [-2.66, -0.49, 0.77, 2.44, -1.52]
const SAT_RADII: Array[float] = [52.0, 49.0, 53.0, 46.0, 24.0]
const SAT_KEYS: Array[String] = ["sat0", "sat1", "sat2", "sat3", "sat4"]

@onready var body: Node2D = $Body
@onready var surface: ColorRect = $Body/Surface
@onready var face: Node2D = $Body/Face

var elapsed: float = 0.0
var _sat_positions: Array[Vector2] = []
var _sat_velocities: Array[Vector2] = []
var _surface_material: ShaderMaterial

func _ready() -> void:
    _surface_material = surface.material.duplicate() as ShaderMaterial
    surface.material = _surface_material
    for i in range(SAT_COUNT):
        _sat_positions.append(Vector2.ZERO)
        _sat_velocities.append(Vector2.ZERO)
    reset_idle()

func reset_idle() -> void:
    elapsed = 0.0
    body.position = Vector2.ZERO
    body.rotation = 0.0
    body.scale = Vector2.ONE
    face.position = Vector2.ZERO
    face.rotation = 0.0
    face.scale = Vector2.ONE
    face.modulate = Color.WHITE
    for i in range(SAT_COUNT):
        _sat_positions[i] = _satellite_target(i, 0.0, 0.0, 0.0)
        _sat_velocities[i] = Vector2.ZERO
    _apply_pose(0.0, true)

func _process(delta: float) -> void:
    var dt: float = minf(delta, 0.05) * time_scale
    elapsed += dt
    _apply_pose(dt, false)

func get_breath_label() -> String:
    var phase: float = elapsed * TAU / BREATH_PERIOD - PI * 0.5
    return "Вдох" if cos(phase) >= 0.0 else "Выдох"

func _apply_pose(dt: float, initialize: bool) -> void:
    var phase: float = elapsed * TAU / BREATH_PERIOD - PI * 0.5
    # The second sine makes the loop subtly organic but continuously periodic.
    var breath: float = 0.84 * sin(phase) + 0.16 * sin(phase * 2.0 + 0.38)
    var intensity: float = breathing_amount
    var muscle_expand: float = intensity * (0.011 * breath)
    var center_x: float = satellite_motion * 1.9 * sin(elapsed * 0.43)
    var center_y: float = -intensity * 3.1 * breath + satellite_motion * 0.8 * sin(elapsed * 0.58)
    var lean: float = satellite_motion * deg_to_rad(0.7) * sin(elapsed * 0.54)

    # Rare, slow posture changes, never a sudden twitch and never a step.
    var adjust: float = 0.0
    if subtle_reposition:
        var micro_phase: float = fposmod(elapsed, 16.0)
        adjust = smoothstep(9.0, 10.5, micro_phase) * (1.0 - smoothstep(12.0, 13.8, micro_phase))
        center_x += 3.0 * adjust * satellite_motion
        lean += deg_to_rad(0.35) * adjust * satellite_motion

    var target_pos := Vector2(center_x, center_y)
    var target_scale := Vector2(1.0 + muscle_expand, 1.0 + muscle_expand * 0.84)
    var interp: float = 1.0 if initialize else 1.0 - exp(-5.0 * dt)
    body.position = body.position.lerp(target_pos, interp)
    body.scale = body.scale.lerp(target_scale, interp)
    body.rotation = lerp_angle(body.rotation, lean, interp)

    # Faces stay aligned and retain the original PNGs. Facial animation comes later.
    face.position = face.position.lerp(Vector2(0.0, -0.9 * breath * intensity), interp)

    # The shader adds gentle, translucent surface movement over an SDF shape.
    _surface_material.set_shader_parameter("core_radius", CORE_RADIUS)
    _surface_material.set_shader_parameter("core_size", Vector2(1.0 + muscle_expand * 0.32, 1.0 + muscle_expand * 0.20))
    _surface_material.set_shader_parameter("anim_time", elapsed * 0.62)
    _surface_material.set_shader_parameter("quiet_level", 0.72)
    _surface_material.set_shader_parameter("glow_strength", 0.67)

    for i in range(SAT_COUNT):
        var target: Vector2 = _satellite_target(i, elapsed, breath, adjust)
        if initialize:
            _sat_positions[i] = target
            _sat_velocities[i] = Vector2.ZERO
        else:
            # Semi-implicit damped spring. Clamp dt for stability after switching windows.
            var omega: float = follower_responsiveness * (5.2 + float(i) * 0.65)
            var zeta: float = 0.88
            var a: Vector2 = (target - _sat_positions[i]) * omega * omega - _sat_velocities[i] * (2.0 * zeta * omega)
            _sat_velocities[i] += a * dt
            _sat_positions[i] += _sat_velocities[i] * dt
        var softness: float = 39.0 if i < 4 else 24.0
        _surface_material.set_shader_parameter(SAT_KEYS[i], Vector4(_sat_positions[i].x, _sat_positions[i].y, SAT_RADII[i], softness))

func _satellite_target(index: int, t: float, breath: float, adjust: float) -> Vector2:
    var j: float = float(index)
    var lag: float = j * 0.37
    var angle: float = SAT_ANGLES[index] + satellite_motion * 0.032 * sin(t * 0.75 - lag)
    var rad: float = SAT_RADII[index]
    var radius: float = CORE_RADIUS + rad * 0.79 + 6.2
    radius += breathing_amount * breath * (2.8 + 0.7 * j)
    var target: Vector2 = Vector2(cos(angle), sin(angle)) * radius
    # Each lobe drifts in a different phase. They don't walk when standing still.
    target += satellite_motion * Vector2(
        2.0 * sin(t * (0.89 + j * 0.09) - lag),
        3.0 * sin(t * (0.75 + j * 0.05) - lag * 1.8)
    )
    if index == 1:
        target += Vector2(2.0, -7.0) * adjust * satellite_motion
    if index == 4:
        target.y -= 2.0 * breath * breathing_amount
    return target
