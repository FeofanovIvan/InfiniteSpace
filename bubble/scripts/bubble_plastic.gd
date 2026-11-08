extends Node2D
class_name MikaBubblePlastic
## Six independent body-plastic actions. Face textures remain unchanged.
## Explicit action states allow later integration into the main game's state machine.

const ACTIONS: Array[String] = ["detach", "rejoin", "stretch", "contract", "gas", "sleep"]
const COUNT: int = 5
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
const DETACHED_DELTA: Array[Vector2] = [
    Vector2(-135.0, -65.0),
    Vector2(140.0, -85.0),
    Vector2(128.0, 95.0),
    Vector2(-145.0, 102.0),
    Vector2(19.0, -118.0)
]

@export_enum("detach", "rejoin", "stretch", "contract", "gas", "sleep") var initial_action: String = "detach"
@export var standalone_autoplay: bool = false
@export_range(0.45, 1.95, 0.05) var spring_responsiveness: float = 1.0
@export_range(0.50, 1.60, 0.05) var pose_amplitude: float = 1.0
@export_range(0.50, 2.00, 0.05) var playback_rate: float = 1.0

@onready var body: Node2D = $Body
@onready var face: Node2D = $Body/Face
@onready var surface: ColorRect = $Body/Surface
@onready var gas_cloud: Node2D = $GasCloud

var action: String = "detach"
var elapsed: float = 0.0
var duration: float = 3.0
var progress: float = 0.0
var has_finished: bool = false
var body_offset: Vector2 = Vector2.ZERO
var current_stage: String = ""
var _hold_timer: float = 0.0
var _idle_time: float = 0.0
var _sat_pos: Array[Vector2] = []
var _sat_vel: Array[Vector2] = []
var _mat: ShaderMaterial

func _ready() -> void:
    _mat = surface.material.duplicate() as ShaderMaterial
    surface.material = _mat
    for i in range(COUNT):
        _sat_pos.append(BASE_POINTS[i])
        _sat_vel.append(Vector2.ZERO)
    start_action(initial_action)

func _process(delta: float) -> void:
    if not standalone_autoplay:
        return
    if has_finished:
        _hold_timer += delta
        hold_pose(delta)
        if _hold_timer > 1.45:
            start_action(action)
    else:
        advance(delta)

func start_action(id: String) -> void:
    action = id if id in ACTIONS else "detach"
    duration = _duration_for(action)
    progress = 0.0
    elapsed = 0.0
    _hold_timer = 0.0
    _idle_time = 0.0
    has_finished = false
    current_stage = "Подготовка"
    body_offset = Vector2.ZERO
    body.position = Vector2.ZERO
    body.rotation = 0.0
    body.scale = Vector2.ONE
    face.position = Vector2.ZERO
    face.rotation = 0.0
    face.scale = Vector2.ONE
    face.modulate.a = 1.0
    for i in range(COUNT):
        _sat_pos[i] = BASE_POINTS[i] + (DETACHED_DELTA[i] * pose_amplitude if action == "rejoin" else Vector2.ZERO)
        _sat_vel[i] = Vector2.ZERO
    _apply_frame(0.0, true)

func _duration_for(id: String) -> float:
    match id:
        "detach": return 3.20
        "rejoin": return 3.00
        "stretch": return 2.80
        "contract": return 2.90
        "gas": return 3.35
        "sleep": return 4.80
    return 3.0

func advance(delta: float) -> void:
    if has_finished:
        return
    var dt: float = minf(delta, 0.04) * playback_rate
    elapsed = minf(elapsed + dt, duration)
    _idle_time += dt
    progress = clampf(elapsed / duration, 0.0, 1.0)
    _apply_frame(dt, false)
    if elapsed >= duration:
        has_finished = true
        _hold_timer = 0.0

func hold_pose(delta: float) -> void:
    # Finished detach = detached orbit; finished sleep = quiet breathing.
    _idle_time += minf(delta, 0.04)
    _apply_frame(minf(delta, 0.04), false)

func _ease(t: float) -> float:
    var x: float = clampf(t, 0.0, 1.0)
    return x * x * (3.0 - 2.0 * x)

func _envelope(t: float, a: float, b: float, c: float, d: float) -> float:
    return _ease((t - a) / (b - a)) * (1.0 - _ease((t - c) / (d - c)))

func _apply_frame(dt: float, reset: bool) -> void:
    var u: float = progress
    var amp: float = pose_amplitude
    var breath: float = sin(_idle_time * TAU / 4.2)
    var core_target: Vector2 = Vector2.ONE * (1.0 + 0.005 * breath)
    var body_target: Vector2 = Vector2.ZERO
    var rot_target: float = 0.0
    var face_target: Vector2 = Vector2.ZERO
    var lobe_targets: Array[Vector2] = []
    var smoothing: float = 1.0 if reset else 1.0 - exp(-11.0 * dt)
    for i in range(COUNT):
        lobe_targets.append(BASE_POINTS[i] + Vector2(1.5 * sin(_idle_time * 1.8 + float(i) * 2.2), 2.3 * cos(_idle_time * 1.55 + float(i))))

    match action:
        "detach":
            # Five independently elastic satellites split away, then hover separately.
            var expansion: float = _ease((u - 0.12) / 0.56)
            current_stage = "Выделение пузырей" if u < 0.69 else "Свободные пузыри"
            core_target += Vector2(-0.030, -0.020) * sin(PI * expansion) * amp
            body_target.y = 5.0 * sin(PI * expansion)
            for i in range(COUNT):
                var hover: Vector2 = Vector2(5.5 * sin(_idle_time * 2.1 + i * 1.5), 6.0 * cos(_idle_time * 2.3 + i * 0.75))
                lobe_targets[i] += DETACHED_DELTA[i] * expansion * amp + hover * expansion
        "rejoin":
            # Starts as five separate lobes and smoothly merges each one back.
            var regroup: float = _ease((u - 0.07) / 0.79)
            current_stage = "Сближение" if u < 0.75 else "Слияние мембран"
            core_target += Vector2(0.040, 0.045) * sin(PI * regroup) * amp
            for i in range(COUNT):
                var delay: float = float(i) * 0.018
                var individual: float = _ease((u - 0.07 - delay) / 0.76)
                lobe_targets[i] += DETACHED_DELTA[i] * (1.0 - individual) * amp
                var settle: float = exp(-14.0 * maxf(u - 0.87, 0.0)) * sin((u - 0.87) * 55.0)
                lobe_targets[i] += BASE_POINTS[i].normalized() * settle * 5.0 * amp
        "stretch":
            # Diagonal elastic elongation in anticipation, high stretch then bounce back.
            var reach: float = _envelope(u, 0.11, 0.34, 0.63, 0.91)
            var rebound: float = sin(PI * _ease((u - 0.77) / 0.22)) if u >= 0.77 and u <= 0.99 else 0.0
            current_stage = "Потягивание" if u < 0.67 else "Возврат формы"
            core_target += Vector2(0.24 * reach - 0.07 * rebound, -0.15 * reach + 0.055 * rebound) * amp
            body_target.y = -16.0 * reach * amp
            rot_target = -0.085 * reach * amp
            lobe_targets[0] += Vector2(-61.0, -48.0) * reach * amp
            lobe_targets[1] += Vector2(76.0, -95.0) * reach * amp
            lobe_targets[4] += Vector2(30.0, -90.0) * reach * amp
            lobe_targets[2] += Vector2(41.0, 18.0) * reach * amp
            lobe_targets[3] += Vector2(-37.0, 12.0) * reach * amp
        "contract":
            # Compact ball: pull every lobe inward, then an overshoot spring release.
            var curl: float = _envelope(u, 0.08, 0.35, 0.64, 0.90)
            var overshoot: float = sin(PI * _ease((u - 0.84) / 0.16)) if u >= 0.84 else 0.0
            current_stage = "Сжатие" if u < 0.67 else "Упругое раскрытие"
            core_target += Vector2(-0.18 * curl + 0.045 * overshoot, -0.15 * curl + 0.034 * overshoot) * amp
            body_target.y = 24.0 * curl * amp
            for i in range(COUNT):
                lobe_targets[i] += -BASE_POINTS[i] * 0.27 * curl * amp + BASE_POINTS[i] * 0.045 * overshoot * amp
        "gas":
            # Inflation -> pressure build-up -> several puffs -> recoil and settle.
            var inflation: float = _envelope(u, 0.07, 0.29, 0.36, 0.59)
            var release: float = _envelope(u, 0.37, 0.48, 0.76, 0.97)
            var pulse: float = sin((u - 0.37) * TAU * 7.0) * release
            current_stage = "Накопление газа" if u < 0.39 else ("Выброс газа" if u < 0.80 else "Восстановление")
            core_target += Vector2(0.14 * inflation - 0.022 * pulse, 0.13 * inflation + 0.018 * pulse) * amp
            body_target.x = (-9.0 * inflation - 10.0 * release + 4.0 * pulse) * amp
            rot_target = -0.021 * pulse * amp
            for i in range(COUNT):
                lobe_targets[i] += BASE_POINTS[i].normalized() * (11.0 * inflation + 4.0 * pulse) * amp
        "sleep":
            # Relaxed wide pose stays low, breathing slows once settled.
            var settle: float = _ease((u - 0.04) / 0.46)
            current_stage = "Укладывается" if u < 0.50 else "Спокойный сон"
            var slow_breath: float = sin(_idle_time * TAU / 5.9)
            core_target += Vector2(0.16 * settle, -0.20 * settle) * amp + Vector2(0.006, 0.006) * slow_breath * settle
            body_target += Vector2(-6.0, 56.0) * settle * amp
            rot_target = -0.09 * settle * amp
            face_target = Vector2(-4.0, 6.0) * settle
            lobe_targets[0] += Vector2(-30.0, 34.0) * settle * amp
            lobe_targets[1] += Vector2(26.0, 28.0) * settle * amp
            lobe_targets[2] += Vector2(37.0, 21.0) * settle * amp
            lobe_targets[3] += Vector2(-35.0, 27.0) * settle * amp
            lobe_targets[4] += Vector2(-10.0, 71.0) * settle * amp

    body.position = body.position.lerp(body_target, smoothing)
    body.rotation = lerpf(body.rotation, rot_target, smoothing)
    body.scale = body.scale.lerp(core_target, smoothing)
    face.position = face.position.lerp(face_target, smoothing)
    # Retain proportions of PNG facial features while the material changes shape.
    var inv_scale: Vector2 = Vector2(1.0 / maxf(body.scale.x, 0.20), 1.0 / maxf(body.scale.y, 0.20))
    face.scale = face.scale.lerp(inv_scale, smoothing)
    body_offset = body.position

    _mat.set_shader_parameter("anim_time", _idle_time * 0.75)
    _mat.set_shader_parameter("quiet_level", 0.62 if action == "sleep" else 0.17)
    _mat.set_shader_parameter("core_radius", CORE_RADIUS)
    _mat.set_shader_parameter("core_size", Vector2.ONE)
    _mat.set_shader_parameter("glow_strength", 0.70)
    _mat.set_shader_parameter("bridge_enabled", 0.0)

    for i in range(COUNT):
        var target: Vector2 = lobe_targets[i]
        if reset:
            _sat_pos[i] = target if action != "rejoin" else BASE_POINTS[i] + DETACHED_DELTA[i] * amp
            _sat_vel[i] = Vector2.ZERO
        else:
            var freq: float = (9.5 - float(i) * 0.72) * spring_responsiveness
            var damping: float = 0.79 if i < 2 else 0.85
            var force: Vector2 = (target - _sat_pos[i]) * freq * freq - _sat_vel[i] * (2.0 * damping * freq)
            _sat_vel[i] += force * dt
            _sat_pos[i] += _sat_vel[i] * dt
        var softness: float = 35.0 if i < 4 else 26.0
        _mat.set_shader_parameter(SAT_KEYS[i], Vector4(_sat_pos[i].x, _sat_pos[i].y, SAT_RADII[i], softness))

    gas_cloud.call("update_phase", action == "gas", u, amp)
