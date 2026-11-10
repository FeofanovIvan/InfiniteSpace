extends "res://education/playtown/src/features/matching_pairs/mika_matching_pairs_panel_v3.gd"
## Matching Pairs v3.1: same simulator header, navigation and 5x2 layout as v3.
## Only replace each v3 rectangular-masked door with the exact 8-point door.

const OCTAGON_DOOR = preload("res://education/playtown/src/features/matching_pairs/mika_matching_door_octagon_v3_1.gd")

func _start_new_round() -> void:
    # Five pairs / ten doors; original game selection, sounds and rewards remain.
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
        var door: MatchingDoor = OCTAGON_DOOR.new() as MatchingDoor
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
