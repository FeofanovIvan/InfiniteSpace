extends Control
## Shared mini-game background enhancement. The very same torn-gas shader
## used by Crossroads (OtherSystem.gd), with brighter violet/pink/cyan clouds.
## Purely visual; no extra imported images and no interaction capture.
const CROSSROADS_GAS: Shader = preload("res://shaders/far_plasma.gdshader")
const LAYERS: Array[Dictionary] = [
    {"x": 0.10, "y": 0.13, "w": 0.79, "h": 0.76, "angle": -0.32, "seed": 8.3, "tint": Color(0.75, 0.37, 1.0), "opacity": 0.47, "style": 1.0},
    {"x": 0.42, "y": 0.37, "w": 0.89, "h": 0.65, "angle": 0.48, "seed": 26.9, "tint": Color(0.98, 0.41, 0.79), "opacity": 0.39, "style": 2.0},
    {"x": 0.82, "y": 0.12, "w": 0.72, "h": 0.80, "angle": -0.75, "seed": 43.2, "tint": Color(0.53, 0.62, 1.0), "opacity": 0.43, "style": 1.0},
    {"x": 0.20, "y": 0.83, "w": 0.71, "h": 0.73, "angle": 0.65, "seed": 18.4, "tint": Color(0.54, 0.41, 1.0), "opacity": 0.40, "style": 2.0},
    {"x": 0.69, "y": 0.84, "w": 0.84, "h": 0.69, "angle": -0.28, "seed": 54.7, "tint": Color(0.89, 0.44, 0.96), "opacity": 0.44, "style": 1.0},
    {"x": 0.93, "y": 0.49, "w": 0.65, "h": 0.75, "angle": 0.54, "seed": 63.5, "tint": Color(0.35, 0.79, 1.0), "opacity": 0.32, "style": 2.0}
]
var _gas: Array[ColorRect] = []

func _ready() -> void:
    mouse_filter = Control.MOUSE_FILTER_IGNORE
    process_mode = Node.PROCESS_MODE_ALWAYS
    for i in range(LAYERS.size()):
        var spec: Dictionary = LAYERS[i]
        var cloud := ColorRect.new()
        cloud.name = "CrossroadsPaletteNebula_%02d" % i
        cloud.mouse_filter = Control.MOUSE_FILTER_IGNORE
        cloud.color = Color.WHITE
        var shader_mat := ShaderMaterial.new()
        shader_mat.shader = CROSSROADS_GAS
        shader_mat.set_shader_parameter("cloud_color", spec["tint"])
        shader_mat.set_shader_parameter("cloud_opacity", spec["opacity"])
        shader_mat.set_shader_parameter("cloud_seed", spec["seed"])
        shader_mat.set_shader_parameter("style", spec["style"])
        shader_mat.set_shader_parameter("glow_strength", 0.76)
        cloud.material = shader_mat
        add_child(cloud)
        _gas.append(cloud)
    resized.connect(_place_clouds)
    _place_clouds()

func _place_clouds() -> void:
    if _gas.is_empty() or size.x < 10.0 or size.y < 10.0:
        return
    for i in range(_gas.size()):
        var cloud: ColorRect = _gas[i]
        var spec: Dictionary = LAYERS[i]
        cloud.size = Vector2(size.x * float(spec["w"]), size.y * float(spec["h"]))
        cloud.pivot_offset = cloud.size * 0.5
        cloud.position = Vector2(size.x * float(spec["x"]), size.y * float(spec["y"])) - cloud.size * 0.5
        cloud.rotation = float(spec["angle"])
