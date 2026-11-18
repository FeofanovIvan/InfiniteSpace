extends Control
## MIKA Gravity Pinball v2.3 — the two real main-flight circular controllers.
## Existing original game and v2 scripts remain untouched for safe rollback.

const TOOLBAR: Script = preload("res://simulator_ui/scripts/mika_shared_tracing_toolbar_v2.gd")
const HUD: Script = preload("res://planet_hub/scripts/bottom_hud.gd")
const GLYPH: Script = preload("res://simulator_ui/back_arrow_glyph.gd")
const KIT: Script = preload("res://simulator_ui/scripts/mika_minigame_ui_kit_v11.gd")
const VERTICAL_JOYSTICK: Script = preload("res://planet_hub/games/gravity_pinball/gravity_pinball_main_vertical_v23.gd")
const LAUNCH_BUTTON: Script = preload("res://planet_hub/games/gravity_pinball/gravity_pinball_main_rocket_v23.gd")
const ARENA: Script = preload("res://planet_hub/games/gravity_pinball/gravity_pinball_arena_v23.gd")

const WORDS: Dictionary = {
    "ru": {"title":"ГРАВИТАЦИОННЫЙ ПИНБОЛ", "sub":"Удерживай ракету, отпусти для запуска • Справа — направление"},
    "en": {"title":"GRAVITY PINBALL", "sub":"Hold the rocket, release to launch • Aim on the right"},
    "pt": {"title":"PINBALL GRAVITACIONAL", "sub":"Segure o foguete e solte para lançar • Mire à direita"},
    "es": {"title":"PINBALL GRAVITACIONAL", "sub":"Mantén el cohete y suéltalo para lanzar • Apunta a la derecha"},
    "fr": {"title":"FLIPPER GRAVITATIONNEL", "sub":"Maintiens la fusée, puis relâche • Vise à droite"},
    "de": {"title":"GRAVITATIONS-PINBALL", "sub":"Rakete halten und zum Start loslassen • Rechts zielen"}
}

# Single spoken instruction on scene entry. No new sound effects and no repetition on NEW GAME.
const INTRO_TEXT: Dictionary = {
    "ru": "Запусти свой шар!",
    "en": "Launch your ball!",
    "pt": "Lance a bola!",
    "es": "¡Lanza la bola!",
    "fr": "Lance ta bille !",
    "de": "Schieß die Kugel los!"
}

var _stage: Panel
var _arena: Control
var _back: Button
var _host_back: Control
var _title_panel: Panel
var _title: Label
var _subtitle: Label
var _crystals: Control
var _launch_button: Control
var _aim_joystick: Control
var _left_caption: Label
var _right_caption: Label
var _end_panel: Panel
var _end_caption: Label
var _new_game_button: Button
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

    # Original main-flight joystick (scripts/Joystick.gd) limited to vertical travel.
    _aim_joystick = VERTICAL_JOYSTICK.new() as Control
    _aim_joystick.name = "VerticalAimMainMenuJoystick"
    _stage.add_child(_aim_joystick)
    _aim_joystick.call("setup", 0.50)
    _aim_joystick.connect("value_changed", Callable(_arena, "set_aim_amount"))
    _arena.call("set_aim_amount", 0.50)

    # Original main-flight ActionButton rings and original landing rocket glyph.
    # Hold = spring oscillates. Release = launch at the current spring power.
    _launch_button = LAUNCH_BUTTON.new() as Control
    _launch_button.name = "CircularMainMenuLaunchButton"
    _stage.add_child(_launch_button)
    _launch_button.connect("hold_started", _on_launch_pressed)
    _launch_button.connect("hold_released", _on_launch_released)
    _launch_button.connect("hold_cancelled", _on_launch_cancelled)

    _arena.connect("round_finished", _on_round_finished)

    _left_caption = _create_caption(_stage, "LAUNCH")
    _right_caption = _create_caption(_stage, "AIM")
    _create_end_overlay()

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
    call_deferred("_announce_game_start")


func _create_end_overlay() -> void:
    _end_panel = Panel.new()
    _end_panel.name = "PinballRoundFinishedPanel"
    _end_panel.mouse_filter = Control.MOUSE_FILTER_STOP
    _end_panel.add_theme_stylebox_override("panel", KIT.stage_style())
    _stage.add_child(_end_panel)
    _end_panel.hide()
    _end_caption = Label.new()
    _end_caption.name = "RoundFinishedCaption"
    _end_caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    _end_caption.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
    _end_caption.mouse_filter = Control.MOUSE_FILTER_IGNORE
    _end_caption.add_theme_color_override("font_color", Color("e4faff"))
    _end_panel.add_child(_end_caption)
    _new_game_button = Button.new()
    _new_game_button.name = "NewRandomPlanetRound"
    _new_game_button.focus_mode = Control.FOCUS_NONE
    _new_game_button.add_theme_stylebox_override("normal", KIT.button_style(false))
    _new_game_button.add_theme_stylebox_override("hover", KIT.button_style(true))
    _new_game_button.add_theme_stylebox_override("pressed", KIT.button_style(true))
    _new_game_button.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
    _new_game_button.pressed.connect(_new_game)
    _end_panel.add_child(_new_game_button)


func _on_round_finished(count: int) -> void:
    _end_panel.show()
    _launch_button.hide()
    _aim_joystick.hide()
    _left_caption.hide()
    _right_caption.hide()
    _update_end_words(count)
    _relayout()


func _update_end_words(count: int) -> void:
    var captions: Dictionary = {
        "ru": ["АСТЕРОИД В КОРЗИНЕ!", "НОВАЯ ИГРА"],
        "en": ["ASTEROID IN THE BASKET!", "NEW GAME"],
        "pt": ["ASTEROIDE NA CESTA!", "NOVO JOGO"],
        "es": ["¡ASTEROIDE EN LA CESTA!", "NUEVA PARTIDA"],
        "fr": ["ASTÉROÏDE DANS LE PANIER !", "NOUVELLE PARTIE"],
        "de": ["ASTEROID IM KORB!", "NEUES SPIEL"]
    }
    var words: Array = captions.get(_locale, captions["en"])
    _end_caption.text = str(words[0]) + "  •  +" + str(count) + " ✧"
    _new_game_button.text = str(words[1])


func _new_game() -> void:
    _arena.call("start_new_game")
    _end_panel.hide()
    _launch_button.show()
    _aim_joystick.show()
    _left_caption.show()
    _right_caption.show()
    _launch_button.call("set_enabled", true)
    _aim_joystick.call("clear_input")
    _arena.call("set_aim_amount", 0.50)
    _relayout()


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


func _announce_game_start() -> void:
    # TTS only once when this scene is opened; use the current interface language.
    # Missing OS voices are a silent no-op; never speak another language by mistake.
    if not is_inside_tree():
        return
    if not bool(ProjectSettings.get_setting("audio/general/text_to_speech", false)):
        return
    var voices: PackedStringArray = DisplayServer.tts_get_voices_for_language(_locale)
    if voices.is_empty():
        return
    DisplayServer.tts_speak(str(INTRO_TEXT.get(_locale, INTRO_TEXT["en"])), voices[0], 70, 1.0, 0.95)


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
        "ru": ["ЗАПУСК", "ПРИЦЕЛ"], "en": ["LAUNCH", "AIM"],
        "pt": ["LANÇAR", "DIREÇÃO"], "es": ["LANZAR", "DIRECCIÓN"],
        "fr": ["LANCER", "DIRECTION"], "de": ["START", "RICHTUNG"]
    }
    var pair: Array = names.get(_locale, names["en"])
    _left_caption.text = str(pair[0])
    _right_caption.text = str(pair[1])
    if _end_panel != null:
        _update_end_words(int(_arena.get("_crystals")))
    if _arena != null:
        _arena.set("locale", _locale)


func _on_crystals_changed(count: int) -> void:
    if is_instance_valid(_crystals):
        _crystals.set("crystal_count", count)


func _on_launch_pressed() -> void:
    _arena.call("begin_spring_charge")


func _on_launch_released() -> void:
    _arena.call("release_spring_charge")
    if bool(_arena.get("_shot_active")):
        _launch_button.call("set_enabled", false)


func _on_launch_cancelled() -> void:
    _arena.call("cancel_spring_charge")


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
    # EXACT same 184x184 circular joystick/action widgets as the main flight scene,
    # downscaled equally, placed symmetrically at the lower corners of the arena.
    var control_scale: float = clampf(minf(_stage.size.y / 600.0, _stage.size.x / 1500.0), 0.43, 0.80)
    var diameter: float = 184.0 * control_scale
    var margin: float = clampf(_stage.size.y * 0.025, 9.0, 17.0)
    _launch_button.size = Vector2(184.0, 184.0)
    _aim_joystick.size = Vector2(184.0, 184.0)
    _launch_button.scale = Vector2.ONE * control_scale
    _aim_joystick.scale = Vector2.ONE * control_scale
    var controls_y: float = _stage.size.y - diameter - margin
    _launch_button.position = Vector2(margin, controls_y)
    _aim_joystick.position = Vector2(_stage.size.x - diameter - margin, controls_y)
    var font_px: int = maxi(10, roundi(17.0 * control_scale))
    _left_caption.position = _launch_button.position + Vector2(0.0, -24.0 * control_scale)
    _left_caption.size = Vector2(diameter, maxf(16.0, 23.0 * control_scale))
    _right_caption.position = _aim_joystick.position + Vector2(0.0, -24.0 * control_scale)
    _right_caption.size = Vector2(diameter, maxf(16.0, 23.0 * control_scale))
    _left_caption.add_theme_font_size_override("font_size", font_px)
    _right_caption.add_theme_font_size_override("font_size", font_px)
    # Centered overlay used only when the asteroid enters a wall basket.
    var overlay_w: float = minf(_stage.size.x * 0.78, 540.0)
    var overlay_h: float = clampf(_stage.size.y * 0.38, 120.0, 215.0)
    _end_panel.position = (_stage.size - Vector2(overlay_w, overlay_h)) * 0.5
    _end_panel.size = Vector2(overlay_w, overlay_h)
    _end_caption.position = Vector2(12.0, overlay_h * 0.12)
    _end_caption.size = Vector2(overlay_w - 24.0, overlay_h * 0.39)
    _end_caption.add_theme_font_size_override("font_size", maxi(11, roundi(24.0 * control_scale)))
    _new_game_button.position = Vector2(overlay_w * 0.19, overlay_h * 0.58)
    _new_game_button.size = Vector2(overlay_w * 0.62, overlay_h * 0.30)
    _new_game_button.add_theme_font_size_override("font_size", maxi(12, roundi(20.0 * control_scale)))
    _arena.call("set_control_clearance", diameter + 20.0)
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
