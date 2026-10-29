extends Node2D
## v0.6 fixed-address clouds. No timed spawning, no positional animation.
## At most one irregular formation per 2048x2048 sky cell. A small
## displacement (<=7% cell width) and bounded cloud size guarantee clearance.
## The same world cell always has the same cloud, regardless of visit time.

const PLASMA_SHADER: Shader = preload("res://shaders/far_plasma.gdshader")
const CELL_SIZE: float = 2048.0
const CELL_COUNT: int = 1024
const SKY_SPAN: float = CELL_SIZE * float(CELL_COUNT)  # 1/4 of the full navigation wrap
const NAV_SECTOR_COUNT: int = 16384
const NAV_SECTOR_SIZE: float = 512.0
const PARALLAX: float = 0.25
const MAX_VISIBLE: int = 5
const RESCAN_DISTANCE: float = 240.0
const SCAN_RADIUS: int = 2

var _view_size: Vector2 = Vector2(1280.0, 720.0)
var _sky_camera: Vector2 = Vector2.ZERO
var _last_scan_camera: Vector2 = Vector2(10000000.0, 10000000.0)
var _need_scan: bool = true
var _rects: Array[ColorRect] = []
var _active: Array[Dictionary] = []


func _ready() -> void:
    for i in range(MAX_VISIBLE):
        var rect: ColorRect = ColorRect.new()
        rect.name = "AnchoredGas_%d" % i
        rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
        rect.visible = false
        var mat: ShaderMaterial = ShaderMaterial.new()
        mat.shader = PLASMA_SHADER
        rect.material = mat
        add_child(rect)
        _rects.append(rect)
    resize_sky(get_viewport_rect().size)


func resize_sky(view_size: Vector2) -> void:
    _view_size = view_size
    _need_scan = true
    _scan_if_needed()


func set_camera_address(sector: Vector2i, local_position: Vector2, camera_offset: Vector2) -> void:
    var wrapped_sector: Vector2i = Vector2i(posmod(sector.x, NAV_SECTOR_COUNT), posmod(sector.y, NAV_SECTOR_COUNT))
    var camera_world: Vector2 = Vector2(wrapped_sector) * NAV_SECTOR_SIZE + local_position + camera_offset
    _sky_camera = Vector2(fposmod(camera_world.x * PARALLAX, SKY_SPAN), fposmod(camera_world.y * PARALLAX, SKY_SPAN))
    _scan_if_needed()
    _position_clouds()


func active_count() -> int:
    return _active.size()


func _wrapped_diff(p: Vector2, q: Vector2) -> Vector2:
    return Vector2(
        fposmod(p.x - q.x + SKY_SPAN * 0.5, SKY_SPAN) - SKY_SPAN * 0.5,
        fposmod(p.y - q.y + SKY_SPAN * 0.5, SKY_SPAN) - SKY_SPAN * 0.5
    )


func _scan_if_needed() -> void:
    if not is_inside_tree():
        return
    if not _need_scan and _wrapped_diff(_sky_camera, _last_scan_camera).length_squared() < RESCAN_DISTANCE * RESCAN_DISTANCE:
        return
    _need_scan = false
    _last_scan_camera = _sky_camera
    var candidates: Array[Dictionary] = []
    var grid: Vector2i = Vector2i(floori(_sky_camera.x / CELL_SIZE), floori(_sky_camera.y / CELL_SIZE))
    for dy in range(-SCAN_RADIUS, SCAN_RADIUS + 1):
        for dx in range(-SCAN_RADIUS, SCAN_RADIUS + 1):
            var cell: Vector2i = Vector2i(posmod(grid.x + dx, CELL_COUNT), posmod(grid.y + dy, CELL_COUNT))
            var spec: Dictionary = _cell_spec(cell)
            if spec.is_empty():
                continue
            var delta: Vector2 = _wrapped_diff(spec["position"], _sky_camera)
            var shape_size: Vector2 = spec["size"]
            if absf(delta.x) > _view_size.x * 0.5 + shape_size.x * 0.5 + 50.0:
                continue
            if absf(delta.y) > _view_size.y * 0.5 + shape_size.y * 0.5 + 50.0:
                continue
            spec["distance_sq"] = delta.length_squared()
            candidates.append(spec)
    candidates.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return float(a["distance_sq"]) < float(b["distance_sq"]))
    _active.clear()
    for item in candidates:
        if _active.size() >= MAX_VISIBLE:
            break
        _active.append(item)
    for i in range(MAX_VISIBLE):
        var rect: ColorRect = _rects[i]
        rect.visible = i < _active.size()
        if i >= _active.size():
            continue
        var spec: Dictionary = _active[i]
        rect.size = spec["size"]
        rect.rotation = float(spec["rotation"])
        rect.pivot_offset = rect.size * 0.5
        var mat: ShaderMaterial = rect.material as ShaderMaterial
        mat.set_shader_parameter("cloud_color", spec["color"])
        mat.set_shader_parameter("cloud_opacity", float(spec["opacity"]))
        mat.set_shader_parameter("cloud_seed", float(spec["seed"]))
        mat.set_shader_parameter("style", float(spec["kind"]))
        mat.set_shader_parameter("glow_strength", float(spec["glow"]))
    _position_clouds()


func _cell_spec(cell: Vector2i) -> Dictionary:
    # Integer coordinate hashing. No RandomNumberGenerator.randomize() calls.
    var rng: RandomNumberGenerator = RandomNumberGenerator.new()
    rng.seed = int(cell.x) * 73856093 + int(cell.y) * 19349663 + 6409361
    if rng.randf() > 0.62 and cell != Vector2i.ZERO:
        return {}
    # Centers are separated by at least 0.86 * CELL_SIZE = 1761.3 pixels.
    var position: Vector2 = Vector2(cell) * CELL_SIZE + Vector2(
        rng.randf_range(-0.07, 0.07), rng.randf_range(-0.07, 0.07)) * CELL_SIZE
    var width: float = rng.randf_range(720.0, 1010.0)
    var height: float = rng.randf_range(310.0, 525.0)
    var choices: Array[Color] = [
        Color(0.13, 0.55, 0.85), Color(0.20, 0.62, 0.73),
        Color(0.53, 0.36, 0.76), Color(0.75, 0.29, 0.43),
        Color(0.79, 0.50, 0.23), Color(0.31, 0.40, 0.81)
    ]
    return {
        "position": position,
        "size": Vector2(width, height),
        "rotation": rng.randf_range(-1.3, 1.3),
        "kind": rng.randi_range(0, 2),
        "color": choices[rng.randi_range(0, choices.size() - 1)],
        "opacity": rng.randf_range(0.08, 0.18),
        "seed": rng.randf_range(0.0, 30.0),
        "glow": rng.randf_range(0.12, 0.30)
    }


func _position_clouds() -> void:
    var midpoint: Vector2 = _view_size * 0.5
    for i in range(_active.size()):
        var item: Dictionary = _active[i]
        var rect: ColorRect = _rects[i]
        var delta: Vector2 = _wrapped_diff(item["position"], _sky_camera)
        rect.position = midpoint + delta - rect.size * 0.5
