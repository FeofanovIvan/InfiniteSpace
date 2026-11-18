extends Node2D
## Procedural metaball body, with eyes and mouth from separate transparent PNGs.
## Standalone: no references to another project or autoloads.

@export_range(0.0, 1.0, 0.01) var separation: float = 0.06
@export var auto_detach: bool = true
@export_range(0.0, 1.0, 0.01) var dirty_level: float = 0.02
@export_range(0.4, 2.5, 0.05) var motion_speed: float = 1.0

var travel_direction: float = 1.0
var walking_energy: float = 1.0

@onready var _surface: ColorRect = $Surface
@onready var _face: Node2D = $Face
@onready var _eye_l: Sprite2D = $Face/EyeLeft
@onready var _eye_r: Sprite2D = $Face/EyeRight
@onready var _mouth: Sprite2D = $Face/Mouth

const CORE_RADIUS = 147.0
const SAT_BASE_ANGLES = [-2.66, -0.49, 0.77, 2.44, -1.52]
const SAT_BASE_RADII = [52.0, 49.0, 53.0, 46.0, 24.0]
const SAT_NAMES = ["sat0", "sat1", "sat2", "sat3", "sat4"]
var _elapsed: float = 0.0
var _smooth_sep: float = 0.06

func _ready() -> void:
    # Shader materials are unique per Bubble instance.
    _surface.material = _surface.material.duplicate()
    _smooth_sep = separation
    _refresh_visuals()

func _process(delta: float) -> void:
    _elapsed += delta * motion_speed
    _smooth_sep = move_toward(_smooth_sep, separation, delta * 1.15)
    _refresh_visuals()

func _refresh_visuals() -> void:
    var mat: ShaderMaterial = _surface.material as ShaderMaterial
    if mat == null:
        return
    mat.set_shader_parameter("anim_time", _elapsed)
    mat.set_shader_parameter("core_radius", CORE_RADIUS + 2.2 * sin(_elapsed * 1.8))
    mat.set_shader_parameter("dirty_level", dirty_level)
    mat.set_shader_parameter("travel_direction", travel_direction)
    mat.set_shader_parameter("time_offset", _elapsed * 0.10)
    var walk: float = sin(_elapsed * 6.0) * walking_energy

    for i in range(SAT_NAMES.size()):
        var fi: float = float(i)
        var angle: float = SAT_BASE_ANGLES[i] + 0.055 * sin(_elapsed * 1.3 + fi * 1.7)
        var rad: float = SAT_BASE_RADII[i] + 2.8 * sin(_elapsed * 1.8 + fi * 2.2)
        var cycle: float = 0.0
        if auto_detach:
            cycle = 0.5 + 0.5 * sin(_elapsed * 0.98 + fi * 2.1)
        var spread: float = clampf(_smooth_sep + cycle * 0.52, 0.0, 1.0)
        var reach: float = CORE_RADIUS + rad * 0.74 + spread * (99.0 + rad * 0.62)
        var center: Vector2 = Vector2(cos(angle), sin(angle)) * reach
        # Independent waddle: lower bubbles take alternating soft steps.
        if i == 2 or i == 3:
            center.x += walk * 13.0 * (1.0 if i == 2 else -1.0)
            center.y += absf(walk) * 7.0 * (1.0 if i == 2 else -0.5)
        else:
            center.x += 3.0 * sin(_elapsed * 1.6 + fi)
            center.y += 3.0 * cos(_elapsed * 1.3 + fi)
        var softness: float = 34.0 if i < 4 else 19.0
        mat.set_shader_parameter(SAT_NAMES[i], Vector4(center.x, center.y, rad, softness))

    # The face stays on the central bubble.
    _face.position = Vector2(1.5 * sin(_elapsed * 0.8), 1.8 * sin(_elapsed * 1.5))
    _face.scale = Vector2.ONE * (1.0 + 0.012 * sin(_elapsed * 1.65))
    # Blink every ~4.7 seconds, very short and soft.
    var blink_phase: float = fposmod(_elapsed + 0.53, 4.65)
    var blink: float = 1.0
    if blink_phase < 0.18:
        blink = 0.13 + 0.87 * absf(cos(blink_phase / 0.18 * PI))
    _eye_l.scale.y = 0.49 * blink
    _eye_r.scale.y = 0.53 * blink
    _mouth.rotation = sin(_elapsed * 1.8) * 0.028

func gather() -> void:
    auto_detach = false
    separation = 0.0

func scatter() -> void:
    auto_detach = false
    separation = 1.0

func resume_breathing() -> void:
    separation = 0.07
    auto_detach = true

func get_max_visual_radius() -> float:
    return 375.0
