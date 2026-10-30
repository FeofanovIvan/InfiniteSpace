extends Node2D
## The Crossroads' sentient liquid world. Godot 4.x; isolated 2D asset.
## No sea, continents, static animation frames, 3D model or physics simulation.

const SURFACE_SHADER: Shader = preload("res://living_world_2d/shaders/viscous_world.gdshader")
const AURA_SHADER: Shader = preload("res://living_world_2d/shaders/liquid_aura.gdshader")
const FLARES_SHADER: Shader = preload("res://living_world_2d/shaders/liquid_flares.gdshader")
const QUAD: Texture2D = preload("res://living_world_2d/textures/white_quad.png")
const ORGANIC_NOISE: Texture2D = preload("res://living_world_2d/textures/organic_field.png")
const QUAD_PX: float = 768.0
const BODY_FRAC: float = 0.755

@export_range(96.0, 900.0, 1.0) var diameter_pixels: float = 455.0
@export_range(0.0, 2.0, 0.01) var activity: float = 0.88
@export_range(0.0, 2.0, 0.01) var viscosity: float = 0.94
@export_range(0.0, 3.0, 0.01) var flow_speed: float = 1.0
@export_range(0.0, 2.0, 0.01) var illumination: float = 0.95
@export var paused: bool = false
@export_enum("calm", "curious", "happy", "listening") var mood: String = "calm"
@export var mobile_simple_shading: bool = false
@export var flares_enabled: bool = true
@export_range(0.0, 2.0, 0.05) var flare_intensity: float = 1.0
@export_range(0.1, 2.5, 0.05) var flare_rate: float = 0.85

@onready var aura: Sprite2D = $Aura
@onready var surface: Sprite2D = $Surface
@onready var flares: Sprite2D = $Flares

var _surface_mat: ShaderMaterial
var _aura_mat: ShaderMaterial
var _flares_mat: ShaderMaterial
var _clock: float = 0.0
var _response: float = 0.0
var _voice_level: float = 0.0
var _flare_burst: float = 0.0
var _flare_angle: float = 0.0
var _palette_now: Array[Color] = []
var _palette_goal: Array[Color] = []

func _ready() -> void:
    _surface_mat = ShaderMaterial.new()
    _surface_mat.shader = SURFACE_SHADER
    _surface_mat.set_shader_parameter("organic_noise", ORGANIC_NOISE)
    _aura_mat = ShaderMaterial.new()
    _aura_mat.shader = AURA_SHADER
    _flares_mat = ShaderMaterial.new()
    _flares_mat.shader = FLARES_SHADER
    flares.texture = QUAD
    flares.material = _flares_mat
    flares.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
    surface.texture = QUAD
    surface.material = _surface_mat
    surface.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
    aura.texture = QUAD
    aura.material = _aura_mat
    aura.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
    update_diameter(diameter_pixels)
    _palette_goal = _palette(mood)
    _palette_now.clear()
    for color_value in _palette_goal:
        _palette_now.append(color_value)
    _apply_palette()
    _sync_motion()
    set_flares_enabled(flares_enabled)
    set_process(true)

func _process(delta: float) -> void:
    if paused:
        return
    _clock = fmod(_clock + delta * flow_speed, 6000.0)
    _response = move_toward(_response, _voice_level, delta * 0.30)
    _voice_level = move_toward(_voice_level, 0.0, delta * 0.52)
    _flare_burst = move_toward(_flare_burst, 0.0, delta * 0.31)
    for i in range(_palette_now.size()):
        _palette_now[i] = _palette_now[i].lerp(_palette_goal[i], minf(1.0, delta * 0.85))
    _apply_palette()
    _sync_motion()

func update_diameter(pixels: float) -> void:
    diameter_pixels = clampf(pixels, 96.0, 900.0)
    var factor: float = diameter_pixels / (QUAD_PX * BODY_FRAC)
    if surface != null and aura != null and flares != null:
        surface.scale = Vector2.ONE * factor
        aura.scale = Vector2.ONE * factor
        flares.scale = Vector2.ONE * factor

func set_mood(new_mood: String) -> void:
    if new_mood not in ["calm", "curious", "happy", "listening"]:
        push_warning("Unknown LivingWorld mood: " + new_mood)
        return
    mood = new_mood
    _palette_goal = _palette(mood)
    if _palette_now.is_empty():
        for color_value in _palette_goal:
            _palette_now.append(color_value)

func set_quality_low(is_low: bool) -> void:
    mobile_simple_shading = is_low
    if _surface_mat != null:
        _surface_mat.set_shader_parameter("detail_level", 0.0 if is_low else 1.0)
    if _flares_mat != null:
        _flares_mat.set_shader_parameter("detail_level", 0.0 if is_low else 1.0)

func react_to_interaction(local_touch: Vector2 = Vector2.ZERO, strength: float = 0.8) -> void:
    # Point expressed in local coordinates of this Node2D (not screen pixels).
    var factor: float = diameter_pixels / (QUAD_PX * BODY_FRAC)
    var position_on_quad: Vector2 = local_touch / maxf(QUAD_PX * factor * 0.5, 0.001)
    position_on_quad = position_on_quad.limit_length(0.75)
    _response = maxf(_response, clampf(strength, 0.0, 1.0))
    if _surface_mat != null:
        _surface_mat.set_shader_parameter("response_origin", position_on_quad)
    trigger_liquid_flare(local_touch, 0.52 + strength * 0.25)

func react_to_voice(amplitude: float) -> void:
    # External input hook for future translator/character dialogue; no microphone usage yet.
    _voice_level = maxf(_voice_level, clampf(amplitude, 0.0, 1.0))


func trigger_liquid_flare(local_direction: Vector2 = Vector2.ZERO, strength: float = 1.0) -> void:
    # Interactive viscous arc; the direction is local to this Node2D.
    # This is a gentle fantasy effect, never a hot solar explosion.
    if local_direction.length_squared() < 0.001:
        _flare_angle = _clock * 0.47 + 0.5
    else:
        _flare_angle = local_direction.angle()
    _flare_burst = maxf(_flare_burst, clampf(strength, 0.0, 1.0))
    _sync_motion()

func set_flares_enabled(enabled: bool) -> void:
    flares_enabled = enabled
    if flares != null:
        flares.visible = enabled

func _sync_motion() -> void:
    if _surface_mat == null:
        return
    _surface_mat.set_shader_parameter("elapsed", _clock)
    _surface_mat.set_shader_parameter("activity", activity)
    _surface_mat.set_shader_parameter("viscosity", viscosity)
    _surface_mat.set_shader_parameter("illumination", illumination)
    _surface_mat.set_shader_parameter("response_power", _response)
    _surface_mat.set_shader_parameter("detail_level", 0.0 if mobile_simple_shading else 1.0)
    _aura_mat.set_shader_parameter("elapsed", _clock)
    _aura_mat.set_shader_parameter("activity", activity)
    _aura_mat.set_shader_parameter("response_power", _response)
    if _flares_mat != null:
        _flares_mat.set_shader_parameter("elapsed", _clock)
        _flares_mat.set_shader_parameter("activity", activity)
        _flares_mat.set_shader_parameter("flare_intensity", flare_intensity if flares_enabled else 0.0)
        _flares_mat.set_shader_parameter("flare_rate", flare_rate)
        _flares_mat.set_shader_parameter("burst_power", _flare_burst)
        _flares_mat.set_shader_parameter("burst_angle", _flare_angle)
        _flares_mat.set_shader_parameter("detail_level", 0.0 if mobile_simple_shading else 1.0)

func _apply_palette() -> void:
    if _surface_mat == null or _palette_now.size() != 4:
        return
    _surface_mat.set_shader_parameter("shadow_color", _palette_now[0])
    _surface_mat.set_shader_parameter("middle_color", _palette_now[1])
    _surface_mat.set_shader_parameter("liquid_color", _palette_now[2])
    _surface_mat.set_shader_parameter("pearl_color", _palette_now[3])
    _aura_mat.set_shader_parameter("glow_color", _palette_now[2])
    if _flares_mat != null:
        _flares_mat.set_shader_parameter("core_color", _palette_now[2])
        _flares_mat.set_shader_parameter("glint_color", _palette_now[3])

func _palette(mode: String) -> Array[Color]:
    match mode:
        "curious":
            return [Color("#150c36"), Color("#423263"), Color("#70c9f0"), Color("#dbf4fa")]
        "happy":
            return [Color("#2f0a40"), Color("#80438c"), Color("#f3a4d5"), Color("#fbe9c2")]
        "listening":
            return [Color("#091932"), Color("#1b607e"), Color("#63edcc"), Color("#cbfff0")]
        _:
            return [Color("#0d0627"), Color("#3f2673"), Color("#35bed7"), Color("#c6e4ff")]
