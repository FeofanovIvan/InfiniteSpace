extends "res://education/playtown/src/features/matching_pairs/mika_matching_pairs_panel_v3_1.gd"
## MIKA Matching Pairs v3.2 — session-only crystal tally (starts at ZERO)
## and grant-at-most-available-capacity into the Simulator's 50-slot reservoir.
## Does not touch door layout, eight-point aperture, voices, sounds, or navigation.

const SESSION_CAPACITY: int = 50


func _build_ui() -> void:
    super._build_ui()
    # Each newly instantiated game is a new session. Do NOT clear persistent
    # GameState coins or MikoMainMenu's ship inventory.
    score = 0
    GameState.last_score = 0
    if _mika_crystal_hud != null:
        _mika_crystal_hud.set("crystal_count", 0)


func _mika_on_coin_balance_changed(_balance: int) -> void:
    # The original HUD displayed GameState's lifetime balance. Ignore that
    # accumulated value: the in-game badge is the CURRENT SESSION only.
    if _mika_crystal_hud != null:
        _mika_crystal_hud.set("crystal_count", score)


func _mika_award_one_crystal() -> void:
    if not is_inside_tree():
        return
    var host: Node = _mika_simulator_host()
    var remaining: int = SESSION_CAPACITY - score
    if host != null:
        if host.get("_playing") is bool and not bool(host.get("_playing")):
            return
        # Main menu bridges GameState coin changes to crystals_earned and owns
        # the authoritative in-flight 0..50 crystal reservoir. The single coin
        # change below triggers exactly ONE bridge event on the same session.
        var balance: Variant = host.get("_crystal_balance")
        if balance is int or balance is float:
            remaining = mini(remaining, SESSION_CAPACITY - clampi(int(balance), 0, SESSION_CAPACITY))
        else:
            # Unknown host state must never authorize an unbounded reward.
            return
    else:
        # Standalone play has no ship reservoir. Never grow legacy stored coins
        # beyond 50 there either; still permit continued play with zero rewards.
        remaining = mini(remaining, SESSION_CAPACITY - maxi(0, GameState.get_coin_balance()))
    if remaining <= 0:
        return
    score += 1
    GameState.last_score = score
    # Coin balance change fires synchronously; the simulator adds only this 1
    # to its ship reservoir, and the session badge keeps its own count.
    GameState.add_coins(1)
    _mika_on_coin_balance_changed(0)


func _on_door_selected(door: MatchingDoor) -> void:
    # The original game's matching flow is retained, with exactly one guarded
    # change at the point where it used to call GameState.add_coins(1).
    if input_locked or door.revealed or door.matched:
        return
    input_locked = true
    door_open_player.stop()
    door_open_player.play()
    await door.set_revealed(true)
    if not is_inside_tree():
        return
    if first_door == null:
        first_door = door
        input_locked = false
        return
    var second_door := door
    if _symbols_match(first_door, second_door):
        correct_player.play()
        _play_shape_voice(first_door.symbol_kind)
        SFX.play_praise(get_viewport_rect().size * 0.5, 1.0)
        _mika_award_one_crystal()
        await get_tree().create_timer(0.28).timeout
        if not is_inside_tree():
            return
        var matched_first := first_door
        first_door = null
        matched_first.play_match_animation()
        second_door.play_match_animation()
        await get_tree().create_timer(0.42).timeout
        if not is_inside_tree():
            return
        doors.erase(matched_first)
        doors.erase(second_door)
        matched_first.queue_free()
        second_door.queue_free()
        if doors.is_empty():
            await get_tree().create_timer(0.9).timeout
            if is_inside_tree():
                _start_new_round()
            return
        _layout_doors(true)
        input_locked = false
    else:
        wrong_player.play()
        SFX.play_retry(get_viewport_rect().size * 0.5)
        await get_tree().create_timer(0.7).timeout
        if not is_inside_tree():
            return
        var previous := first_door
        first_door = null
        door_close_player.stop()
        door_close_player.play()
        await previous.set_revealed(false)
        if not is_inside_tree():
            return
        await second_door.set_revealed(false)
        if is_inside_tree():
            input_locked = false
