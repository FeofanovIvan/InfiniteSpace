extends "res://learning/src/features/tilt_maze/tilt_maze_game.gd"
## MIKA Roll the Ball v1 — shared top toolbar + one central responsive stage.
## No changes to maze generation, ball physics, touch/sensor/keyboard controls,
## win screen, voice, scoring or original source scripts.

const MIKA_TOOLBAR = preload("res://simulator_ui/scripts/mika_shared_tracing_toolbar_v2.gd")
const MIKA_UI = preload("res://simulator_ui/scripts/mika_minigame_ui_kit_v11.gd")
const MIKA_HUD = preload("res://planet_hub/scripts/bottom_hud.gd")
const MIKA_BACK_GLYPH = preload("res://simulator_ui/back_arrow_glyph.gd")

const TEXT := {
    "ru": {"title": "ЗАКАТИ ШАРИК", "subtitle": "Проведи шарик через лабиринт"},
    "en": {"title": "ROLL THE BALL", "subtitle": "Guide the ball through the maze"},
    "pt": {"title": "ROLE A BOLA", "subtitle": "Guie a bola pelo labirinto"},
    "es": {"title": "HAZ RODAR LA BOLA", "subtitle": "Guía la bola por el laberinto"},
    "de": {"title": "ROLLE DEN BALL", "subtitle": "Führe die Kugel durch das Labyrinth"},
    "fr": {"title": "FAIS ROULER LA BILLE", "subtitle": "Guide la bille dans le labyrinthe"},
}
const HOST_BACK_NAMES := ["ReturnToEducationalCards", "ReturnToExistingPlanetCards"]

var _mika_title_panel: Panel
var _mika_title_label: Label
var _mika_subtitle_label: Label
var _mika_back: Button
var _mika_counter: Control
var _mika_stage: Panel
var _mika_stage_rect: Rect2 = Rect2()
var _mika_header_bottom: float = 0.0
var _mika_local_points: int = 0
var _mika_locale: String = "en"
var _mika_host_back: Array[Button] = []


func _build_ui() -> void:
    super._build_ui()
    # The original exit button and exit method still exist; the unified back
    # replaces only their visible location/artwork.
    if back_button != null:
        back_button.hide()
    background.color = Color("061225")
    _mika_build_shell()
    call_deferred("_mika_find_host_back")


func _mika_build_shell() -> void:
    _mika_stage = Panel.new()
    _mika_stage.name = "RollBallLargeMainStage"
    _mika_stage.z_index = -1
    _mika_stage.mouse_filter = Control.MOUSE_FILTER_IGNORE
    _mika_stage.clip_contents = true
    var stage_skin := MIKA_UI.stage_style()
    stage_skin.set_corner_radius_all(29)
    stage_skin.bg_color = Color(0.018, 0.060, 0.125, 0.88)
    _mika_stage.add_theme_stylebox_override("panel", stage_skin)
    add_child(_mika_stage)

    _mika_title_panel = Panel.new()
    _mika_title_panel.name = "RollBallSharedTitlePanel"
    _mika_title_panel.z_index = 22
    _mika_title_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
    MIKA_TOOLBAR.apply_title_style(_mika_title_panel)
    add_child(_mika_title_panel)

    _mika_title_label = _mika_make_label("RollBallTitle", Color("eefbff"))
    _mika_subtitle_label = _mika_make_label("RollBallInstructions", Color("abdff4"))
    _mika_title_panel.add_child(_mika_title_label)
    _mika_title_panel.add_child(_mika_subtitle_label)

    _mika_back = Button.new()
    _mika_back.name = "RollBallSharedBack"
    _mika_back.z_index = 23
    _mika_back.focus_mode = Control.FOCUS_NONE
    _mika_back.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
    _mika_back.add_theme_stylebox_override("normal", MIKA_UI.button_style())
    _mika_back.add_theme_stylebox_override("hover", MIKA_UI.button_style(true))
    _mika_back.add_theme_stylebox_override("pressed", MIKA_UI.button_style(true))
    _mika_back.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
    _mika_back.pressed.connect(_go_back)
    add_child(_mika_back)
    var glyph: Control = MIKA_BACK_GLYPH.new() as Control
    glyph.mouse_filter = Control.MOUSE_FILTER_IGNORE
    _mika_back.add_child(glyph)
    glyph.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

    _mika_counter = MIKA_HUD.new() as Control
    _mika_counter.name = "RollBallNativeGamePoints"
    _mika_counter.z_index = 22
    _mika_counter.size = Vector2(1680.0, 158.0)
    _mika_counter.mouse_filter = Control.MOUSE_FILTER_IGNORE
    add_child(_mika_counter)
    for key in ["sim_button", "flight_button"]:
        var unused_button: Button = _mika_counter.get(key) as Button
        if unused_button != null:
            unused_button.disabled = true
            unused_button.hide()
    _mika_counter.set("crystal_count", _mika_local_points)
    _mika_set_locale()
    var language: Node = get_node_or_null("/root/LanguageService")
    if language != null and language.has_signal("language_changed"):
        language.connect("language_changed", Callable(self, "_mika_on_language_changed"))


func _mika_make_label(id: String, color: Color) -> Label:
    var label := Label.new()
    label.name = id
    label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
    label.mouse_filter = Control.MOUSE_FILTER_IGNORE
    label.clip_text = true
    label.add_theme_color_override("font_color", color)
    return label


func _mika_set_locale() -> void:
    var language: Node = get_node_or_null("/root/LanguageService")
    var locale: String = "en"
    if language != null:
        locale = str(language.get("learning_locale")).to_lower().substr(0, 2)
        if not TEXT.has(locale):
            locale = str(language.get("interface_locale")).to_lower().substr(0, 2)
    _mika_locale = locale if TEXT.has(locale) else "en"
    if _mika_title_label != null:
        var phrases: Dictionary = TEXT[_mika_locale]
        _mika_title_label.text = str(phrases["title"])
        _mika_subtitle_label.text = str(phrases["subtitle"])


func _mika_on_language_changed(_ignored: String) -> void:
    _mika_set_locale()
    _layout()


func _layout() -> void:
    # Preserve the original win overlay, touch setup and source calculations.
    super._layout()
    if _mika_title_panel == null:
        return
    _mika_layout_for_size(get_viewport_rect().size)


func _mika_layout_for_size(view: Vector2) -> void:
    var safe: Rect2 = _mika_safe_rect(view)
    _mika_header_bottom = MIKA_TOOLBAR.relayout(
        view, safe, _mika_back, _mika_counter,
        _mika_title_panel, _mika_title_label, _mika_subtitle_label
    )
    # Fit both localized lines without losing the shared MIKA title style.
    _mika_title_label.position = Vector2(6.0, _mika_title_panel.size.y * 0.06)
    _mika_title_label.size = Vector2(maxf(24.0, _mika_title_panel.size.x - 12.0), _mika_title_panel.size.y * 0.53)
    _mika_subtitle_label.position = Vector2(6.0, _mika_title_panel.size.y * 0.59)
    _mika_subtitle_label.size = Vector2(maxf(24.0, _mika_title_panel.size.x - 12.0), _mika_title_panel.size.y * 0.36)
    _mika_subtitle_label.show()
    var font: Font = ThemeDB.fallback_font
    var main_px: int = maxi(11, roundi(_mika_title_panel.size.y * 0.34))
    while main_px > 10 and font.get_string_size(_mika_title_label.text, HORIZONTAL_ALIGNMENT_LEFT, -1.0, main_px).x > _mika_title_label.size.x - 8.0:
        main_px -= 1
    _mika_title_label.add_theme_font_size_override("font_size", main_px)
    var second_px: int = maxi(9, roundi(_mika_title_panel.size.y * 0.19))
    while second_px > 8 and font.get_string_size(_mika_subtitle_label.text, HORIZONTAL_ALIGNMENT_LEFT, -1.0, second_px).x > _mika_subtitle_label.size.x - 8.0:
        second_px -= 1
    _mika_subtitle_label.add_theme_font_size_override("font_size", second_px)

    var side_margin: float = clampf(safe.size.x * 0.018, 6.0, 26.0)
    var gap: float = clampf(safe.size.y * 0.018, 5.0, 17.0)
    var bottom_margin: float = clampf(safe.size.y * 0.017, 6.0, 23.0)
    _mika_stage_rect = Rect2(
        safe.position.x + side_margin,
        _mika_header_bottom + gap,
        maxf(160.0, safe.size.x - 2.0 * side_margin),
        maxf(120.0, safe.end.y - _mika_header_bottom - gap - bottom_margin)
    )
    _mika_stage.position = _mika_stage_rect.position
    _mika_stage.size = _mika_stage_rect.size

    # Fit the existing *circular* board in the main stage; never stretch it.
    # Keep 17px between maze edge and the neon panel outline.
    var inset: float = clampf(minf(_mika_stage_rect.size.x, _mika_stage_rect.size.y) * 0.032, 7.0, 23.0)
    var diameter: float = maxf(1.0, minf(_mika_stage_rect.size.x, _mika_stage_rect.size.y) - inset * 2.0)
    board_rect = Rect2(
        _mika_stage_rect.position + (_mika_stage_rect.size - Vector2.ONE * diameter) * 0.5,
        Vector2.ONE * diameter
    )
    board.position = board_rect.position
    board.scale = Vector2.ONE * (diameter / source_size.x)
    _update_ball_visual()


func _mika_safe_rect(view: Vector2) -> Rect2:
    if OS.get_name() not in ["Android", "iOS"]:
        return Rect2(Vector2.ZERO, view)
    var window: Vector2 = Vector2(DisplayServer.window_get_size())
    var raw: Rect2i = DisplayServer.get_display_safe_area()
    if window.x < 100.0 or window.y < 100.0 or raw.size.x < 100:
        return Rect2(Vector2.ZERO, view)
    return Rect2(Vector2(raw.position) * (view / window), Vector2(raw.size) * (view / window))


func _reset_game() -> void:
    super._reset_game()
    _mika_local_points = 0
    if _mika_counter != null:
        _mika_counter.set("crystal_count", 0)


func _complete_game() -> void:
    if completed:
        return
    super._complete_game()
    # Mirrors the existing +3 GameState reward. Does NOT add extra points.
    _mika_local_points = 3
    if _mika_counter != null:
        _mika_counter.set("crystal_count", _mika_local_points)


func _mika_find_host_back() -> void:
    _mika_host_back.clear()
    for node in get_tree().root.find_children("*", "Button", true, false):
        if node.name in HOST_BACK_NAMES and node.visible:
            var host_button: Button = node as Button
            if host_button != null:
                _mika_host_back.append(host_button)
                host_button.hide()


func _exit_tree() -> void:
    for host_button in _mika_host_back:
        if is_instance_valid(host_button):
            host_button.show()


func _go_back() -> void:
    for host_button in _mika_host_back:
        if is_instance_valid(host_button):
            host_button.emit_signal("pressed")
            return
    var portal: Node = get_node_or_null("/root/EmbeddedGamePortal")
    if portal != null and bool(portal.get("active")) and portal.has_method("handle_scene_transition"):
        portal.call("handle_scene_transition", "")
        return
    super._go_back()
