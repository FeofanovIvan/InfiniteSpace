extends Node2D
## Solution Lab v2 — the five supplied transparent glass drawings.
## Liquid is a separate masked sprite, always level to gravity (not rotated with the pouring animation).

const GLASSES = [
    preload("res://planet_hub/games/solution_lab/assets/01_round_bottom_flask.png"),
    preload("res://planet_hub/games/solution_lab/assets/02_erlenmeyer_flask.png"),
    preload("res://planet_hub/games/solution_lab/assets/03_straight_beaker.png"),
    preload("res://planet_hub/games/solution_lab/assets/04_long_neck_flask.png"),
    preload("res://planet_hub/games/solution_lab/assets/05_test_tube.png")
]
const MASKS = [
    preload("res://planet_hub/games/solution_lab/assets/liquid_mask_01.png"),
    preload("res://planet_hub/games/solution_lab/assets/liquid_mask_02.png"),
    preload("res://planet_hub/games/solution_lab/assets/liquid_mask_03.png"),
    preload("res://planet_hub/games/solution_lab/assets/liquid_mask_04.png"),
    preload("res://planet_hub/games/solution_lab/assets/liquid_mask_05.png")
]
const LIQUID_SHADER = preload("res://planet_hub/games/solution_lab/solution_liquid.gdshader")

var kind: int = 0
var liquid_color: Color = Color("#3bd1ff")
var fill: float = 0.78
var _glass: Sprite2D
var _liquid: Sprite2D
var _liquid_mat: ShaderMaterial

func _ready() -> void:
    _liquid = Sprite2D.new()
    _liquid.name = "MaskedLiquidVertical"
    # Non-negative relative Z is essential: a negative Z renders behind
    # the opaque parent reagent Panel and makes every vessel look empty.
    _liquid.z_index = 0
    _liquid.z_as_relative = true
    add_child(_liquid)
    _liquid_mat = ShaderMaterial.new()
    _liquid_mat.shader = LIQUID_SHADER
    _liquid.material = _liquid_mat
    _glass = Sprite2D.new()
    _glass.name = "UserSuppliedTransparentGlass"
    _glass.z_index = 1
    add_child(_glass)
    _apply()

func configure(vessel_kind: int, color: Color, amount: float = 0.78) -> void:
    kind = posmod(vessel_kind, GLASSES.size())
    liquid_color = color
    fill = clampf(amount, 0.0, 1.0)
    _apply()

func _apply() -> void:
    if _glass == null or _liquid == null or _liquid_mat == null:
        return
    _glass.texture = GLASSES[kind]
    _liquid.texture = MASKS[kind]
    _liquid_mat.set_shader_parameter("solution_color", liquid_color)
    _liquid_mat.set_shader_parameter("fill_level", fill)
    _liquid.visible = fill > 0.001

func fit_scale(max_width: float, max_height: float) -> float:
    var dims: Vector2 = GLASSES[kind].get_size()
    return minf(max_width / maxf(dims.x,1.0), max_height / maxf(dims.y,1.0))

func half_height() -> float:
    return GLASSES[kind].get_height() * 0.5 * scale.y
