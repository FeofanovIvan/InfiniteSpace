extends RefCounted
## Fossil Hunt v4: user-drawn source-image polygons; source coordinates 1683x935.
## Everything (background, player, items, ladder) shares the same world transform.

const DATA: String = "res://learning/src/features/house_search/fossil_cave_zones_v4.json"
const ART_SIZE: Vector2 = Vector2(1683.0, 935.0)
const GAME_SIZE: Vector2 = Vector2(1536.0, 864.0)

static func source_to_world(point: Vector2) -> Vector2:
    return point * (GAME_SIZE / ART_SIZE)

static func world_to_source(point: Vector2) -> Vector2:
    return point * (ART_SIZE / GAME_SIZE)

static func load_shapes() -> Dictionary:
    var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(DATA))
    var polygons: Dictionary = {}
    var entrances: Dictionary = {"lower": PackedVector2Array(), "upper": PackedVector2Array()}
    if not (parsed is Dictionary):
        push_error("Fossil cave v4: invalid user navigation JSON")
        return {"walk": polygons, "stair": entrances}
    var shapes: Array = parsed.get("shapes", [])
    for shape_value in shapes:
        if not (shape_value is Dictionary):
            continue
        var shape: Dictionary = shape_value
        var floor_name: String = str(shape.get("floor", ""))
        var kind: String = str(shape.get("kind", ""))
        if floor_name != "upper" and floor_name != "lower":
            continue
        var vertices: PackedVector2Array = PackedVector2Array()
        for raw_point in shape.get("points_px", []):
            if raw_point is Array and raw_point.size() >= 2:
                vertices.append(Vector2(float(raw_point[0]), float(raw_point[1])))
        if kind == "walk" and vertices.size() >= 3:
            polygons[floor_name] = vertices
        elif kind == "stair_entry" and vertices.size() >= 1:
            var list: PackedVector2Array = entrances[floor_name]
            list.append(vertices[0])
            entrances[floor_name] = list
    return {"walk": polygons, "stair": entrances}

static func contains(point: Vector2, polygon: PackedVector2Array) -> bool:
    if polygon.size() < 3:
        return false
    # Boundary points are also playable.
    for i in range(polygon.size()):
        var a: Vector2 = polygon[i]
        var b: Vector2 = polygon[(i + 1) % polygon.size()]
        if Geometry2D.get_closest_point_to_segment(point, a, b).distance_squared_to(point) < 0.16:
            return true
    return Geometry2D.is_point_in_polygon(point, polygon)

static func nearest_on_polygon(point: Vector2, polygon: PackedVector2Array) -> Vector2:
    if polygon.is_empty():
        return point
    if contains(point, polygon):
        return point
    var result: Vector2 = polygon[0]
    var distance: float = INF
    for i in range(polygon.size()):
        var next: Vector2 = Geometry2D.get_closest_point_to_segment(
                point, polygon[i], polygon[(i + 1) % polygon.size()])
        var squared: float = next.distance_squared_to(point)
        if squared < distance:
            result = next
            distance = squared
    return result

static func distance_to_walk(point: Vector2, polygon: PackedVector2Array) -> float:
    return point.distance_to(nearest_on_polygon(point, polygon))

static func nearest_ladder(point_world: Vector2, floor_name: String, entrance_map: Dictionary) -> Vector2:
    var points: PackedVector2Array = entrance_map.get(floor_name, PackedVector2Array())
    var position: Vector2 = world_to_source(point_world)
    var chosen: Vector2 = Vector2(845.0, 499.0) if floor_name == "upper" else Vector2(854.0, 792.0)
    var distance: float = INF
    for other in points:
        var d: float = position.distance_squared_to(other)
        if d < distance:
            distance = d
            chosen = other
    return source_to_world(chosen)
