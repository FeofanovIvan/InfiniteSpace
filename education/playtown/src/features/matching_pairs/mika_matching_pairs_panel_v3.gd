extends "res://education/playtown/src/features/matching_pairs/mika_matching_pairs_panel_v2.gd"
## MIKA Matching Pairs v3: correct single back button and clipped shuttle doors.
## No MikoMainMenu changes: we hide only its existing game-back while this
## Matching Pairs scene lives, then restore it when leaving.

const SHUTTLE_DOOR = preload("res://education/playtown/src/features/matching_pairs/mika_matching_door_shuttle_v3.gd")

var _host_game_back: Button = null
var _host_back_was_visible: bool = false


func _layout() -> void:
    super._layout()
    if _mika_header_back != null:
        # v2 did the opposite; KEEP the back button in our own header.
        _mika_header_back.show()
    _hide_simulator_game_back()


func _hide_simulator_game_back() -> void:
    var host: Node = _mika_simulator_host()
    if host == null:
        return
    # This is MikoMainMenu's game back, NOT our MatchingPairs_HeaderBack.
    var candidate: Variant = host.get("_game_back")
    if candidate is Button:
        var host_button: Button = candidate as Button
        if _host_game_back != host_button:
            _host_game_back = host_button
            _host_back_was_visible = host_button.visible
        host_button.hide()


func _restore_simulator_game_back() -> void:
    if is_instance_valid(_host_game_back):
        _host_game_back.visible = _host_back_was_visible
    _host_game_back = null


func _go_home() -> void:
    var host: Node = _mika_simulator_host()
    if host != null:
        # Navigation must use the simulator's card-return path, not PlayTown HOME.
        _restore_simulator_game_back()
        host.call("_return_to_cards")
        return
    super._go_home()


func _exit_tree() -> void:
    _restore_simulator_game_back()


func _start_new_round() -> void:
    # v2's five-pair gameplay, now using the v3 shuttle-door visual controller.
    # Selection, scoring, audio and matched/failed outcomes remain inherited.
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
        var door: MatchingDoor = SHUTTLE_DOOR.new() as MatchingDoor
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
