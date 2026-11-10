extends "res://education/playtown/src/features/matching_pairs/mika_matching_pairs_panel_v1.gd"
## MIKA Matching Pairs v2 — 10 new neon doors in a 5x2 grid.
## Reuses v1 native crystal HUD, title, stage, background and original gameplay.

const MIKA_VISUAL_DOOR = preload("res://education/playtown/src/features/matching_pairs/mika_matching_door_visual_v2.gd")
const MIKA_DOOR_ART = preload("res://education/playtown/assets/matching_pairs/mika_neon_double_door_v2.png")


func _layout() -> void:
    super._layout()
    if _mika_header_back == null:
        return
    # The Simulator (MikoMainMenu) already has its own real back button.
    # Keep the local back only when this scene is launched standalone.
    _mika_header_back.visible = _mika_simulator_host() == null


func _mika_simulator_host() -> Node:
    var p: Node = get_parent()
    for _i in range(24):
        if p == null:
            break
        if p.has_method("_return_to_cards"):
            return p
        p = p.get_parent()
    return null


func _start_new_round() -> void:
    # Exactly FIVE pairs, rather than the base game's four pairs.
    # Gameplay/audio/rewards after selection remain inherited unchanged.
    input_locked = true
    first_door = null
    round_number += 1
    for door in doors:
        if is_instance_valid(door):
            door.queue_free()
    doors.clear()
    var available: Array = SYMBOL_POOL.duplicate(true)
    available.shuffle()
    var pairs: Array[Dictionary] = []
    for index in range(5):
        pairs.append(available[index])
        pairs.append(available[index].duplicate())
    pairs.shuffle()
    for symbol in pairs:
        var door: MatchingDoor = MIKA_VISUAL_DOOR.new() as MatchingDoor
        door.configure(symbol["kind"], symbol["color"])
        door.selected.connect(_on_door_selected)
        door.modulate.a = 0.0
        add_child(door)
        doors.append(door)
    _layout_doors(false)
    for index in range(doors.size()):
        var door: MatchingDoor = doors[index]
        var tween: Tween = create_tween()
        tween.tween_interval(float(index) * 0.045)
        tween.tween_property(door, "modulate:a", 1.0, 0.18)
    input_locked = false


func _layout_doors(animated: bool) -> void:
    if doors.is_empty() or _mika_stage == null or _mika_stage_bounds.size.x < 70.0:
        return
    # Keep the same scale when completed pairs disappear, avoiding sudden
    # resizing of the remaining doors. Every initial round shows 5 x 2.
    var padding: float = clampf(minf(_mika_stage_bounds.size.x,
            _mika_stage_bounds.size.y) * 0.034, 11.0, 27.0)
    var inner: Rect2 = _mika_stage_bounds.grow(-padding)
    var horizontal_gap: float = clampf(inner.size.x * 0.013, 8.0, 20.0)
    var vertical_gap: float = clampf(inner.size.y * 0.027, 7.0, 19.0)
    var max_cell_width: float = maxf(10.0, (inner.size.x - horizontal_gap * 4.0) / 5.0)
    var max_cell_height: float = maxf(10.0, (inner.size.y - vertical_gap) / 2.0)
    var image_ratio: float = float(MIKA_DOOR_ART.get_width()) / maxf(1.0, float(MIKA_DOOR_ART.get_height()))
    var door_h: float = minf(max_cell_height, max_cell_width / image_ratio)
    var door_w: float = door_h * image_ratio
    var cols: int = mini(5, doors.size())
    var rows: int = int(ceil(float(doors.size()) / float(cols)))
    var total_h: float = door_h * float(rows) + vertical_gap * float(rows - 1)
    var start_y: float = inner.position.y + (inner.size.y - total_h) * 0.5
    for index in range(doors.size()):
        var row: int = index / cols
        var first_in_row: int = row * cols
        var items_in_row: int = mini(cols, doors.size() - first_in_row)
        var row_w: float = door_w * float(items_in_row) + horizontal_gap * float(items_in_row - 1)
        var column: int = index - first_in_row
        var target: Vector2 = Vector2(
            inner.position.x + (inner.size.x - row_w) * 0.5 + float(column) * (door_w + horizontal_gap),
            start_y + float(row) * (door_h + vertical_gap)
        )
        var current_door: MatchingDoor = doors[index]
        current_door.size = Vector2(door_w, door_h)
        current_door.pivot_offset = current_door.size * 0.5
        if animated:
            var tween: Tween = create_tween()
            tween.tween_property(current_door, "position", target, 0.34).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
        else:
            current_door.position = target
