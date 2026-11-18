extends "res://planet_hub/games/electric_impulses/scripts/ElectricImpulses_mika_v2.gd"
## Electric Impulses v2.1: first pattern waits for actual TTS completion,
## automatic rounds with no Next overlay, per-session crystals settled on exit.
## Scoped only to this game, preserving v2 layout, translations and node sounds.

const SESSION_CRYSTAL_CAP: int = 50
const VOICE_START_GRACE: float = 3.0
const VOICE_SAFETY_TIMEOUT: float = 25.0
const AUTO_ROUND_DELAY: float = 0.70
const AUTO_CYCLE_DELAY: float = 1.05

var _intro_voice_pending: bool = false
var _intro_voice_requested: bool = false
var _intro_voice_observed: bool = false
var _intro_voice_elapsed: float = 0.0
var _intro_voice_silent: float = 0.0
var _auto_round_remaining: float = -1.0
var _session_crystals: int = 0
var _crystals_settled: bool = false


func _ready() -> void:
    # super schedules _speak_instruction_once using call_deferred.
    # Explicitly gate the first demo before the deferred call can start it.
    super._ready()
    _session_crystals = 0
    _crystals_settled = false
    _intro_voice_pending = true
    _intro_voice_requested = false
    _intro_voice_observed = false
    _intro_voice_elapsed = 0.0
    _intro_voice_silent = 0.0
    _auto_round_remaining = -1.0
    _phase = "voice_intro"
    _update_crystals()
    queue_redraw()


func _speak_instruction_once() -> void:
    if not _intro_voice_pending or not is_inside_tree():
        return
    _intro_voice_requested = true
    if not bool(ProjectSettings.get_setting("audio/general/text_to_speech", false)):
        _finish_intro_voice()
        return
    var voices: PackedStringArray = DisplayServer.tts_get_voices_for_language(_ui_lang)
    if voices.is_empty():
        # Unsupported voice: do not block children from playing forever.
        _finish_intro_voice()
        return
    DisplayServer.tts_speak(str(INSTRUCTIONS.get(_ui_lang, INSTRUCTIONS["en"])), voices[0], 70, 1.0, 0.95)
    # tts_is_speaking() observes both active speech and queued utterances.
    # Polling avoids replacing the shared DisplayServer utterance callbacks.
    if DisplayServer.tts_is_speaking():
        _intro_voice_observed = true


func _finish_intro_voice() -> void:
    if not _intro_voice_pending:
        return
    _intro_voice_pending = false
    if _phase == "voice_intro":
        _start_demo()


func _process(delta: float) -> void:
    super._process(delta)
    if _intro_voice_pending:
        # The original base only advances demo/intro phases; "voice_intro"
        # keeps the entire first light pattern motionless while speech plays.
        if not _intro_voice_requested:
            return
        _intro_voice_elapsed += delta
        var speaking: bool = DisplayServer.tts_is_speaking()
        if speaking:
            _intro_voice_observed = true
            _intro_voice_silent = 0.0
        else:
            _intro_voice_silent += delta
        if _intro_voice_observed and _intro_voice_silent >= 0.20:
            _finish_intro_voice()
        elif not _intro_voice_observed and _intro_voice_elapsed >= VOICE_START_GRACE:
            _finish_intro_voice()
        elif _intro_voice_elapsed >= VOICE_SAFETY_TIMEOUT:
            _finish_intro_voice()
        return

    if _auto_round_remaining >= 0.0:
        _auto_round_remaining -= delta
        if _auto_round_remaining <= 0.0:
            _auto_round_remaining = -1.0
            if _phase == "level_done" or _phase == "finished":
                super._go_next()
                # Do not show a separate Ready/Next state between rounds.
                _start_demo()


func _tap_node_now(node_id: int) -> void:
    var credit_before: int = _credited_steps
    super._tap_node_now(node_id)
    # Existing logic credits each *new* correct step only once, even when a
    # sequence is replayed after a mistake or with Watch Again.
    var newly_correct: int = maxi(0, _credited_steps - credit_before)
    if newly_correct > 0:
        _session_crystals = mini(SESSION_CRYSTAL_CAP, _session_crystals + newly_correct)
        _update_crystals()
    if _phase == "level_done" and _auto_round_remaining < 0.0:
        _auto_round_remaining = AUTO_ROUND_DELAY
    elif _phase == "finished" and _auto_round_remaining < 0.0:
        _auto_round_remaining = AUTO_CYCLE_DELAY


func _update_crystals() -> void:
    if _crystal_hud == null:
        return
    var count: int = clampi(_session_crystals, 0, SESSION_CRYSTAL_CAP)
    if count != _last_hud_crystals:
        _last_hud_crystals = count
        _crystal_hud.set("crystal_count", count)


func _handle_click(point: Vector2) -> void:
    # No more Next / Again popup or invisible interactive Next rectangle.
    if _phase != "input":
        return
    if REPLAY_RECT.has_point(point):
        _start_demo()
        return
    for node_id in _available_nodes:
        if point.distance_to(NODE_POSITIONS[node_id]) <= 49.0:
            _tap_node_now(node_id)
            return


func _unhandled_key_input(event: InputEvent) -> void:
    if not (event is InputEventKey and event.pressed and not event.echo):
        return
    if event.keycode == KEY_SPACE and _phase == "input":
        _start_demo()
    elif event.keycode >= KEY_1 and event.keycode <= KEY_8 and _phase == "input":
        var slot: int = event.keycode - KEY_1
        if slot < _available_nodes.size():
            _tap_node_now(_available_nodes[slot])
        else:
            return
    else:
        return
    get_viewport().set_input_as_handled()


func _draw_overlay() -> void:
    # Round success is shown in the existing short status text in the arena.
    # No full-screen dialog and no NEXT CIRCUIT button.
    pass


func _find_reward_host() -> Node:
    var ancestor: Node = get_parent()
    for _i in range(25):
        if ancestor == null:
            break
        if ancestor.has_signal("crystals_earned") and ancestor.has_method("_return_to_cards"):
            return ancestor
        ancestor = ancestor.get_parent()
    return null


func _settle_session_crystals() -> void:
    if _crystals_settled:
        return
    var host: Node = _find_reward_host()
    if host == null:
        # Standalone tests have no global fuel receiver; leave them untouched.
        return
    _crystals_settled = true
    if _session_crystals <= 0:
        return
    host.emit_signal("crystals_earned", mini(_session_crystals, SESSION_CRYSTAL_CAP))
    # Same immediate UI refresh as the existing MIKA drawing minigame.
    var parent: Node = host.get_parent()
    for _i in range(8):
        if parent == null:
            break
        var fuel: Variant = parent.get("_fuel_units")
        if fuel is int or fuel is float:
            if host.has_method("set_stats"):
                host.call("set_stats", maxi(0, floori(float(fuel) + 0.001)), 0, 0.0)
            break
        parent = parent.get_parent()


func _exit_to_cards() -> void:
    _settle_session_crystals()
    super._exit_to_cards()


func _exit_tree() -> void:
    _settle_session_crystals()
    super._exit_tree()
