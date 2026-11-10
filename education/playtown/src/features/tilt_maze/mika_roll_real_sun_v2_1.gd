extends Control
## The ACTUAL rotating solar sphere/corona shaders and texture atlas from MIKA.
## Sun is drawn BEHIND magnetic rails, with a visible solid body at the centre.

const REAL_SUN_SURFACE: Texture2D = preload("res://solar/sun/sun_surface_1536x768.png")
const REAL_SUN_FLOW: Texture2D = preload("res://solar/sun/sun_plasma_flow_512x256.png")
const REAL_SUN_BODY_SHADER: Shader = preload("res://solar/sun/sun_body.gdshader")
const REAL_SUN_CORONA_SHADER: Shader = preload("res://solar/sun/sun_corona.gdshader")

var _body: ColorRect
var _corona: ColorRect
var _body_material: ShaderMaterial
var _corona_material: ShaderMaterial


func _ready() -> void:
    mouse_filter = Control.MOUSE_FILTER_IGNORE
    _corona = ColorRect.new()
    _corona.name = "RealAnimatedSolarCorona"
    _corona.mouse_filter = Control.MOUSE_FILTER_IGNORE
    _corona.color = Color.WHITE
    _corona_material = ShaderMaterial.new()
    _corona_material.shader = REAL_SUN_CORONA_SHADER
    _corona_material.set_shader_parameter("solar_radius", 0.641)
    _corona_material.set_shader_parameter("corona_strength", 1.14)
    _corona.material = _corona_material
    add_child(_corona)

    _body = ColorRect.new()
    _body.name = "RealRotatingSolarSurface"
    _body.mouse_filter = Control.MOUSE_FILTER_IGNORE
    _body.color = Color.WHITE
    _body_material = ShaderMaterial.new()
    _body_material.shader = REAL_SUN_BODY_SHADER
    _body_material.set_shader_parameter("surface_tex", REAL_SUN_SURFACE)
    _body_material.set_shader_parameter("plasma_flow", REAL_SUN_FLOW)
    _body_material.set_shader_parameter("rotation_seconds", 21.0)
    _body_material.set_shader_parameter("activity", 0.40)
    _body.material = _body_material
    add_child(_body)
    resized.connect(_layout_sun)
    _layout_sun()


func _layout_sun() -> void:
    if _body == null:
        return
    # The corona texture covers the full node; the surface occupies 64.1%.
    _corona.position = Vector2.ZERO
    _corona.size = size
    var diameter: float = minf(size.x, size.y) * 0.641
    _body.size = Vector2.ONE * diameter
    _body.position = (size - _body.size) * 0.5
