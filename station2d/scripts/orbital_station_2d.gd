extends Node2D
class_name MikoOrbitalStation2D
## Reusable programmable orbital station for MIKO. 100% CanvasItem 2D.
## Metallic spherical hub uses the same equirectangular projection principle as Planet2D.
const GLOBE_SHADER: Shader = preload("res://station2d/shaders/metal_sphere.gdshader")
const QUAD: Texture2D = preload("res://station2d/textures/white_quad.png")
const ALBEDO: Texture2D = preload("res://station2d/textures/metal_core_albedo.png")
const EMISSION: Texture2D = preload("res://station2d/textures/metal_core_emission.png")
const HALO: Texture2D = preload("res://station2d/textures/core_glow.png")
const CAP: Texture2D = preload("res://station2d/textures/core_docking_cap.png")
const RAIL_SCRIPT: Script = preload("res://station2d/scripts/station_ring_rails.gd")
const POD_TEXTURES: Array[Texture2D] = [
    preload("res://station2d/textures/module_habitat.png"),
    preload("res://station2d/textures/module_solar.png"),
    preload("res://station2d/textures/module_cargo.png"),
    preload("res://station2d/textures/module_dock.png"),
    preload("res://station2d/textures/module_greenhouse.png"),
    preload("res://station2d/textures/module_communications.png")
]

@export_range(96.0, 1200.0, 1.0, "suffix:px") var diameter_pixels: float = 490.0
@export_range(8, 24, 1) var module_count: int = 12
@export_range(-65.0, 65.0, 0.5, "suffix:deg") var ring_angle_degrees: float = -23.0
@export_range(-150.0, 150.0, 1.0, "suffix:s") var ring_period_seconds: float = 45.0
@export_range(-150.0, 150.0, 1.0, "suffix:s") var core_period_seconds: float = 34.0
@export var pause_animation: bool = false
@export var station_seed: int = 45
@export var lights_enabled: bool = true
@export var solar_panels_enabled: bool = true
@export var light_direction: Vector3 = Vector3(-0.55,-0.30,0.82)

var _spin: float = 0.0
var _core_spin: float = 0.0
var _core_mat: ShaderMaterial
var _pods: Array[Sprite2D] = []
var _rail_back: Node2D
var _rail_front: Node2D
var _core: Sprite2D
var _hardware: Sprite2D
var _halo: Sprite2D

func _ready() -> void:
    _rail_back = Node2D.new()
    _rail_back.set_script(RAIL_SCRIPT)
    _rail_back.set("draw_front",false)
    _rail_back.z_index = -4
    add_child(_rail_back)

    _halo = Sprite2D.new()
    _halo.texture = HALO
    _halo.z_index = -1
    _halo.scale = Vector2.ONE * 0.67
    add_child(_halo)

    _core_mat = ShaderMaterial.new()
    _core_mat.shader = GLOBE_SHADER
    _core_mat.set_shader_parameter("metal_map",ALBEDO)
    _core_mat.set_shader_parameter("windows_map",EMISSION)
    _core_mat.set_shader_parameter("light_direction",light_direction.normalized())
    _core_mat.set_shader_parameter("lights_strength",1.0 if lights_enabled else 0.0)
    _core = Sprite2D.new()
    _core.texture = QUAD
    _core.material = _core_mat
    _core.scale = Vector2.ONE * 0.51
    _core.z_index = 0
    add_child(_core)

    _hardware = Sprite2D.new()
    _hardware.texture = CAP
    _hardware.scale = Vector2.ONE * 0.51
    _hardware.z_index = 3
    add_child(_hardware)

    _rail_front = Node2D.new()
    _rail_front.set_script(RAIL_SCRIPT)
    _rail_front.set("draw_front",true)
    _rail_front.z_index = 2
    add_child(_rail_front)

    _build_modules()
    _apply_size()
    _update_animation(0.0)

func _build_modules() -> void:
    for old in _pods:
        if is_instance_valid(old):
            old.queue_free()
    _pods.clear()
    var rng: RandomNumberGenerator = RandomNumberGenerator.new()
    rng.seed = station_seed
    var total: int = clampi(module_count,8,24)
    for i in range(total):
        var pod: Sprite2D = Sprite2D.new()
        var id: int = (i * 7 + rng.randi_range(0,5)) % POD_TEXTURES.size()
        if not solar_panels_enabled and id == 1:
            id = 0
        pod.texture = POD_TEXTURES[id]
        pod.name = "Module_%02d" % i
        pod.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
        add_child(pod)
        _pods.append(pod)

func _apply_size() -> void:
    # Default object diameter ~= 500 local pixels. Scaling root keeps shader and ring aligned.
    scale = Vector2.ONE * (maxf(48.0,diameter_pixels)/500.0)

func _orbit_point(theta: float) -> Vector2:
    var x: float = cos(theta)*195.0
    var y: float = sin(theta)*94.0
    var a: float = deg_to_rad(ring_angle_degrees)
    return Vector2(x*cos(a)-y*sin(a),x*sin(a)+y*cos(a))

func _update_animation(delta: float) -> void:
    if not pause_animation:
        if absf(ring_period_seconds)>0.05:
            _spin = wrapf(_spin + TAU*delta/ring_period_seconds,0.0,TAU)
        if absf(core_period_seconds)>0.05:
            _core_spin = wrapf(_core_spin + TAU*delta/core_period_seconds,0.0,TAU)
    if _core_mat != null:
        _core_mat.set_shader_parameter("phase",_core_spin)
        _core_mat.set_shader_parameter("lights_strength",(0.94 + 0.06*sin(_spin*12.0)) if lights_enabled else 0.0)
    if _hardware != null:
        _hardware.rotation = -_spin * 0.12
    for rail in [_rail_back,_rail_front]:
        rail.set("module_count",_pods.size())
        rail.set("tilt_rad",deg_to_rad(ring_angle_degrees))
        rail.set("ring_phase",_spin)
        rail.queue_redraw()
    for i in range(_pods.size()):
        var theta: float = TAU*float(i)/float(_pods.size())+_spin
        var depth: float = sin(theta)
        var pod: Sprite2D = _pods[i]
        pod.position = _orbit_point(theta)
        var tangent: Vector2 = _orbit_point(theta+0.015)-pod.position
        pod.rotation = tangent.angle()
        pod.z_index = 5 if depth >= 0.0 else -2
        var factor: float = 0.15 + (depth+1.0)*0.019
        pod.scale = Vector2(factor,factor)
        pod.modulate = Color(0.86,0.95,1.0) if depth>=0.0 else Color(0.51,0.69,0.77)

func _process(delta: float) -> void:
    _update_animation(delta)

func set_station_diameter(px: float) -> void:
    diameter_pixels = maxf(px,48.0)
    if is_node_ready():
        _apply_size()

func set_spin_period(seconds: float) -> void:
    ring_period_seconds = seconds

func set_paused(value: bool) -> void:
    pause_animation = value

func set_lights(value: bool) -> void:
    lights_enabled = value

func set_module_count(value: int) -> void:
    module_count = clampi(value,8,24)
    if is_node_ready():
        _build_modules()
        _update_animation(0.0)

func get_docking_points() -> Array[Vector2]:
    ## Local-space approximate docking points (current outer module positions).
    var locations: Array[Vector2] = []
    for i in range(_pods.size()):
        locations.append(_pods[i].position)
    return locations
