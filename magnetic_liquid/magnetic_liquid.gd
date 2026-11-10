extends Node2D
## InfiniteSpace (Godot 4.7 / 2D / GL Compatibility)
## Procedural, connected magnetic-metal life-form.
## No textures, Sprite2D satellites, 3D viewport or particles.

@export var idle_morph: bool = true
@export_range(0.1, 3.0, 0.05) var animation_speed: float = 1.0
@export_range(0.0, 1.0, 0.01) var default_agitation: float = 0.22
@export var metal_tint: Color = Color(0.76, 0.86, 1.0, 1.0)
@export var warm_tint: Color = Color(1.0, 0.41, 0.08, 1.0)

@onready var _body: ColorRect = $Body
var _shader_material: ShaderMaterial
var _elapsed: float = 0.0
var _form_target: float = 0.0
var _form_actual: float = 0.0
var _agitation_target: float = 0.22
var _agitation_actual: float = 0.22
var _field_target: float = 0.0
var _field_actual: float = 0.0
var _field_position: Vector2 = Vector2(0.35, -0.15)

func _ready() -> void:
    # Important: instances must not share morph/field parameter state.
    _shader_material = _body.material.duplicate() as ShaderMaterial
    _body.material = _shader_material
    _agitation_actual = default_agitation
    _agitation_target = default_agitation
    _push_parameters()

func _process(delta: float) -> void:
    _elapsed += delta * animation_speed
    var target: float = _form_target
    if idle_morph and _form_target < 0.01:
        # Remains a ring most of the time; it breathes instead of becoming a ball.
        target = 0.05 + 0.10 * (0.5 + 0.5 * sin(_elapsed * 0.48))
    var rate: float = 1.0 - exp(-delta * 2.0)
    _form_actual = lerpf(_form_actual, target, rate)
    _agitation_actual = lerpf(_agitation_actual, _agitation_target, rate)
    _field_actual = lerpf(_field_actual, _field_target, 1.0 - exp(-delta * 4.0))
    _push_parameters()

func _push_parameters() -> void:
    if _shader_material == null:
        return
    _shader_material.set_shader_parameter("phase_time", _elapsed)
    _shader_material.set_shader_parameter("morph", _form_actual)
    _shader_material.set_shader_parameter("agitation", _agitation_actual)
    _shader_material.set_shader_parameter("field_power", _field_actual)
    _shader_material.set_shader_parameter("field_point", _field_position)
    _shader_material.set_shader_parameter("metal_tint", metal_tint)
    _shader_material.set_shader_parameter("warm_tint", warm_tint)

## 0: hollow ring with connected heart, 1: unified droplet, 2: restless ring.
func set_form(mode: int) -> void:
    match mode:
        0:
            _form_target = 0.0
            _agitation_target = default_agitation
        1:
            _form_target = 1.0
            _agitation_target = 0.33
        2:
            _form_target = 0.05
            _agitation_target = 1.0
        _:
            push_warning("MagneticLiquid.set_form(): unknown form %d" % mode)

## One continuous body stretches toward the pointer/field.
## world_point is in global 2D canvas coordinates, e.g. get_global_mouse_position().
func set_magnetic_focus(world_point: Vector2, strength: float = 1.0) -> void:
    _field_position = (to_local(world_point) / 256.0).clamp(Vector2(-1.0, -1.0), Vector2(1.0, 1.0))
    _field_target = clampf(strength, 0.0, 1.0)

func clear_magnetic_focus() -> void:
    _field_target = 0.0

## For dialogue mood changes: gentle=0, agitated=1.
func set_agitation(value: float) -> void:
    _agitation_target = clampf(value, 0.0, 1.0)

## If the game needs a silent, still character.
func set_animation_enabled(enabled: bool) -> void:
    set_process(enabled)
