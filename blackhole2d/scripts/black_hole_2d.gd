extends Node2D
class_name MikoBlackHole2D
## Cinematic black-hole sprite with isolated alpha and barely visible pulse.
## The sprite does not contain a rectangular star-field background.
## Visual diameter = whole disk. Physical mass is NOT derived from this pixel size.

const BLACK_HOLE_SHADER: Shader = preload("res://blackhole2d/shaders/black_hole_cinematic.gdshader")
const QUAD_TEXTURE: Texture2D = preload("res://blackhole2d/textures/black_hole_cinematic.png")

@export_range(100.0, 1100.0, 5.0) var diameter_px: float = 400.0
@export_range(0.18, 0.65, 0.01) var inclination: float = 0.29
@export_range(0.0, 3.0, 0.01) var rotation_speed: float = 0.30
@export_range(0.0, 1.0, 0.01) var lensing_strength: float = 0.60
@export_range(0.15, 2.0, 0.05) var luminosity: float = 1.0
@export_range(0.0, 1.0, 0.05) var beaming: float = 0.78
@export_range(0.0, 1.0, 0.05) var warm_palette: float = 1.0
@export var disk_enabled: bool = true
@export var lensing_enabled: bool = true
@export var animation_enabled: bool = true

var _visual: Sprite2D
var _mat: ShaderMaterial
var _elapsed: float = 0.0

func _ready() -> void:
    _visual = Sprite2D.new()
    _visual.name = "ScreenSpaceBlackHole"
    _visual.texture = QUAD_TEXTURE
    _visual.centered = true
    _visual.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
    add_child(_visual)
    _mat = ShaderMaterial.new()
    _mat.shader = BLACK_HOLE_SHADER
    _visual.material = _mat
    refresh_settings()
    set_process(true)

func _process(delta: float) -> void:
    if animation_enabled:
        _elapsed += delta
    if _mat != null:
        _mat.set_shader_parameter("animation_time", _elapsed)

func refresh_settings() -> void:
    if _visual == null or _mat == null:
        return
    _visual.scale = Vector2.ONE * (diameter_px / float(QUAD_TEXTURE.get_width()))
    _mat.set_shader_parameter("sprite_size_pixels", diameter_px)
    _mat.set_shader_parameter("disk_tilt", inclination)
    _mat.set_shader_parameter("rotation_speed", rotation_speed)
    _mat.set_shader_parameter("lensing_strength", lensing_strength)
    _mat.set_shader_parameter("disk_brightness", luminosity)
    _mat.set_shader_parameter("beaming_strength", beaming)
    _mat.set_shader_parameter("warm_palette", warm_palette)
    _mat.set_shader_parameter("show_disk", disk_enabled)
    _mat.set_shader_parameter("show_lensing", lensing_enabled)

func pause_animation(paused: bool) -> void:
    animation_enabled = not paused

func reset_animation() -> void:
    _elapsed = 0.0

func set_diameter(px: float) -> void:
    diameter_px = px
    refresh_settings()
