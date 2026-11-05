extends Node2D
## Galaxy 05 / Andromeda / eight fictional planets.
## Atlas IDs remain stable. The parent stars belong to SEPARATE fictional systems.
const GLOBE_SHADER: Shader = preload("res://m31_planets/planet_globe.gdshader")
const QUAD: Texture2D = preload("res://m31_planets/textures/white_quad.png")
const CATALOG_PATH: String = "res://m31_planets/catalog.json"
const DISC_FRACTION: float = 0.804

@export_enum("m31_p01", "m31_p02", "m31_p03", "m31_p04", "m31_p05", "m31_p06", "m31_p07", "m31_p08") var planet_id: String = "m31_p01"
@export_range(32, 650, 1) var diameter_pixels: float = 210.0
@export var paused: bool = false
@export var rotate_on_start: bool = true
@export_range(-180.0, 180.0, 1.0) var start_longitude_degrees: float = 0.0
@export var sun_direction: Vector3 = Vector3(-0.40, 0.22, 0.89)

@onready var globe: Sprite2D = $Globe
@onready var ring_back: Sprite2D = $RingBack
@onready var ring_front: Sprite2D = $RingFront
const BLACK_EMISSION: Texture2D = preload("res://m31_planets/textures/black_emission.png")
var _shader_material: ShaderMaterial
var _profile: Dictionary = {}
var _angle: float = 0.0
var _cloud_angle: float = 0.0
var _spin_seconds: float = 45.0
var _cloud_multiplier: float = 1.0
var _clouds_enabled: bool = true

func _ready() -> void:
    _shader_material = ShaderMaterial.new()
    _shader_material.shader = GLOBE_SHADER
    globe.texture = QUAD
    ring_back.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
    ring_front.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
    globe.material = _shader_material
    globe.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
    set_planet(planet_id)
    set_process(rotate_on_start)

func _process(delta: float) -> void:
    if paused or _spin_seconds <= 0.0 or _shader_material == null:
        return
    var advance: float = TAU * delta / maxf(_spin_seconds, 0.05)
    _angle = wrapf(_angle + advance, 0.0, TAU)
    _cloud_angle = wrapf(_cloud_angle + advance * _cloud_multiplier, 0.0, TAU)
    _shader_material.set_shader_parameter("longitude_phase", _angle)
    _shader_material.set_shader_parameter("cloud_phase", _cloud_angle)

static func get_profiles() -> Array:
    var file: FileAccess = FileAccess.open(CATALOG_PATH, FileAccess.READ)
    if file == null:
        push_error("Missing M31 planet catalog: " + CATALOG_PATH)
        return []
    var raw: Variant = JSON.parse_string(file.get_as_text())
    if raw is Dictionary:
        return raw.get("profiles", [])
    return []

func set_planet(id: String) -> void:
    var found: Dictionary = {}
    for entry in get_profiles():
        if entry.get("id", "") == id:
            found = entry
            break
    if found.is_empty():
        push_warning("Unknown Andromeda planet: " + id)
        return
    planet_id = id
    _profile = found
    _spin_seconds = float(found.get("spin_seconds", 45.0))
    _cloud_multiplier = float(found.get("cloud_speed", 1.0))
    # Synchronous world: display the permanent day-night border, no artificial rotation.
    _angle = deg_to_rad(float(found.get("initial_longitude_degrees", start_longitude_degrees)))
    _cloud_angle = _angle
    if _shader_material == null:
        return
    var base_path: String = "res://m31_planets/textures/" + id
    var is_ringed: bool = bool(found.get("has_rings", false))
    ring_back.visible = is_ringed
    ring_front.visible = is_ringed
    if is_ringed:
        ring_back.texture = load(base_path + "_ring_back.png")
        ring_front.texture = load(base_path + "_ring_front.png")
    else:
        ring_back.texture = null
        ring_front.texture = null
    _shader_material.set_shader_parameter("surface_map", load(base_path + "_surface.jpg"))
    _shader_material.set_shader_parameter("cloud_map", load(base_path + "_clouds.png"))
    var emission_texture_path: String = base_path + "_emission.png"
    _shader_material.set_shader_parameter("emission_map", load(emission_texture_path) if ResourceLoader.exists(emission_texture_path) else BLACK_EMISSION)
    _shader_material.set_shader_parameter("emission_strength", float(found.get("emission_strength", 0.0)))
    _shader_material.set_shader_parameter("cloud_opacity", float(found.get("cloud_opacity", 0.0)) if _clouds_enabled else 0.0)
    _shader_material.set_shader_parameter("ambient_strength", float(found.get("ambient", 0.16)))
    _shader_material.set_shader_parameter("atmosphere_strength", float(found.get("atmosphere_strength", 0.45)))
    _shader_material.set_shader_parameter("atmosphere_color", Color.html(str(found.get("atmosphere_color", "#aabbcc"))))
    _shader_material.set_shader_parameter("star_light_tint", Color.html(str(found.get("star_light", "#ffffff"))))
    _shader_material.set_shader_parameter("sunlight_direction", (Vector3(0.82, 0.14, 0.30).normalized() if id == "m31_p03" else sun_direction.normalized()))
    _shader_material.set_shader_parameter("aurora_strength", 0.0)
    _shader_material.set_shader_parameter("haze_strength", 0.57 if id == "m31_p08" else 0.0)
    _shader_material.set_shader_parameter("longitude_phase", _angle)
    _shader_material.set_shader_parameter("cloud_phase", _cloud_angle)
    set_diameter(diameter_pixels)

func set_diameter(size_pixels: float) -> void:
    diameter_pixels = maxf(1.0, size_pixels)
    if globe != null:
        var factor: float = diameter_pixels / (512.0 * DISC_FRACTION)
        globe.scale = Vector2.ONE * factor
        ring_back.scale = Vector2.ONE * factor
        ring_front.scale = Vector2.ONE * factor

func set_sunlight(direction: Vector3) -> void:
    if direction.length_squared() < 0.00001:
        return
    sun_direction = direction.normalized()
    if _shader_material != null:
        _shader_material.set_shader_parameter("sunlight_direction", sun_direction)

func set_spin_seconds(seconds: float) -> void:
    # 0 = locked/static orientation; otherwise one full GAME rotation in seconds.
    _spin_seconds = maxf(seconds, 0.0)

func set_clouds_visible(visible: bool) -> void:
    _clouds_enabled = visible
    if _shader_material != null:
        _shader_material.set_shader_parameter("cloud_opacity", float(_profile.get("cloud_opacity", 0.0)) if visible else 0.0)

func set_longitude_degrees(degrees: float) -> void:
    _angle = wrapf(deg_to_rad(degrees), 0.0, TAU)
    _cloud_angle = _angle
    if _shader_material != null:
        _shader_material.set_shader_parameter("longitude_phase", _angle)
        _shader_material.set_shader_parameter("cloud_phase", _cloud_angle)

func get_profile() -> Dictionary:
    return _profile.duplicate(true)
