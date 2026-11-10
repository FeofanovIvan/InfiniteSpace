extends Node2D
## MIKO Crossroads | Storm V1
## Composite around UNCHANGED V2 living_world_2d; separate portable folder.
## Rendering is 2D only; no external textures, no microphone usage.

const QUAD: Texture2D = preload("res://living_world_2d/textures/white_quad.png")
const MIST_SHADER: Shader = preload("res://living_world_storm_2d/shaders/storm_mist.gdshader")
const SWIRL_SHADER: Shader = preload("res://living_world_storm_2d/shaders/storm_swirl.gdshader")
const WAVES_SHADER: Shader = preload("res://living_world_storm_2d/shaders/storm_waves.gdshader")
const LIGHTNING_SHADER: Shader = preload("res://living_world_storm_2d/shaders/storm_lightning.gdshader")
const FRONT_SHADER: Shader = preload("res://living_world_storm_2d/shaders/storm_front_ribbons.gdshader")
const QUAD_PIXELS: float = 768.0
const STORM_EXTENT: float = 2.05

@export_range(110.0, 900.0, 1.0) var diameter_pixels: float = 350.0
@export_range(0.0, 2.0, 0.01) var storm_intensity: float = 0.8
@export_range(0.0, 2.5, 0.01) var animation_speed: float = 1.0
@export_enum("calm", "communicating", "surge") var storm_state: String = "calm"
@export_enum("calm", "curious", "happy", "listening") var mood: String = "calm"
@export var paused: bool = false
@export var mobile_simple_shading: bool = false
@export var storm_enabled: bool = true

@onready var mist: Sprite2D = $BackMist
@onready var back_swirl: Sprite2D = $BackSwirls
@onready var rings: Sprite2D = $WaveRings
@onready var world = $World
@onready var front_ribbons: Sprite2D = $FrontRibbons
@onready var lightning: Sprite2D = $ArcLightning
@onready var motes = $LiquidMotes

var _materials: Array[ShaderMaterial] = []
var _sprites: Array[Sprite2D] = []
var _clock: float = 0.0
var _react_energy: float = 0.0
var _talk_energy: float = 0.0
var _manual_burst: float = 0.0
var _burst_angle: float = -0.8
var _cyan: Color = Color("#51d9df")
var _violet: Color = Color("#aa83f5")
var _cyan_target: Color = Color("#51d9df")
var _violet_target: Color = Color("#aa83f5")

func _ready() -> void:
    _sprites = [mist, back_swirl, rings, front_ribbons, lightning]
    var shaders: Array[Shader] = [MIST_SHADER, SWIRL_SHADER, WAVES_SHADER, FRONT_SHADER, LIGHTNING_SHADER]
    for i in range(_sprites.size()):
        var mat: ShaderMaterial = ShaderMaterial.new()
        mat.shader = shaders[i]
        _materials.append(mat)
        _sprites[i].texture = QUAD
        _sprites[i].material = mat
        _sprites[i].texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
    world.set_mood(mood)
    world.paused = paused
    set_quality_low(mobile_simple_shading)
    update_diameter(diameter_pixels)
    _update_palette_target()
    set_storm_enabled(storm_enabled)
    _sync_layers()
    set_process(true)

func _process(delta: float) -> void:
    if paused:
        return
    _clock = fmod(_clock + delta * animation_speed, 6000.0)
    _react_energy = move_toward(_react_energy, 0.0, delta * 0.16)
    _talk_energy = move_toward(_talk_energy, 0.0, delta * 0.55)
    _manual_burst = move_toward(_manual_burst, 0.0, delta * 0.24)
    var k: float = minf(1.0, delta * 0.6)
    _cyan = _cyan.lerp(_cyan_target, k)
    _violet = _violet.lerp(_violet_target, k)
    _sync_layers()

func update_diameter(pixels: float) -> void:
    diameter_pixels = clampf(pixels, 110.0, 900.0)
    if world == null:
        return
    world.update_diameter(diameter_pixels)
    var size_factor: float = diameter_pixels * STORM_EXTENT / QUAD_PIXELS
    for sprite in _sprites:
        sprite.scale = Vector2.ONE * size_factor
    _sync_layers()

func set_storm_state(state_name: String) -> void:
    if state_name not in ["calm", "communicating", "surge"]:
        push_warning("Unknown storm state: " + state_name)
        return
    storm_state = state_name
    match state_name:
        "calm":
            storm_intensity = 0.72
        "communicating":
            storm_intensity = 1.02
        "surge":
            storm_intensity = 1.35
    _sync_layers()

func set_mood(new_mood: String) -> void:
    if new_mood not in ["calm", "curious", "happy", "listening"]:
        return
    mood = new_mood
    if world != null:
        world.set_mood(new_mood)
    _update_palette_target()

func set_quality_low(low: bool) -> void:
    mobile_simple_shading = low
    if world != null:
        world.set_quality_low(low)
    if _sprites.size() == 5:
        rings.visible = storm_enabled and not low
        front_ribbons.visible = storm_enabled and not low
        lightning.visible = storm_enabled and not low
    _sync_layers()

func set_storm_enabled(enabled: bool) -> void:
    storm_enabled = enabled
    if _sprites.size() == 5:
        for sprite in _sprites:
            sprite.visible = enabled
        if mobile_simple_shading:
            rings.visible = false
            front_ribbons.visible = false
            lightning.visible = false
    if motes != null:
        motes.visible = enabled

func set_paused(value: bool) -> void:
    paused = value
    if world != null:
        world.paused = value

func trigger_storm(direction: Vector2 = Vector2.ZERO, strength: float = 1.0) -> void:
    var power: float = clampf(strength, 0.0, 1.0)
    _react_energy = maxf(_react_energy, power)
    _manual_burst = maxf(_manual_burst, power)
    _burst_angle = direction.angle() if direction.length_squared() > 0.00001 else -0.80
    if world != null:
        world.trigger_liquid_flare(direction, power)
    _sync_layers()

func react_to_interaction(local_touch: Vector2 = Vector2.ZERO, strength: float = 0.8) -> void:
    if world != null:
        world.react_to_interaction(local_touch, strength)
    # Do not launch a second body flare; world.react_to_interaction already does this.
    _react_energy = maxf(_react_energy, clampf(strength, 0.0, 1.0))
    _manual_burst = maxf(_manual_burst, clampf(strength * 0.72, 0.0, 1.0))
    _burst_angle = local_touch.angle() if local_touch.length_squared() > 0.00001 else -0.80
    _sync_layers()

func react_to_voice(amplitude: float) -> void:
    # Public interface ONLY: caller supplies normalized 0..1 amplitude.
    # Microphone permissions, audio capture and recognition are not connected.
    var value: float = clampf(amplitude, 0.0, 1.0)
    _talk_energy = maxf(_talk_energy, value)
    if world != null:
        world.react_to_voice(value)

func _update_palette_target() -> void:
    match mood:
        "curious":
            _cyan_target = Color("#82ddff")
            _violet_target = Color("#9372ef")
        "happy":
            _cyan_target = Color("#ffe7df")
            _violet_target = Color("#e5a0f4")
        "listening":
            _cyan_target = Color("#78ffcf")
            _violet_target = Color("#55aad1")
        _:
            _cyan_target = Color("#51d9df")
            _violet_target = Color("#aa83f5")

func _sync_layers() -> void:
    if _materials.size() != 5:
        return
    var power: float = storm_intensity if storm_enabled else 0.0
    var response: float = maxf(_react_energy, _talk_energy * 0.75)
    for mat in _materials:
        mat.set_shader_parameter("elapsed", _clock)
        mat.set_shader_parameter("intensity", power)
        mat.set_shader_parameter("response_energy", response)
        mat.set_shader_parameter("cyan_color", _cyan)
        if mat != _materials[4]:
            mat.set_shader_parameter("violet_color", _violet)
    _materials[0].set_shader_parameter("detail_level", 0.0 if mobile_simple_shading else 1.0)
    _materials[1].set_shader_parameter("detail_level", 0.0 if mobile_simple_shading else 1.0)
    _materials[4].set_shader_parameter("burst_power", _manual_burst)
    _materials[4].set_shader_parameter("burst_direction", _burst_angle)
    if motes != null and storm_enabled:
        motes.set_parameters(_clock, diameter_pixels * 0.5, power, mobile_simple_shading, _cyan, _violet)
