extends "res://planet_hub/games/ice_planet/IcePlanet.gd"
## MIKA — Ice Planet native header and adaptive game stage, v1 (Godot 4.7.1).
## Original IcePlanet.gd physics, missions, touch controls and art remain untouched.
## Only the original scene is redirected to this derived presentation script.

const MIKA_TOOLBAR = preload("res://simulator_ui/scripts/mika_shared_tracing_toolbar_v2.gd")
const MIKA_UI = preload("res://simulator_ui/scripts/mika_minigame_ui_kit_v11.gd")
const MIKA_CRYSTAL_HUD = preload("res://planet_hub/scripts/bottom_hud.gd")
const MIKA_BACK_ARROW = preload("res://simulator_ui/back_arrow_glyph.gd")

const CONTENT_CROP_TOP: float = 145.0
const CONTENT_HEIGHT: float = 559.0   # original content occupies y=149..698
const SHORT_RESTART: Dictionary = {
    "ru": "Заново", "en": "Restart", "pt": "Reiniciar",
    "es": "Reiniciar", "de": "Neustart", "fr": "Rejouer"
}
const SHORT_SUBTITLES: Dictionary = {
    "ru": "Спаси океаны четырёх миров",
    "en": "Save the oceans of four worlds",
    "pt": "Salve os oceanos de quatro mundos",
    "es": "Salva los océanos de cuatro mundos",
    "de": "Rette die Ozeane von vier Welten",
    "fr": "Sauve les océans de quatre mondes"
}

var _mika_title_panel: Panel
var _mika_header_title: Label
var _mika_header_subtitle: Label
var _mika_back_button: Button
var _mika_hud: Control
var _stage_rect: Rect2
var _header_bottom: float = 0.0
var _host_back_buttons: Array[Button] = []
var _host_back_visibility: Array[bool] = []


func _ready() -> void:
    super._ready()
    _build_mika_toolbar()
    _hide_legacy_header()
    _style_actions()
    _layout()
    call_deferred("_layout")
    call_deferred("_claim_host_back_buttons")


func _build_mika_toolbar() -> void:
    _mika_title_panel = Panel.new()
    _mika_title_panel.name = "IcePlanetMIKAHeader"
    _mika_title_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
    MIKA_TOOLBAR.apply_title_style(_mika_title_panel)
    add_child(_mika_title_panel)

    _mika_header_title = _header_label()
    _mika_title_panel.add_child(_mika_header_title)
    _mika_header_subtitle = _header_label()
    _mika_header_subtitle.add_theme_color_override("font_color", Color("a7daee"))
    _mika_title_panel.add_child(_mika_header_subtitle)

    _mika_back_button = Button.new()
    _mika_back_button.name = "IcePlanetBackInToolbar"
    _mika_back_button.focus_mode = Control.FOCUS_NONE
    _mika_back_button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
    _mika_back_button.add_theme_stylebox_override("normal", MIKA_UI.button_style())
    _mika_back_button.add_theme_stylebox_override("hover", MIKA_UI.button_style(true))
    _mika_back_button.add_theme_stylebox_override("pressed", MIKA_UI.button_style(true))
    _mika_back_button.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
    _mika_back_button.pressed.connect(_return_to_game_cards)
    add_child(_mika_back_button)
    var arrow: Control = MIKA_BACK_ARROW.new() as Control
    arrow.mouse_filter = Control.MOUSE_FILTER_IGNORE
    _mika_back_button.add_child(arrow)
    arrow.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

    _mika_hud = MIKA_CRYSTAL_HUD.new() as Control
    _mika_hud.name = "IcePlanetNativeCrystals"
    _mika_hud.size = Vector2(1680.0, 158.0)
    _mika_hud.mouse_filter = Control.MOUSE_FILTER_IGNORE
    add_child(_mika_hud)
    for property_name in ["sim_button", "flight_button"]:
        var b: Button = _mika_hud.get(property_name) as Button
        if b != null:
            b.disabled = true
            b.hide()
    _mika_hud.set("crystal_count", int(_score / 100))
    _refresh_toolbar_text()


func _header_label() -> Label:
    var label := Label.new()
    label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
    label.mouse_filter = Control.MOUSE_FILTER_IGNORE
    label.clip_text = true
    label.add_theme_color_override("font_color", Color("eefbff"))
    return label


func _hide_legacy_header() -> void:
    # The language selector is intentionally not presented in the game.
    # Languages are still read from the parent Settings/LanguageService.
    for old_control in [
        _title, _subtitle, _round_label, _score_label,
        _language_picker, _instruction_label,
        _model_note, _guide_label
    ]:
        if old_control != null:
            old_control.hide()
            old_control.mouse_filter = Control.MOUSE_FILTER_IGNORE


func _style_actions() -> void:
    for control in [_hint_button, _restart_button, _next_button]:
        if control == null:
            continue
        control.add_theme_stylebox_override("normal", MIKA_UI.button_style())
        control.add_theme_stylebox_override("hover", MIKA_UI.button_style(true))
        control.add_theme_stylebox_override("pressed", MIKA_UI.button_style(true))
        control.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
        control.add_theme_font_size_override("font_size", 14)
    _refresh_action_visibility()


func _refresh_toolbar_text() -> void:
    if _mika_header_title == null:
        return
    _mika_header_title.text = _tr("title")
    _mika_header_subtitle.text = str(SHORT_SUBTITLES.get(_interface_lang, SHORT_SUBTITLES["en"]))
    if _mika_hud != null:
        _mika_hud.set("crystal_count", int(_score / 100))


func _update_labels() -> void:
    super._update_labels()
    if _restart_button != null:
        _restart_button.text = "↻ " + str(SHORT_RESTART.get(_interface_lang, SHORT_RESTART["en"]))
    _refresh_toolbar_text()


func _process(delta: float) -> void:
    super._process(delta)
    _refresh_action_visibility()


func _refresh_action_visibility() -> void:
    if _hint_button == null or _restart_button == null:
        return
    # The completed mission uses the whole control row for 'Next World'.
    # New Game remains available on the next full cycle.
    var active: bool = not _mission_complete and not _game_complete
    _hint_button.visible = active
    _restart_button.visible = active


func _layout() -> void:
    if _mika_title_panel == null or _mika_back_button == null or _mika_hud == null:
        super._layout()
        return
    var view: Vector2 = size
    if view.x <= 1.0 or view.y <= 1.0:
        view = get_viewport_rect().size
    if view.x < 180.0 or view.y < 180.0:
        return
    var safe: Rect2 = _safe_view_area(view)
    _header_bottom = MIKA_TOOLBAR.relayout(
        view, safe, _mika_back_button, _mika_hud,
        _mika_title_panel, _mika_header_title, _mika_header_subtitle
    )
    var margin_x: float = clampf(safe.size.x * 0.016, 7.0, 28.0)
    var margin_y: float = clampf(safe.size.y * 0.018, 5.0, 19.0)
    _stage_rect = Rect2(
        safe.position.x + margin_x,
        _header_bottom + margin_y,
        maxf(120.0, safe.size.x - margin_x * 2.0),
        maxf(130.0, safe.end.y - _header_bottom - margin_y * 2.0)
    )
    # A uniform design scale keeps circles circular, not ellipses, on
    # unusually wide or tall displays. A full-viewport sky fills unused edges.
    _scale = minf(_stage_rect.size.x / DESIGN.x, _stage_rect.size.y / CONTENT_HEIGHT)
    _scale = maxf(0.05, _scale)
    var occupied: Vector2 = Vector2(DESIGN.x, CONTENT_HEIGHT) * _scale
    _origin = _stage_rect.position + (_stage_rect.size - occupied) * 0.5 - Vector2(0.0, CONTENT_CROP_TOP * _scale)
    _layout_legacy_game_content()
    queue_redraw()


func _layout_legacy_game_content() -> void:
    # These are the original IcePlanet.gd panel coordinates. Do not move
    # the interactive surfaces independently of their drawing/input zones.
    _put(_mission_label, Rect2(370, 169, 443, 33))
    _put(_phase_label, Rect2(430, 451, 355, 27))
    _put(_panel_title, Rect2(980, 170, 260, 31))
    _put(_state_label, Rect2(982, 214, 256, 39))
    _put(_average_label, Rect2(992, 263, 237, 32))
    _put(_warm_label, Rect2(992, 305, 237, 30))
    _put(_cool_label, Rect2(992, 343, 237, 30))
    _put(_stable_label, Rect2(987, 412, 245, 25))
    _put(_next_button, Rect2(996, 454, 233, 52))
    # In the original script these floated above the board and collided
    # with the header. They now share the right monitor's action row.
    _put(_hint_button, Rect2(984, 461, 111, 43))
    _put(_restart_button, Rect2(1101, 461, 139, 43))

    _put(_distance_label, Rect2(59, 552, 548, 29))
    _put(_rotation_label, Rect2(685, 552, 510, 29))
    _put(_distance_near_label, Rect2(81, 638, 175, 23))
    _put(_distance_far_label, Rect2(416, 638, 178, 23))
    _put(_rotation_slow_label, Rect2(709, 638, 175, 23))
    _put(_rotation_fast_label, Rect2(1004, 638, 176, 23))
    _put(_tip_label, Rect2(354, 663, 584, 25))


func _safe_view_area(view: Vector2) -> Rect2:
    if OS.get_name() not in ["Android", "iOS"]:
        return Rect2(Vector2.ZERO, view)
    var window: Vector2 = Vector2(DisplayServer.window_get_size())
    var raw: Rect2i = DisplayServer.get_display_safe_area()
    if window.x < 100.0 or window.y < 100.0 or raw.size.x < 100:
        return Rect2(Vector2.ZERO, view)
    return Rect2(Vector2(raw.position) * (view / window), Vector2(raw.size) * (view / window))


func _draw() -> void:
    # The inherited game scene uses a 1280x720 stage. Draw the sky over the
    # entire real viewport so letterboxing never leaves transparent strips.
    draw_rect(Rect2(Vector2.ZERO, size), Color("061225"), true)
    for i in range(100):
        var point := Vector2(fmod(float(47 + i * 353), maxf(size.x, 1.0)), fmod(float(23 + i * 191), maxf(size.y, 1.0)))
        draw_circle(point, 0.75 + float(i % 3) * 0.45, Color(0.57, 0.80, 1.0, 0.16 + float(i % 3) * 0.08))
    draw_set_transform(_origin, 0.0, Vector2.ONE * _scale)
    _draw_background()
    _draw_panels()
    _draw_orbit()
    _draw_sun()
    _draw_planet()
    _draw_monitor()
    _draw_sliders()
    draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


func _draw_panels() -> void:
    # Only three functional panels. The old floating top instruction plaque
    # is removed because its text moved into the native toolbar.
    _panel(Rect2(27, 149, 929, 374), Color("0d2039"), Color("366a90"), 23, 2)
    _panel(Rect2(971, 149, 281, 374), Color("10253e"), Color("37658b"), 23, 2)
    _panel(Rect2(29, 537, 1222, 161), Color("0e2039"), Color("3b7297"), 22, 2)
    draw_line(Vector2(955, 174), Vector2(955, 493), Color("447ca1", 0.42), 1.5, true)
    draw_line(Vector2(638, 558), Vector2(638, 668), Color("34658e", 0.8), 2.0, true)


func _claim_host_back_buttons() -> void:
    # Host Planet Hub / Simulator has another Back outside the game SubViewport.
    if not is_inside_tree():
        return
    for name in ["ReturnToExistingPlanetCards", "ReturnToEducationalCards"]:
        for item in get_tree().root.find_children(name, "Button", true, false):
            var button: Button = item as Button
            if button == null or button == _mika_back_button:
                continue
            if _host_back_buttons.has(button) or not button.is_visible_in_tree():
                continue
            _host_back_buttons.append(button)
            _host_back_visibility.append(button.visible)
            button.hide()


func _exit_tree() -> void:
    for i in range(_host_back_buttons.size()):
        var b: Button = _host_back_buttons[i]
        if is_instance_valid(b):
            b.visible = _host_back_visibility[i]
    _host_back_buttons.clear()
    _host_back_visibility.clear()


func _return_to_game_cards() -> void:
    var portal: Node = get_node_or_null("/root/EmbeddedGamePortal")
    if portal != null and bool(portal.get("active")):
        portal.call("handle_scene_transition", "")
        return
    var parent_node: Node = get_parent()
    for i in range(16):
        if parent_node == null:
            break
        if parent_node.has_method("_v1051_return_to_cards"):
            parent_node.call("_v1051_return_to_cards")
            return
        if parent_node.has_method("_return_to_cards"):
            parent_node.call("_return_to_cards")
            return
        parent_node = parent_node.get_parent()
    var fallback: String = "res://scenes/main.tscn"
    if ResourceLoader.exists(fallback):
        get_tree().change_scene_to_file(fallback)


func _unhandled_key_input(event: InputEvent) -> void:
    if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
        _return_to_game_cards()
        get_viewport().set_input_as_handled()
