extends "res://planet_hub/games/electric_impulses/scripts/ElectricImpulses.gd"
## MIKA Electric Impulses v2. One safe-area stage, shared mini-game header,
## original sequence gameplay and eight sound cues, one spoken instruction.
## Inherits the existing game; neither its logic nor its assets are overwritten.

const TOOLBAR: Script = preload("res://simulator_ui/scripts/mika_shared_tracing_toolbar_v2.gd")
const HUD: Script = preload("res://planet_hub/scripts/bottom_hud.gd")
const GLYPH: Script = preload("res://simulator_ui/back_arrow_glyph.gd")
const KIT: Script = preload("res://simulator_ui/scripts/mika_minigame_ui_kit_v11.gd")

const INSTRUCTIONS: Dictionary = {
    "ru": "Запомни, как загораются узлы, и повтори последовательность.",
    "en": "Watch the glowing nodes, then repeat the same pattern.",
    "pt": "Observe os pontos iluminados e repita a sequência.",
    "es": "Observa los nodos iluminados y repite la secuencia.",
    "de": "Merke dir die leuchtenden Knoten und wiederhole die Reihenfolge.",
    "fr": "Observe les nœuds lumineux, puis reproduis la séquence."
}

const DESIGN_STAGE := Rect2(25.0, 116.0, 1230.0, 472.0)

var _back_button: Button
var _host_back: Control
var _title_panel: Panel
var _title_label: Label
var _instruction_label: Label
var _crystal_hud: Control
var _stage_rect := Rect2()
var _cosmos_style: StyleBoxFlat
var _arena_scale: float = 1.0
var _arena_origin := Vector2.ZERO
var _last_hud_crystals: int = -1


func _ready() -> void:
    super._ready()
    _cosmos_style = KIT.stage_style()
    _cosmos_style.bg_color = Color(0.0015, 0.0030, 0.0090, 0.98)
    _create_mika_header()
    _update_header_words()
    _find_host_back()
    resized.connect(_relayout)
    get_viewport().size_changed.connect(_relayout)
    _relayout()
    call_deferred("_relayout")
    call_deferred("_speak_instruction_once")


func _create_mika_header() -> void:
    _title_panel = Panel.new()
    _title_panel.name = "ElectricImpulsesUnifiedTitlePanel"
    _title_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
    TOOLBAR.apply_title_style(_title_panel)
    add_child(_title_panel)

    _title_label = Label.new()
    _title_label.name = "ElectricImpulsesTitle"
    _title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    _title_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
    _title_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
    _title_label.clip_text = true
    _title_panel.add_child(_title_label)

    _instruction_label = Label.new()
    _instruction_label.name = "ElectricImpulsesSpokenInstruction"
    _instruction_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    _instruction_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
    _instruction_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
    _instruction_label.clip_text = true
    _title_panel.add_child(_instruction_label)

    _back_button = Button.new()
    _back_button.name = "ElectricImpulsesUnifiedBack"
    _back_button.focus_mode = Control.FOCUS_NONE
    _back_button.text = ""
    _back_button.add_theme_stylebox_override("normal", KIT.button_style(false))
    _back_button.add_theme_stylebox_override("hover", KIT.button_style(true))
    _back_button.add_theme_stylebox_override("pressed", KIT.button_style(true))
    _back_button.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
    _back_button.pressed.connect(_exit_to_cards)
    add_child(_back_button)
    var glyph: Control = GLYPH.new() as Control
    glyph.mouse_filter = Control.MOUSE_FILTER_IGNORE
    _back_button.add_child(glyph)
    glyph.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

    _crystal_hud = HUD.new() as Control
    _crystal_hud.name = "ElectricImpulsesUnifiedCrystalCounter"
    _crystal_hud.size = Vector2(1680.0, 158.0)
    add_child(_crystal_hud)
    for node_name in ["SimulatorButton", "LaunchButton"]:
        var action: Control = _crystal_hud.get_node_or_null(node_name) as Control
        if action != null:
            action.hide()
    _update_crystals()


func _update_header_words() -> void:
    if _title_label == null:
        return
    _title_label.text = _text("title")
    _instruction_label.text = str(INSTRUCTIONS.get(_ui_lang, INSTRUCTIONS["en"]))
    queue_redraw()


func _on_language_changed(locale: String) -> void:
    super._on_language_changed(locale)
    _update_header_words()


func _speak_instruction_once() -> void:
    # Initial announcement only. Existing node tones remain unchanged.
    if not is_inside_tree() or not bool(ProjectSettings.get_setting("audio/general/text_to_speech", false)):
        return
    var voices: PackedStringArray = DisplayServer.tts_get_voices_for_language(_ui_lang)
    if voices.is_empty():
        return
    DisplayServer.tts_speak(str(INSTRUCTIONS.get(_ui_lang, INSTRUCTIONS["en"])), voices[0], 70, 1.0, 0.95)


func _safe_area(view: Vector2) -> Rect2:
    if OS.get_name() not in ["iOS", "Android"]:
        return Rect2(Vector2.ZERO, view)
    var window: Vector2 = Vector2(DisplayServer.window_get_size())
    var native_safe: Rect2i = DisplayServer.get_display_safe_area()
    if window.x <= 0.0 or window.y <= 0.0 or native_safe.size.x <= 0 or native_safe.size.y <= 0:
        return Rect2(Vector2.ZERO, view)
    var scale: Vector2 = view / window
    var safe: Rect2 = Rect2(Vector2(native_safe.position) * scale, Vector2(native_safe.size) * scale)
    return safe.intersection(Rect2(Vector2.ZERO, view))


func _relayout() -> void:
    if _title_panel == null or size.x < 260.0 or size.y < 160.0:
        return
    var safe: Rect2 = _safe_area(size)
    var header_bottom: float = TOOLBAR.relayout(size, safe, _back_button, _crystal_hud, _title_panel, _title_label, _instruction_label)
    var margin: float = clampf(safe.size.x * 0.013, 7.0, 20.0)
    var top: float = header_bottom + clampf(safe.size.y * 0.010, 5.0, 13.0)
    _stage_rect = Rect2(
        Vector2(safe.position.x + margin, top),
        Vector2(maxf(1.0, safe.size.x - margin * 2.0), maxf(1.0, safe.end.y - top - margin))
    )
    var inner: Rect2 = _stage_rect.grow(-clampf(minf(_stage_rect.size.x, _stage_rect.size.y) * 0.022, 8.0, 18.0))
    _arena_scale = minf(inner.size.x / DESIGN_STAGE.size.x, inner.size.y / DESIGN_STAGE.size.y)
    _arena_origin = inner.get_center() - DESIGN_STAGE.get_center() * _arena_scale
    queue_redraw()


func _on_viewport_resized() -> void:
    _relayout()


func _view_point(pointer: Vector2) -> Vector2:
    if _arena_scale <= 0.0:
        return Vector2(-999.0, -999.0)
    return (pointer - _arena_origin) / _arena_scale


func _gui_input(event: InputEvent) -> void:
    if event is InputEventScreenTouch and event.pressed:
        if _stage_rect.has_point(event.position):
            _handle_click(_view_point(event.position))
            accept_event()
    elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
        if _stage_rect.has_point(event.position):
            _handle_click(_view_point(event.position))
            accept_event()


func _handle_click(point: Vector2) -> void:
    # All legacy score/sound/reset/language/footer hit targets are deliberately removed.
    if _phase == "level_done" or _phase == "finished":
        if NEXT_RECT.has_point(point):
            _go_next()
        return
    if _phase == "input" and REPLAY_RECT.has_point(point):
        _start_demo()
        return
    if _phase != "input":
        return
    for node_id in _available_nodes:
        if point.distance_to(NODE_POSITIONS[node_id]) <= 49.0:
            _tap_node_now(node_id)
            return


func _unhandled_key_input(event: InputEvent) -> void:
    # No hidden R=Reset or M=On/Off shortcuts for removed controls.
    if not (event is InputEventKey and event.pressed and not event.echo):
        return
    if event.keycode == KEY_SPACE:
        if _phase == "input":
            _start_demo()
        elif _phase == "level_done" or _phase == "finished":
            _go_next()
    elif event.keycode >= KEY_1 and event.keycode <= KEY_8:
        var slot: int = event.keycode - KEY_1
        if slot < _available_nodes.size():
            _tap_node_now(_available_nodes[slot])
    else:
        return
    get_viewport().set_input_as_handled()


func _process(delta: float) -> void:
    super._process(delta)
    _update_crystals()


func _update_crystals() -> void:
    if _crystal_hud == null:
        return
    var count: int = clampi(_score, 0, 50)
    if count != _last_hud_crystals:
        _last_hud_crystals = count
        _crystal_hud.set("crystal_count", count)


func _draw() -> void:
    draw_rect(Rect2(Vector2.ZERO, size), Color(0.0015, 0.0030, 0.0090, 1.0), true)
    if _stage_rect.size.x < 2.0 or _stage_rect.size.y < 2.0:
        return
    # One large safe-area stage. No blue translucent film, no lower panel.
    draw_style_box(_cosmos_style, _stage_rect)
    draw_set_transform(_arena_origin, 0.0, Vector2.ONE * _arena_scale)
    _draw_game_field()
    if _phase == "level_done" or _phase == "finished":
        _draw_overlay()
    draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


func _draw_game_field() -> void:
    # Existing original circuit, central core, playable nodes, and level logic.
    _draw_space()
    _draw_circuit()
    _draw_central_core()
    for node_id in _available_nodes:
        _draw_node(node_id)
    var prompt: String = _text("repeat") if _phase == "input" else _text("watch")
    if _phase == "intro":
        prompt = _text("ready")
    elif _phase == "wrong":
        prompt = _text("mistake")
    elif _phase == "level_done":
        prompt = _text("success")
    elif _phase == "finished":
        prompt = _text("completed")
    _label(prompt, Vector2(54, 166), 19, GOLD if _phase == "demo" else AQUA, 760.0)
    if _phase == "input":
        _draw_button(REPLAY_RECT, _text("replay"), CYAN)
    else:
        # Keep the position stable but don't introduce extra controls.
        _center_label(_text("demo") if _phase == "demo" else "", REPLAY_RECT.get_center().x, 166, 16, MUTED, 225.0)
    _draw_sequence_meter()


func _draw_space() -> void:
    # Dark real-space backdrop, with faint nebulae entirely behind the nodes.
    # No translucent blue rectangular layer over the gameplay.
    for layer in range(17, 0, -1):
        var radius: float = 33.0 + float(layer) * 7.3
        draw_circle(Vector2(295, 333), radius, Color(0.24, 0.20, 0.54, 0.0055))
    for layer in range(16, 0, -1):
        var radius: float = 23.0 + float(layer) * 6.6
        draw_circle(Vector2(1030, 366), radius, Color(0.11, 0.40, 0.49, 0.0050))
    for i in range(_stars.size()):
        var star: Vector2 = _stars[i]
        var alpha: float = 0.19 + 0.13 * (1.0 + sin(_clock * 0.6 + float(i) * 1.2)) * 0.5
        draw_circle(star, 0.8 + float(i % 3) * 0.4, Color(0.82, 0.92, 1.0, alpha))


func _draw_overlay() -> void:
    # Progress stays playable; only the completion dialog and essential Next button.
    _round_box(Rect2(27, 117, 1226, 470), Color(0.02, 0.04, 0.10, 0.77), Color.TRANSPARENT, 26)
    _round_box(Rect2(410, 206, 460, 290), Color("10273d"), Color("6bd4e9"), 30, 3)
    for i in range(8):
        var angle: float = float(i) * TAU / 8.0 + _clock * 0.12
        var p: Vector2 = Vector2(640, 262) + Vector2(cos(angle), sin(angle)) * 45.0
        draw_circle(p, 3.8, AQUA if i % 2 == 0 else GOLD)
    draw_circle(Vector2(640, 262), 26, Color("246782"))
    draw_arc(Vector2(640, 262), 26.0, 0.0, TAU, 48, AQUA, 2.5)
    _center_label("✓", 640.0, 275.0, 38, TEXT, 60)
    _center_label(_text("success") if _phase == "level_done" else _text("completed"), 640.0, 352.0, 23, TEXT, 418)
    _draw_button(NEXT_RECT, _text("next") if _phase == "level_done" else _text("again"), AQUA)


func _find_host_back() -> void:
    var ancestor: Node = get_parent()
    while ancestor != null:
        for name in ["ReturnToEducationalCards", "ReturnToExistingPlanetCards"]:
            var host: Control = ancestor.get_node_or_null(name) as Control
            if host != null:
                _host_back = host
                _host_back.hide()
                return
        ancestor = ancestor.get_parent()


func _exit_to_cards() -> void:
    if is_instance_valid(_host_back):
        _host_back.show()
    var portal: Node = get_node_or_null("/root/PlayTownPortal")
    if portal != null and bool(portal.get("active")):
        portal.call("handle_scene_transition", "res://")
        return
    get_tree().change_scene_to_file("res://education/playtown/scenes/screens/game_select_playground.tscn")


func _exit_tree() -> void:
    if is_instance_valid(_host_back):
        _host_back.show()
