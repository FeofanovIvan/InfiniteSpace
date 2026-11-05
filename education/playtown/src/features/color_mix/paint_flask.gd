class_name PaintFlask
extends Node2D

const GLASS: Texture2D = preload("res://education/playtown/assets/color_mix/glass_flask.webp")
const INNER_MASK: Texture2D = preload("res://education/playtown/assets/color_mix/liquid_mask.webp")

var paint_color := Color.WHITE
var fill_level := 0.0
var liquid: Sprite2D
var glass: Sprite2D
var liquid_material: ShaderMaterial


func _ready() -> void:
	liquid = Sprite2D.new()
	liquid.name = "PaintBehindGlass"
	liquid.texture = INNER_MASK
	liquid.z_index = 0
	add_child(liquid)

	var shader := Shader.new()
	shader.code = """
shader_type canvas_item;
uniform vec4 paint_color : source_color = vec4(0.9, 0.2, 0.2, 0.94);
uniform float fill_level : hint_range(0.0, 1.0) = 0.0;
void fragment() {
    vec4 mask_color = texture(TEXTURE, UV);
    float surface_y = mix(0.96, 0.25, clamp(fill_level, 0.0, 1.0));
    float wave = sin(UV.x * 24.0 + TIME * 2.8) * 0.0025;
    float fluid = smoothstep(surface_y - 0.006, surface_y + 0.006, UV.y + wave);
    COLOR = vec4(paint_color.rgb, mask_color.a * paint_color.a * fluid);
}
"""
	liquid_material = ShaderMaterial.new()
	liquid_material.shader = shader
	liquid.material = liquid_material

	glass = Sprite2D.new()
	glass.name = "GlassHighlights"
	glass.texture = GLASS
	glass.z_index = 1
	add_child(glass)
	set_paint(paint_color, fill_level)


func set_paint(color: Color, amount: float) -> void:
	paint_color = color
	fill_level = clampf(amount, 0.0, 1.0)
	if liquid_material != null:
		liquid_material.set_shader_parameter("paint_color", Color(color.r, color.g, color.b, 0.95))
		liquid_material.set_shader_parameter("fill_level", fill_level)
