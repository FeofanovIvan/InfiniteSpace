extends Control
## Fungal Paths v7. The supplied two artwork textures and our movement graph
## use one invariant image-coordinate space (1535x1024). No image stretch.
const ROUND_MASK: Shader = preload("res://planet_hub/games/fungal_paths/fungal_round_mask_v8.gdshader")
const TERRAIN: Texture2D = preload("res://planet_hub/games/fungal_paths/assets/fungal_terrain_v7.png")
const NETWORK: Texture2D = preload("res://planet_hub/games/fungal_paths/assets/fungal_network_v7.png")
const DATA_PATH: String = "res://planet_hub/games/fungal_paths/data/mycelium_trace_v7.json"
const ORIGINAL_WIDTH: float = 1535.0
const ORIGINAL_HEIGHT: float = 1024.0
const CROP_TOP: float = 35.0
const CROP_HEIGHT: float = 925.0

var map_rect: Rect2 = Rect2()
var _rounded_mask_material: ShaderMaterial
var path_data: Dictionary = {}
var _nodes: Dictionary = {}
var _neighbors: Dictionary = {}
var _edges: Dictionary = {}
var display_tracing: bool = false # Debug switch; never drawn in normal play.
var traveled_path: PackedVector2Array = PackedVector2Array()

func _ready() -> void:
    mouse_filter = Control.MOUSE_FILTER_IGNORE
    clip_contents = true
    _rounded_mask_material = ShaderMaterial.new()
    _rounded_mask_material.shader = ROUND_MASK
    material = _rounded_mask_material
    path_data = JSON.parse_string(FileAccess.get_file_as_string(DATA_PATH)) as Dictionary
    if path_data.is_empty():
        push_error("FUNGAL_V7: Failed to read mycelium network geometry")
        return
    _nodes = path_data.get("nodes", {})
    for id in _nodes:
        _neighbors[id] = []
    for raw in path_data.get("edges", []):
        if not raw is Dictionary:
            continue
        var a: String = str(raw.get("a", ""))
        var b: String = str(raw.get("b", ""))
        if not _nodes.has(a) or not _nodes.has(b):
            push_error("FUNGAL_V7: Unknown passage endpoint")
            continue
        _edges[_edge_key(a, b)] = raw
        _neighbors[a].append(b)
        _neighbors[b].append(a)
    resized.connect(_update_map_rect)
    _update_map_rect()

func _update_map_rect() -> void:
    var available: Vector2 = size - Vector2.ONE * 6.0
    if available.x < 10.0 or available.y < 10.0:
        return
    var scale_factor: float = minf(available.x / ORIGINAL_WIDTH, available.y / CROP_HEIGHT)
    var scaled: Vector2 = Vector2(ORIGINAL_WIDTH, CROP_HEIGHT) * scale_factor
    map_rect = Rect2((size - scaled) * 0.5, scaled)
    if _rounded_mask_material != null:
        _rounded_mask_material.set_shader_parameter("panel_size", size)
        _rounded_mask_material.set_shader_parameter("corner_radius", minf(27.0, minf(size.x, size.y) * 0.15))
    queue_redraw()

func _draw() -> void:
    if size.x < 10.0 or size.y < 10.0:
        return
    # The atmospheric background covers its parent frame at all aspect ratios.
    var bg_size: Vector2 = TERRAIN.get_size()
    var cover: float = maxf(size.x / bg_size.x, size.y / bg_size.y)
    var crop: Vector2 = size / cover
    draw_texture_rect_region(TERRAIN, Rect2(Vector2.ZERO, size), Rect2((bg_size - crop) * 0.5, crop))
    if map_rect.size.x < 10.0:
        return
    # Independent mycelial map: uniform scale, centered, never stretched or tiled.
    # Import size limits change Texture2D pixel dimensions. Geometry and tracing
    # remain in the original artwork space, so convert the requested source crop
    # into the current imported texture space before drawing it.
    var network_size: Vector2 = NETWORK.get_size()
    var source_scale: Vector2 = network_size / Vector2(ORIGINAL_WIDTH, ORIGINAL_HEIGHT)
    var source_crop := Rect2(
            Vector2(0.0, CROP_TOP * source_scale.y),
            Vector2(ORIGINAL_WIDTH * source_scale.x, CROP_HEIGHT * source_scale.y))
    draw_texture_rect_region(NETWORK, map_rect, source_crop)
    if display_tracing:
        for raw in _edges.values():
            var coords: PackedVector2Array = PackedVector2Array()
            for pair in raw.get("points", []):
                coords.append(_map_image_point(Vector2(float(pair[0]), float(pair[1]))))
            if coords.size() >= 2:
                draw_polyline(coords, Color(0.11, 0.94, 0.94, 0.79), maxf(1.5, map_rect.size.y * 0.003), true)

func _edge_key(a: String, b: String) -> String:
    return a + ":" + b if a < b else b + ":" + a

func _map_image_point(p: Vector2) -> Vector2:
    var s: float = map_rect.size.x / ORIGINAL_WIDTH
    return map_rect.position + Vector2(p.x, p.y - CROP_TOP) * s

func point_for(id: String) -> Vector2:
    var pair: Array = _nodes.get(id, [0.0, 0.0])
    return _map_image_point(Vector2(float(pair[0]), float(pair[1])))

func neighbors_for(id: String) -> Array[String]:
    var result: Array[String] = []
    for other in _neighbors.get(id, []):
        result.append(str(other))
    return result

func edge_points(a: String, b: String) -> PackedVector2Array:
    var key: String = _edge_key(a, b)
    if not _edges.has(key):
        return PackedVector2Array()
    var edge: Dictionary = _edges[key]
    var coords: PackedVector2Array = PackedVector2Array()
    for pair in edge.get("points", []):
        coords.append(_map_image_point(Vector2(float(pair[0]), float(pair[1]))))
    if str(edge.get("a")) != a:
        var backward: PackedVector2Array = PackedVector2Array()
        for i in range(coords.size() - 1, -1, -1):
            backward.append(coords[i])
        return backward
    return coords

func path_length(points: PackedVector2Array) -> float:
    var result: float = 0.0
    for i in range(1, points.size()):
        result += points[i - 1].distance_to(points[i])
    return result

func point_at(points: PackedVector2Array, traveled: float) -> Vector2:
    if points.is_empty():
        return Vector2.ZERO
    var left: float = maxf(0.0, traveled)
    for i in range(1, points.size()):
        var delta: Vector2 = points[i] - points[i - 1]
        var span: float = delta.length()
        if left <= span:
            return points[i - 1] + delta * (left / maxf(span, 0.001))
        left -= span
    return points[-1]

func heading_at(points: PackedVector2Array, traveled: float) -> float:
    if points.size() < 2:
        return 0.0
    var p0: Vector2 = point_at(points, maxf(0.0, traveled - 4.0))
    var p1: Vector2 = point_at(points, traveled + 4.0)
    return (p1 - p0).angle() if p1.distance_to(p0) > 0.3 else 0.0

func image_points_for_edge(a: String, b: String) -> Array:
    if not _edges.has(_edge_key(a, b)):
        return []
    return _edges[_edge_key(a, b)].get("points", [])
