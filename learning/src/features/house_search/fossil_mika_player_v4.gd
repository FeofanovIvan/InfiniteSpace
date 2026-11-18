extends "res://learning/src/features/house_search/fossil_mika_player_v3.gd"
## Fossil Hunt v4: centre of Mika's feet must stay in the user-drawn zone.
const CaveZones: Script = preload("res://learning/src/features/house_search/fossil_cave_zones_v4.gd")

var _walk_zones_v4: Dictionary = {}
var _stair_entries_v4: Dictionary = {}

func _ready() -> void:
    super._ready()
    var parsed: Dictionary = CaveZones.load_shapes()
    _walk_zones_v4 = parsed.get("walk", {})
    _stair_entries_v4 = parsed.get("stair", {})
    if not _walk_zones_v4.has("lower") or not _walk_zones_v4.has("upper"):
        push_error("Fossil Hunt: user cave walk areas missing")

func _ladder_solid(source_point: Vector2, floor_name: String) -> bool:
    # Rock/walk polygons are authoritatively from JSON. The ladder is solid on
    # its physical strip but a lane exists on the opposite side for walking.
    if source_point.x < 808.0 or source_point.x > 890.0:
        return false
    if floor_name == "lower":
        return source_point.y < 820.0
    return source_point.y > 497.0

func _is_allowed(point_source: Vector2, polygon: PackedVector2Array, floor_name: String) -> bool:
    return CaveZones.contains(point_source, polygon) and not _ladder_solid(point_source, floor_name)

func _try_step(current_source: Vector2, next_source: Vector2,
        polygon: PackedVector2Array, floor_name: String) -> Vector2:
    if _is_allowed(next_source, polygon, floor_name):
        return next_source
    # Slide along the boundary instead of moving through rocks.
    var along_x: Vector2 = Vector2(next_source.x, current_source.y)
    if _is_allowed(along_x, polygon, floor_name):
        return along_x
    var along_y: Vector2 = Vector2(current_source.x, next_source.y)
    if _is_allowed(along_y, polygon, floor_name):
        return along_y
    # If the original point lies just beyond a border (precision on import),
    # bring it back to the closest playable point without teleporting.
    if not _is_allowed(current_source, polygon, floor_name):
        var edge: Vector2 = CaveZones.nearest_on_polygon(current_source, polygon)
        if not _ladder_solid(edge, floor_name):
            return edge
    return current_source

func _physics_process(delta: float) -> void:
    if not input_enabled:
        velocity = Vector2.ZERO
        return
    var desired: Vector2 = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down") + touch_direction
    if desired.length() > 1.0:
        desired = desired.normalized()
    var floor_name: String = "lower" if fossil_current_floor == 1 else "upper"
    var polygon: PackedVector2Array = _walk_zones_v4.get(floor_name, PackedVector2Array())
    if polygon.size() < 3:
        velocity = Vector2.ZERO
        return
    var world_motion: Vector2 = Vector2(desired.x, desired.y * 0.72) * speed * delta
    var from_world: Vector2 = position
    var step_source: Vector2 = CaveZones.world_to_source(world_motion)
    var steps: int = maxi(1, ceili(step_source.length() / 4.0))
    var current: Vector2 = CaveZones.world_to_source(position)
    for i in range(steps):
        var result: Vector2 = _try_step(current, current + step_source / float(steps), polygon, floor_name)
        var world_result: Vector2 = CaveZones.source_to_world(result)
        if world_result.x >= floor_left and world_result.x <= floor_right:
            current = result
    position = CaveZones.source_to_world(current)
    velocity = (position - from_world) / maxf(delta, 0.0001)
    if desired.length_squared() > 0.015 and velocity.length_squared() > 1.0:
        if absf(desired.x) > absf(desired.y) * 0.65:
            animated_sprite.play(&"walk_right" if desired.x > 0.0 else &"walk_left")
        else:
            animated_sprite.play(&"walk_down" if desired.y > 0.0 else &"walk_up")
    else:
        animated_sprite.pause()
        animated_sprite.frame = 0
    _set_side_mirror()
