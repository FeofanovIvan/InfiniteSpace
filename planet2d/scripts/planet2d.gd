extends Node2D
class_name MikoPlanet2D
## MIKO Planet2D V3. Godot 4.3+ reusable 2D spherical UV projection.
## All 8 fixed Solar System presets use the same shader and independent animation phases.

const PLANET_SHADER: Shader = preload("res://planet2d/shaders/planet_globe.gdshader")
const CATALOG_PATH: String = "res://planet2d/configs/solar_system.json"
const QUAD_SIZE: float = 512.0
const DISC_FRACTION: float = 0.84

@export_enum("mercury", "venus", "earth", "mars", "jupiter", "saturn", "uranus", "neptune") var planet_id: String = "earth"
@export_range(24.0, 900.0, 1.0, "suffix:px") var diameter_pixels: float = 180.0
@export var light_direction: Vector3 = Vector3(-0.45, 0.17, 0.87)
@export var paused: bool = false
@export var custom_surface_texture: Texture2D
@export_range(-180.0, 180.0, 0.1) var start_longitude_degrees: float = 0.0

@onready var _globe: Sprite2D = $Globe
@onready var _ring_back: Sprite2D = $RingBack
@onready var _ring_front: Sprite2D = $RingFront

var _shader_mat: ShaderMaterial
var _config: Dictionary = {}
var _surface_phase: float = 0.0
var _cloud_phase: float = 0.0
var _rotation_period_seconds: float = 42.0
var _clouds_multiplier: float = 1.0
var _atmosphere: float = 0.0
var _clouds: bool = false
var _night: bool = false
var _night_strength: float = 3.0

func _ready() -> void:
	_shader_mat = ShaderMaterial.new()
	_shader_mat.shader = PLANET_SHADER
	_globe.material = _shader_mat
	_surface_phase = deg_to_rad(start_longitude_degrees)
	_cloud_phase = _surface_phase
	set_planet_type(planet_id)
	set_process(true)

func _process(delta: float) -> void:
	if paused or _shader_mat == null:
		return
	var step: float = TAU * delta / maxf(absf(_rotation_period_seconds), 0.01)
	if _rotation_period_seconds < 0.0:
		step = -step
	_surface_phase = wrapf(_surface_phase + step, 0.0, TAU)
	_cloud_phase = wrapf(_cloud_phase + step * _clouds_multiplier, 0.0, TAU)
	_shader_mat.set_shader_parameter("surface_phase", _surface_phase)
	_shader_mat.set_shader_parameter("clouds_phase", _cloud_phase)

static func catalog() -> Dictionary:
	var data: Variant = JSON.parse_string(FileAccess.get_file_as_string(CATALOG_PATH))
	if data is Dictionary:
		return data
	return {}

func set_planet_type(id: String) -> void:
	var all_planets: Dictionary = catalog().get("planets", {})
	if not all_planets.has(id):
		push_warning("MIKO Planet2D: unknown planet ID: " + id)
		return
	planet_id = id
	_config = all_planets[id]
	_rotation_period_seconds = float(_config.get("demo_rotation_sec", 42.0))
	_clouds_multiplier = float(_config.get("clouds_multiplier", 1.0))
	_atmosphere = float(_config.get("atmosphere_strength", 0.0))
	_clouds = bool(_config.get("clouds", false))
	_night = bool(_config.get("night_lights", false))
	if _globe == null or _shader_mat == null:
		return
	var path: String = "res://planet2d/textures/" + id + "_surface.jpg"
	var active_texture: Texture2D = custom_surface_texture if custom_surface_texture != null else load(path)
	_shader_mat.set_shader_parameter("surface_map", active_texture)
	_shader_mat.set_shader_parameter("clouds_map", load("res://planet2d/textures/earth_clouds_procedural.png"))
	_shader_mat.set_shader_parameter("night_map", load("res://planet2d/textures/earth_night_lights_procedural.png"))
	_shader_mat.set_shader_parameter("show_clouds", _clouds)
	_shader_mat.set_shader_parameter("show_night_lights", _night)
	_shader_mat.set_shader_parameter("cloud_opacity", float(_config.get("cloud_opacity", 0.0)))
	_shader_mat.set_shader_parameter("night_lights_strength", _night_strength)
	_shader_mat.set_shader_parameter("ambient_strength", float(_config.get("ambient_strength", 0.12)))
	_shader_mat.set_shader_parameter("atmosphere_strength", _atmosphere)
	_shader_mat.set_shader_parameter("atmosphere_color", Color.html(str(_config.get("atmosphere_color", "#ffffff"))))
	_shader_mat.set_shader_parameter("axial_tilt", deg_to_rad(float(_config.get("axial_tilt_deg", 0.0))))
	_shader_mat.set_shader_parameter("light_direction", light_direction.normalized())
	_shader_mat.set_shader_parameter("surface_phase", _surface_phase)
	_shader_mat.set_shader_parameter("clouds_phase", _cloud_phase)
	var show_rings: bool = bool(_config.get("rings", false))
	_ring_back.visible = show_rings
	_ring_front.visible = show_rings
	if show_rings:
		_ring_back.texture = load("res://planet2d/textures/saturn_ring_back.png")
		_ring_front.texture = load("res://planet2d/textures/saturn_ring_front.png")
	_update_scale()

func set_planet_diameter(px: float) -> void:
	diameter_pixels = maxf(1.0, px)
	if is_node_ready():
		_update_scale()

func _update_scale() -> void:
	_globe.scale = Vector2.ONE * diameter_pixels / (QUAD_SIZE * DISC_FRACTION)
	_ring_back.scale = Vector2.ONE * diameter_pixels / 400.0
	_ring_front.scale = _ring_back.scale

func set_rotation_period(seconds: float) -> void:
	_rotation_period_seconds = seconds if absf(seconds) >= 0.01 else 0.01

func set_rotation_phase(degrees: float) -> void:
	_surface_phase = deg_to_rad(degrees)
	_cloud_phase = _surface_phase
	if _shader_mat != null:
		_shader_mat.set_shader_parameter("surface_phase", _surface_phase)
		_shader_mat.set_shader_parameter("clouds_phase", _cloud_phase)

func set_sun_direction(direction: Vector3) -> void:
	light_direction = direction.normalized() if direction.length_squared() > 0.0 else Vector3(0.0, 0.0, 1.0)
	if _shader_mat != null:
		_shader_mat.set_shader_parameter("light_direction", light_direction)

func set_clouds_enabled(enabled: bool) -> void:
	_clouds = enabled
	if _shader_mat != null:
		_shader_mat.set_shader_parameter("show_clouds", enabled)

func set_atmosphere(value: float) -> void:
	_atmosphere = maxf(0.0, value)
	if _shader_mat != null:
		_shader_mat.set_shader_parameter("atmosphere_strength", _atmosphere)

func get_profile() -> Dictionary:
	return _config.duplicate(true)

## To replace NASA / Solar System Scope illustration with an accurate map at runtime.
func set_surface_map(texture: Texture2D) -> void:
	custom_surface_texture = texture
	if _shader_mat != null:
		_shader_mat.set_shader_parameter("surface_map", texture)

func get_rotation_period() -> float:
	return _rotation_period_seconds
