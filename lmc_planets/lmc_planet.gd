extends Node2D
## Atlas-driven rotating 2D globe; drag into an existing Miko project.
## Size/rotation are GAME settings, not claimed measurements of fictional planets.
const SHADER = preload("res://lmc_planets/planet_globe.gdshader")
const BASE_TEXTURE = preload("res://lmc_planets/textures/white_quad.png")
const CATALOG_PATH = "res://lmc_planets/catalog.json"
const DISC_FRACTION = 0.804
@export_enum("lmc_p01", "lmc_p02", "lmc_p03", "lmc_p04", "lmc_p05", "lmc_p06", "lmc_p07", "lmc_p08") var planet_id: String = "lmc_p01"
@export_range(32, 650, 1) var diameter_pixels: float = 210.0
@export var paused: bool = false
@export var rotate_on_start: bool = true
@export_range(-180, 180, 1) var start_longitude_degrees: float = 0.0
@export var sun_direction: Vector3 = Vector3(-0.50, 0.22, 0.83)
@onready var globe: Sprite2D = $Globe
var _material: ShaderMaterial
var _profile: Dictionary = {}
var _angle: float = 0.0
var _cloud_angle: float = 0.0
var _spin_seconds: float = 40.0
var _cloud_multiplier: float = 1.1

func _ready() -> void:
    _material = ShaderMaterial.new()
    _material.shader = SHADER
    globe.texture = BASE_TEXTURE
    globe.material = _material
    globe.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
    _angle = deg_to_rad(start_longitude_degrees)
    _cloud_angle = _angle
    set_planet(planet_id)
    set_process(rotate_on_start)

func _process(delta: float) -> void:
    if paused or _material == null:
        return
    var change: float = TAU * delta / maxf(_spin_seconds, 0.05)
    _angle = wrapf(_angle + change, 0.0, TAU)
    _cloud_angle = wrapf(_cloud_angle + change * _cloud_multiplier, 0.0, TAU)
    _material.set_shader_parameter("longitude_phase", _angle)
    _material.set_shader_parameter("cloud_phase", _cloud_angle)

static func get_profiles() -> Array:
    var loaded: Variant = JSON.parse_string(FileAccess.get_file_as_string(CATALOG_PATH))
    if loaded is Dictionary:
        return loaded.get("profiles", [])
    return []

func set_planet(id: String) -> void:
    var found: Dictionary = {}
    for candidate in get_profiles():
        if candidate.get("id", "") == id:
            found = candidate
            break
    if found.is_empty():
        push_warning("LMC Planet2D: unknown ID: " + id)
        return
    planet_id = id
    _profile = found
    _spin_seconds = float(found.get("spin_seconds", 42.0))
    _cloud_multiplier = float(found.get("cloud_speed", 1.0))
    if _material == null:
        return
    var surface_path: String = "res://lmc_planets/textures/" + id + "_surface.jpg"
    var cloud_path: String = "res://lmc_planets/textures/" + id + "_clouds.png"
    _material.set_shader_parameter("surface_map", load(surface_path))
    _material.set_shader_parameter("cloud_map", load(cloud_path))
    _material.set_shader_parameter("cloud_opacity", float(found.get("cloud_opacity", 0.0)))
    _material.set_shader_parameter("ambient_strength", float(found.get("ambient", 0.16)))
    _material.set_shader_parameter("atmosphere_strength", float(found.get("atmosphere_strength", 0.5)))
    _material.set_shader_parameter("atmosphere_color", Color.html(str(found.get("atmosphere_color", "#aabbcc"))))
    _material.set_shader_parameter("star_light_tint", Color.html(str(found.get("star_light", "#ffffff"))))
    _material.set_shader_parameter("aurora_strength", 0.67 if id == "lmc_p08" else 0.0)
    _material.set_shader_parameter("haze_strength", 0.85 if id == "lmc_p06" else 0.0)
    _material.set_shader_parameter("sunlight_direction", sun_direction.normalized())
    _material.set_shader_parameter("longitude_phase", _angle)
    _material.set_shader_parameter("cloud_phase", _cloud_angle)
    set_diameter(diameter_pixels)

func set_diameter(size_pixels: float) -> void:
    diameter_pixels = maxf(1.0, size_pixels)
    if globe != null:
        globe.scale = Vector2.ONE * (diameter_pixels / (512.0 * DISC_FRACTION))

func set_sunlight(direction: Vector3) -> void:
    if direction.length_squared() < 0.00001:
        return
    sun_direction = direction.normalized()
    if _material != null:
        _material.set_shader_parameter("sunlight_direction", sun_direction)

func set_spin_seconds(seconds: float) -> void:
    _spin_seconds = maxf(absf(seconds), 0.05)

func set_clouds_visible(visible: bool) -> void:
    if _material != null:
        _material.set_shader_parameter("cloud_opacity", float(_profile.get("cloud_opacity", 0.0)) if visible else 0.0)

func set_longitude_degrees(degrees: float) -> void:
    _angle = wrapf(deg_to_rad(degrees), 0.0, TAU)
    _cloud_angle = _angle
    if _material != null:
        _material.set_shader_parameter("longitude_phase", _angle)
        _material.set_shader_parameter("cloud_phase", _cloud_angle)

func get_profile() -> Dictionary:
    return _profile.duplicate(true)
