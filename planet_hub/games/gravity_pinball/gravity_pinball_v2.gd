extends Control
## MIKA Gravity Pinball v2 — actual Andromeda planet textures and original
## flight joysticks. Spring power at left; aiming at right. No background music.
## This new script intentionally leaves gravity_pinball.gd untouched.

const TOOLBAR: Script = preload("res://simulator_ui/scripts/mika_shared_tracing_toolbar_v2.gd")
const HUD: Script = preload("res://planet_hub/scripts/bottom_hud.gd")
const GLYPH: Script = preload("res://simulator_ui/back_arrow_glyph.gd")
const KIT: Script = preload("res://simulator_ui/scripts/mika_minigame_ui_kit_v11.gd")
const FLIGHT_JOYSTICK: Script = preload("res://scripts/Joystick.gd")
const ARENA: Script = preload("res://planet_hub/games/gravity_pinball/gravity_pinball_arena_v2.gd")

const WORDS: Dictionary = {
    "ru": {"title":"ГРАВИТАЦИОННЫЙ ПИНБОЛ", "sub":"Тяни левую пружину вниз и направляй стрелку справа"},
    "en": {"title":"GRAVITY PINBALL", "sub":"Pull the left spring down; aim with the right stick"},
    "pt": {"title":"PINBALL GRAVITACIONAL", "sub":"Puxe a mola à esquerda; mire com o controle direito"},
    "es": {"title":"PINBALL GRAVITACIONAL", "sub":"Tira del muelle izquierdo y apunta con el control derecho"},
    "fr": {"title":"FLIPPER GRAVITATIONNEL", "sub":"Tire le ressort à gauche et vise à droite"},
    "de": {"title":"GRAVITATIONS-PINBALL", "sub":"Ziehe links die Feder, ziele rechts mit dem Stick"}
}

var _stage: Panel
var _arena: Control
var _back: Button
var _host_back: Control
var _title_panel: Panel
var _title: Label
var _subtitle: Label
var _crystals: Control
var _left_stick: Control
var _right_stick: Control
var _left_caption: Label
var _right_caption: Label
var _locale: String = "en"


func _ready() -> void:
    mouse_filter = Control.MOUSE_FILTER_PASS
    _stage = Panel.new()
    _stage.name = "GravityPinballRoundedStage"
    _stage.mouse_filter = Control.MOUSE_FILTER_PASS
    _stage.clip_contents = true
    _stage.add_theme_stylebox_override("panel", KIT.stage_style())
    add_child(_stage)

    _arena = ARENA.new() as Control
    _arena.name = "GravityPinballOrbitalArena"
    _arena.mouse_filter = Control.MOUSE_FILTER_IGNORE
    _stage.add_child(_arena)
    _arena.connect("crystals_changed", _on_crystals_changed)

    _left_stick = FLIGHT_JOYSTICK.new() as Control
    _left_stick.name = "OriginalFlightJoystickPower"
    _stage.add_child(_left_stick)
    _left_stick.connect("direction_changed", Callable(_arena, "set_power_input"))

    _right_stick = FLIGHT_JOYSTICK.new() as Control
    _right_stick.name = "OriginalFlightJoystickDirection"
    _stage.add_child(_right_stick)
    _right_stick.connect("direction_changed", Callable(_arena, "set_aim_input"))

    _left_caption = _create_caption(_stage, "POWER")
    _right_caption = _create_caption(_stage, "AIM")

    _title_panel = Panel.new()
    _title_panel.name = "NativePinballTitle"
    _title_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
    TOOLBAR.apply_title_style(_title_panel)
    add_child(_title_panel)
    _title = Label.new()
    _title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    _title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
    _title.mouse_filter = Control.MOUSE_FILTER_IGNORE
    _title.clip_text = true
    _title_panel.add_child(_title)
    _subtitle = Label.new()
    _subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    _subtitle.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
    _subtitle.mouse_filter = Control.MOUSE_FILTER_IGNORE
    _subtitle.clip_text = true
    _title_panel.add_child(_subtitle)

    _back = Button.new()
    _back.name = "PinballNativeBack"
    _back.focus_mode = Control.FOCUS_NONE
    _back.add_theme_stylebox_override("normal", KIT.button_style(false))
    _back.add_theme_stylebox_override("hover", KIT.button_style(true))
    _back.add_theme_stylebox_override("pressed", KIT.button_style(true))
    _back.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
    _back.pressed.connect(_exit_to_cards)
    add_child(_back)
    var back_glyph: Control = GLYPH.new() as Control
    _back.add_child(back_glyph)
    back_glyph.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    back_glyph.mouse_filter = Control.MOUSE_FILTER_IGNORE

    _crystals = HUD.new() as Control
    _crystals.name = "NativePinballCrystalCounter"
    _crystals.size = Vector2(1680.0, 158.0)
    add_child(_crystals)
    for node_name in ["SimulatorButton", "LaunchButton"]:
        var action: Control = _crystals.get_node_or_null(node_name) as Control
        if action != null:
            action.hide()
    _crystals.set("crystal_count", 0)

    _read_locale()
    var mobile: Node = get_node_or_null("/root/MobileLocale")
    if mobile != null and mobile.has_signal("language_changed"):
        mobile.connect("language_changed", _on_locale)
    var language_service: Node = get_node_or_null("/root/LanguageService")
    if language_service != null and language_service.has_signal("language_changed"):
        language_service.connect("language_changed", _on_locale)
    _translate()
    _find_host_back()
    resized.connect(_relayout)
    get_viewport().size_changed.connect(_relayout)
    _relayout()
    call_deferred("_relayout")


func _create_caption(parent: Control, content: String) -> Label:
    var label := Label.new()
    label.text = content
    label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
    label.mouse_filter = Control.MOUSE_FILTER_IGNORE
    label.add_theme_color_override("font_color", Color("d6f5ff"))
    label.add_theme_color_override("font_outline_color", Color("0b2342"))
    label.add_theme_constant_override("outline_size", 4)
    parent.add_child(label)
    return label


func _read_locale() -> void:
    var mobile: Node = get_node_or_null("/root/MobileLocale")
    var service: Node = get_node_or_null("/root/LanguageService")
    var chosen: String = "en"
    if mobile != null:
        chosen = str(mobile.get("language"))
    elif service != null:
        chosen = str(service.get("interface_locale"))
    chosen = chosen.to_lower().get_slice("_", 0).get_slice("-", 0)
    _locale = chosen if WORDS.has(chosen) else "en"


func _on_locale(_value: String) -> void:
    _read_locale()
    _translate()
    _relayout()


func _translate() -> void:
    var words: Dictionary = WORDS.get(_locale, WORDS["en"])
    _title.text = str(words["title"])
    _subtitle.text = str(words["sub"])
    var names: Dictionary = {
        "ru": ["СИЛА", "ПРИЦЕЛ"], "en": ["POWER", "AIM"],
        "pt": ["FORÇA", "DIREÇÃO"], "es": ["FUERZA", "DIRECCIÓN"],
        "fr": ["PUISSANCE", "DIRECTION"], "de": ["KRAFT", "RICHTUNG"]
    }
    var pair: Array = names.get(_locale, names["en"])
    _left_caption.text = str(pair[0])
    _right_caption.text = str(pair[1])
    if _arena != null:
        _arena.set("locale", _locale)


func _on_crystals_changed(count: int) -> void:
    if is_instance_valid(_crystals):
        _crystals.set("crystal_count", count)


func _safe_area(view: Vector2) -> Rect2:
    if OS.get_name() not in ["iOS", "Android"]:
        return Rect2(Vector2.ZERO, view)
    var window: Vector2 = Vector2(DisplayServer.window_get_size())
    var native_safe: Rect2i = DisplayServer.get_display_safe_area()
    if window.x <= 0.0 or window.y <= 0.0 or native_safe.size.x <= 0 or native_safe.size.y <= 0:
        return Rect2(Vector2.ZERO, view)
    return Rect2(Vector2(native_safe.position) * (view / window), Vector2(native_safe.size) * (view / window))


func _relayout() -> void:
    if _stage == null or size.x < 280.0 or size.y < 180.0:
        return
    var safe: Rect2 = _safe_area(size)
    var below_header: float = TOOLBAR.relayout(size, safe, _back, _crystals, _title_panel, _title, _subtitle)
    var edge: float = clampf(safe.size.x * 0.012, 6.0, 22.0)
    var top: float = below_header + clampf(safe.size.y * 0.012, 5.0, 12.0)
    _stage.position = Vector2(safe.position.x + edge, top)
    _stage.size = Vector2(maxf(220.0, safe.size.x - edge * 2.0), maxf(90.0, safe.end.y - top - edge))
    var inset: float = clampf(minf(_stage.size.x, _stage.size.y) * 0.020, 7.0, 15.0)
    _arena.position = Vector2.ONE * inset
    _arena.size = _stage.size - Vector2.ONE * (inset * 2.0)
    var joystick_scale: float = clampf(minf(_stage.size.y / 690.0, _stage.size.x / 1250.0), 0.42, 0.93)
    var knob_side: float = 184.0 * joystick_scale
    _left_stick.scale = Vector2.ONE * joystick_scale
    _right_stick.scale = Vector2.ONE * joystick_scale
    _left_stick.position = Vector2(inset + 8.0, _stage.size.y - knob_side - inset - 9.0)
    _right_stick.position = Vector2(_stage.size.x - knob_side - inset - 8.0, _stage.size.y - knob_side - inset - 9.0)
    var font_px: int = maxi(11, roundi(17.0 * joystick_scale))
    for pair in [[_left_caption, _left_stick], [_right_caption, _right_stick]]:
        var label: Label = pair[0] as Label
        var stick: Control = pair[1] as Control
        label.position = stick.position + Vector2(0.0, -24.0 * joystick_scale)
        label.size = Vector2(knob_side, maxf(15.0, 24.0 * joystick_scale))
        label.add_theme_font_size_override("font_size", font_px)
    _arena.call("set_control_clearance", knob_side + 26.0)
    _arena.queue_redraw()


func _find_host_back() -> void:
    var ancestor: Node = get_parent()
    while ancestor != null:
        for identifier in ["ReturnToEducationalCards", "ReturnToExistingPlanetCards"]:
            var found: Control = ancestor.get_node_or_null(identifier) as Control
            if found != null:
                _host_back = found
                _host_back.hide()
                return
        ancestor = ancestor.get_parent()


func _exit_to_cards() -> void:
    if is_instance_valid(_host_back):
        _host_back.show()
    var portal: Node = get_node_or_null("/root/EmbeddedGamePortal")
    if portal != null and bool(portal.get("active")):
        portal.call("handle_scene_transition", "res://")
        return
    get_tree().change_scene_to_file("res://scenes/main.tscn")


func _exit_tree() -> void:
    if is_instance_valid(_host_back):
        _host_back.show()
