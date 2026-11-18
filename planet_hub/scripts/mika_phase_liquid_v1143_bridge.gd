extends Node
## v114.3: phase-only live liquid in dialogue. Card preview remains PNG.
## Runs regardless of the presence of the previous optional v113 bridge.

const PHASE_IDS: Array[String] = ["smc_p01", "smc_p02", "smc_p03", "smc_p05", "st_smc"]
const LIVE_SCENE: PackedScene = preload("res://phase_liquid_v4/PhaseLiquid3D.tscn")

var _dialog: Control = null
var _active: Control = null
var _character: Control = null
var _portrait: CanvasItem = null
var _voice: Node = null

func _ready() -> void:
    process_mode = Node.PROCESS_MODE_ALWAYS
    _dialog = get_parent() as Control
    _voice = get_node_or_null("/root/MikaVoice")
    if _voice != null:
        if _voice.has_signal("speech_started"):
            _voice.connect("speech_started", Callable(self, "_speech_started"))
        if _voice.has_signal("speech_completed"):
            _voice.connect("speech_completed", Callable(self, "_speech_completed"))
        if _voice.has_signal("speech_stopped"):
            _voice.connect("speech_stopped", Callable(self, "_speech_stopped"))
    set_process(true)
    call_deferred("sync_now")

func _process(_delta: float) -> void:
    sync_now()

func sync_now() -> void:
    if not is_instance_valid(_dialog):
        return
    var place: String = str(_dialog.get("_current_planet_id"))
    var should_show: bool = PHASE_IDS.has(place) and _dialog.is_visible_in_tree()
    if should_show:
        if _active == null or not is_instance_valid(_active):
            _show_phase()
    elif _active != null:
        _hide_phase()

func _show_phase() -> void:
    if not is_instance_valid(_dialog):
        return
    _character = _dialog.get_node_or_null("RepresentativeCharacter") as Control
    if _character == null:
        push_warning("MIKA v114.3: RepresentativeCharacter not found, liquid preview remains")
        return
    var phase_node: Node = LIVE_SCENE.instantiate()
    var phase: Control = phase_node as Control
    if phase == null:
        phase_node.queue_free()
        push_warning("MIKA v114.3: PhaseLiquid3D is not a Control, liquid preview remains")
        return
    _portrait = _character.find_child("ReplaceableRepresentativeArt", true, false) as CanvasItem
    phase.name = "LivePhaseLiquidOnlyWhileTalking"
    phase.process_mode = Node.PROCESS_MODE_ALWAYS
    phase.mouse_filter = Control.MOUSE_FILTER_IGNORE
    phase.set("high_quality", false)
    _character.add_child(phase)
    # The source model sets STOP in its own _ready; keep dialog touches available.
    phase.mouse_filter = Control.MOUSE_FILTER_IGNORE
    phase.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    phase.move_to_front()
    _active = phase
    if _portrait != null:
        _portrait.visible = false
    if _voice != null and _voice.has_method("is_reading") and bool(_voice.call("is_reading")):
        _active.call("set_speech_state", "talk_soft")
    print("MIKA v114.3: phase liquid animation shown for ", str(_dialog.get("_current_planet_id")))

func _hide_phase() -> void:
    if _active != null and is_instance_valid(_active):
        if _active.has_method("stop_talking"):
            _active.call("stop_talking")
        _active.queue_free()
    _active = null
    if is_instance_valid(_portrait):
        _portrait.visible = true
    _portrait = null
    _character = null

func _speech_started(text: String, _role: String) -> void:
    if _active == null or not is_instance_valid(_active):
        return
    var seconds: float = clampf(float(text.length()) * 0.075, 0.6, 12.0)
    _active.call("speak_for", seconds, 0.72)

func _speech_completed(_text: String, _role: String) -> void:
    if _active != null and is_instance_valid(_active):
        _active.call("stop_talking")

func _speech_stopped() -> void:
    if _active != null and is_instance_valid(_active):
        _active.call("stop_talking")

func _exit_tree() -> void:
    _hide_phase()
