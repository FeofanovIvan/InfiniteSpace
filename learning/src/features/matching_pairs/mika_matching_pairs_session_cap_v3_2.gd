extends "res://learning/src/features/matching_pairs/mika_matching_pairs_panel_v3_1.gd"
## MIKA Matching Pairs v3.2 — session-only crystal tally (starts at ZERO)
## and grant-at-most-available-capacity into the Simulator's 50-slot reservoir.
## Does not touch door layout, eight-point aperture, voices, sounds, or navigation.

const SESSION_CAPACITY: int = 50
const ACTION_FEEDBACK_SCRIPT: Script = preload("res://planet_hub/games/shared/ActionFeedbackVoice.gd")

var _m33_action_voice: Variant = null
var _m33_wrong_streak: int = 0


func _build_ui() -> void:
    super._build_ui()
    _m33_action_voice = ACTION_FEEDBACK_SCRIPT.new()
    _m33_action_voice.name = "MatchingPairsActionFeedback"
    add_child(_m33_action_voice)
    _m33_action_voice.prime_locale(_m33_locale())
    # Each newly instantiated game is a new session. Do NOT clear persistent
    # GameState coins or MikoMainMenu's ship inventory.
    score = 0
    GameState.last_score = 0
    if _mika_crystal_hud != null:
        _mika_crystal_hud.set("crystal_count", 0)


func _m33_locale() -> String:
    var language: String = str(LanguageService.learning_locale)
    var code: String = language.to_lower().get_slice("_", 0).get_slice("-", 0)
    return code if code in ["ru", "en", "pt", "es", "fr", "de"] else "en"


func _start_new_round() -> void:
    _m33_wrong_streak = 0
    super._start_new_round()


func _exit_tree() -> void:
    if _m33_action_voice != null:
        _m33_action_voice.stop_feedback()
    super._exit_tree()


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
        _m33_wrong_streak = 0
        correct_player.play()
        # Five pairs per round: retain each shape's educational voice. On the
        # final pair, an immediate phrase may replace the final shape name.
        var praised: bool = false
        if doors.size() == 2 and _m33_action_voice != null and not voice_player.playing:
            praised = _m33_action_voice.praise(_m33_locale())
        if not praised:
            _play_shape_voice(first_door.symbol_kind)
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
        _m33_wrong_streak += 1
        if _m33_wrong_streak >= 2:
            _m33_wrong_streak = 0
            if _m33_action_voice != null and not voice_player.playing:
                _m33_action_voice.encourage(_m33_locale())
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
