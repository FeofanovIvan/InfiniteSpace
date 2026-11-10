extends Control
## Real InfiniteSpace Starfield + a subtle peripheral nebula shader.
## Pure scenery, no touch interception and no gameplay changes.

const FLIGHT_STARS: Script = preload("res://scripts/Starfield.gd")
const PERIPHERAL_NEBULA: Shader = preload("res://education/playtown/src/features/tilt_maze/mika_roll_nebula_v2_1.gdshader")

var _starfield: Node2D
var _nebula: ColorRect
var _nebula_material: ShaderMaterial
var _labyrinth_center: Vector2 = Vector2(640.0, 410.0)
var _labyrinth_radius: float = 310.0


func _ready() -> void:
    mouse_filter = Control.MOUSE_FILTER_IGNORE
    _starfield = FLIGHT_STARS.new() as Node2D
    _starfield.name = "OriginalInfiniteSpaceStarfield"
    add_child(_starfield)
    _nebula = ColorRect.new()
    _nebula.name = "PeripheralNebulaeNotOverTheMaze"
    _nebula.color = Color.WHITE
    _nebula.mouse_filter = Control.MOUSE_FILTER_IGNORE
    _nebula_material = ShaderMaterial.new()
    _nebula_material.shader = PERIPHERAL_NEBULA
    _nebula.material = _nebula_material
    add_child(_nebula)
    resized.connect(_sync_size)
    _sync_size()


func _sync_size() -> void:
    if _starfield == null or size.x < 1.0 or size.y < 1.0:
        return
    _starfield.call("resize_field", size)
    _nebula.position = Vector2.ZERO
    _nebula.size = size
    _nebula_material.set_shader_parameter("viewport_px", size)
    _nebula_material.set_shader_parameter("labyrinth_center_px", _labyrinth_center)
    _nebula_material.set_shader_parameter("labyrinth_radius_px", _labyrinth_radius)


func configure(viewport_size: Vector2, board_area: Rect2) -> void:
    position = Vector2.ZERO
    size = viewport_size
    _labyrinth_center = board_area.get_center()
    _labyrinth_radius = board_area.size.x * 0.5
    if _nebula_material != null:
        _nebula_material.set_shader_parameter("viewport_px", viewport_size)
        _nebula_material.set_shader_parameter("labyrinth_center_px", _labyrinth_center)
        _nebula_material.set_shader_parameter("labyrinth_radius_px", _labyrinth_radius)


func _process(delta: float) -> void:
    if _starfield != null and visible:
        # Reuse the exact star population and parallax of MIKA spaceflight.
        _starfield.call("advance", Vector2(10.0 * delta, 2.0 * delta))
