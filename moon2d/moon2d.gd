extends Node2D
## Reusable lunar globe for all 64 moons of the Miko atlas.
## Texture maps are artistic/procedural and are NOT satellite photographs.
const SHADER: Shader = preload("res://moon2d/moon_globe.gdshader")
const QUAD: Texture2D = preload("res://moon2d/white_quad.png")
const CATALOG_PATH: String = "res://moon2d/catalog.json"
const DISC_FRACTION: float = 0.806
@export var moon_id: String = "mw_p01_m01"
@export_range(24.0, 640.0, 1.0) var diameter_pixels: float = 140.0
@export var paused: bool = false
@export var rotation_enabled: bool = true
@export var sun_direction: Vector3 = Vector3(-0.42,0.22,0.88)
@onready var globe: Sprite2D = $Globe
var material_instance: ShaderMaterial
var profile: Dictionary = {}
var angle: float = 0.0
var spin_seconds: float = 60.0

func _ready() -> void:
    material_instance = ShaderMaterial.new()
    material_instance.shader = SHADER
    globe.texture = QUAD
    globe.material = material_instance
    globe.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
    set_moon(moon_id)
    set_process(rotation_enabled)

func _process(delta: float) -> void:
    if paused or spin_seconds <= 0.0 or material_instance == null:
        return
    angle = wrapf(angle + TAU * delta / maxf(spin_seconds, 0.1),0.0,TAU)
    material_instance.set_shader_parameter("longitude_phase",angle)

static func get_catalog() -> Array:
    var f: FileAccess = FileAccess.open(CATALOG_PATH, FileAccess.READ)
    if f == null:
        push_error("Moon atlas missing: " + CATALOG_PATH)
        return []
    var parsed: Variant = JSON.parse_string(f.get_as_text())
    if parsed is Dictionary:
        return parsed.get("profiles", [])
    return []

func set_moon(id: String) -> void:
    var entry: Dictionary = {}
    for item in get_catalog():
        if item.get("id","") == id:
            entry = item
            break
    if entry.is_empty():
        push_warning("Unknown moon ID: " + id)
        return
    moon_id = id
    profile = entry
    spin_seconds = float(entry.get("game_spin_seconds",60.0))
    angle = 0.0
    if material_instance == null:
        return
    var tex_path: String = "res://moon2d/textures/" + id + "_surface.jpg"
    material_instance.set_shader_parameter("surface_map",load(tex_path))
    material_instance.set_shader_parameter("longitude_phase",angle)
    material_instance.set_shader_parameter("sunlight_direction",sun_direction.normalized())
    material_instance.set_shader_parameter("ambient_strength",0.16 if entry.get("status","") == "REAL" else 0.20)
    material_instance.set_shader_parameter("silhouette_irregularity",float(entry.get("silhouette_irregularity",0.0)))
    material_instance.set_shader_parameter("haze_strength",float(entry.get("haze_strength",0.0)))
    var tint: Color = Color.html(str(entry.get("haze_tint","#e3a36c")))
    material_instance.set_shader_parameter("haze_color",Vector3(tint.r,tint.g,tint.b))
    set_diameter(diameter_pixels)

func set_diameter(pixels: float) -> void:
    diameter_pixels = maxf(1.0,pixels)
    if globe != null:
        globe.scale = Vector2.ONE * (diameter_pixels/(512.0*DISC_FRACTION))

func set_light_direction(direction: Vector3) -> void:
    if direction.length_squared() < 0.00001:
        return
    sun_direction = direction.normalized()
    if material_instance != null:
        material_instance.set_shader_parameter("sunlight_direction",sun_direction)

func set_rotation_seconds(seconds: float) -> void:
    # GAME VISUAL, not an actual satellite spin period.
    spin_seconds = maxf(0.0,seconds)

func get_profile() -> Dictionary:
    return profile.duplicate(true)
