extends "res://learning/src/features/tilt_maze/mika_roll_ball_magnetic_audio_v2_3_2.gd"
## MIKA Roll the Ball v2.4.1 — victory popup visuals and localization only.
## Inherited unchanged: magnetic maze, true Sun, stage, tilt physics and SFX.

var _mika_popup_inner_frame: Panel
var _mika_popup_subtitle: Label

const RESULT_TITLE = {
    "ru": "Лабиринт пройден!",
    "en": "Maze completed!",
    "pt": "Labirinto concluído!",
    "es": "¡Laberinto completado!",
    "fr": "Labyrinthe terminé !",
    "de": "Labyrinth geschafft!",
}
const RESULT_SUBTITLE = {
    "ru": "Магнитная миссия выполнена",
    "en": "Magnetic mission accomplished",
    "pt": "Missão magnética concluída",
    "es": "Misión magnética completada",
    "fr": "Mission magnétique accomplie",
    "de": "Magnetische Mission geschafft",
}


func _build_win_overlay() -> void:
    win_overlay = Control.new()
    win_overlay.name = "MagneticVictoryOverlay"
    win_overlay.visible = false
    win_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
    win_overlay.z_index = 80
    add_child(win_overlay)

    var dim := ColorRect.new()
    dim.name = "GentleSpaceDim"
    dim.color = Color(0.015, 0.045, 0.10, 0.38)
    dim.mouse_filter = Control.MOUSE_FILTER_STOP
    win_overlay.add_child(dim)
    dim.set_anchors_preset(Control.PRESET_FULL_RECT)

    win_panel = Panel.new()
    win_panel.name = "MagneticVictoryPanel"
    win_panel.mouse_filter = Control.MOUSE_FILTER_STOP
    var skin := StyleBoxFlat.new()
    skin.bg_color = Color(0.105, 0.27, 0.49, 0.78)
    skin.border_color = Color(0.52, 0.91, 1.0, 0.94)
    skin.set_border_width_all(3)
    skin.set_corner_radius_all(34)
    skin.shadow_color = Color(0.09, 0.77, 1.0, 0.52)
    skin.shadow_size = 22
    skin.shadow_offset = Vector2.ZERO
    win_panel.add_theme_stylebox_override("panel", skin)
    win_overlay.add_child(win_panel)

    _mika_popup_inner_frame = Panel.new()
    _mika_popup_inner_frame.name = "SoftInnerRim"
    _mika_popup_inner_frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
    var rim := StyleBoxFlat.new()
    rim.bg_color = Color(0.20, 0.59, 0.82, 0.09)
    rim.border_color = Color(0.70, 0.97, 1.0, 0.30)
    rim.set_border_width_all(1)
    rim.set_corner_radius_all(27)
    _mika_popup_inner_frame.add_theme_stylebox_override("panel", rim)
    win_panel.add_child(_mika_popup_inner_frame)

    var stars := Label.new()
    stars.name = "VictoryStars"
    stars.text = "✦   ✦   ✦"
    stars.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    stars.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
    stars.mouse_filter = Control.MOUSE_FILTER_IGNORE
    stars.add_theme_font_size_override("font_size", 28)
    stars.add_theme_color_override("font_color", Color(0.67, 0.98, 1.0, 0.98))
    win_panel.add_child(stars)

    win_label = Label.new()
    win_label.name = "VictoryTitleLocalized"
    win_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    win_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
    win_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    win_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
    win_label.add_theme_font_size_override("font_size", 37)
    win_label.add_theme_color_override("font_color", Color.WHITE)
    win_label.add_theme_color_override("font_shadow_color", Color(0.11, 0.58, 0.88, 0.68))
    win_label.add_theme_constant_override("shadow_outline_size", 5)
    win_panel.add_child(win_label)

    _mika_popup_subtitle = Label.new()
    _mika_popup_subtitle.name = "VictorySubtitleLocalized"
    _mika_popup_subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    _mika_popup_subtitle.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
    _mika_popup_subtitle.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    _mika_popup_subtitle.mouse_filter = Control.MOUSE_FILTER_IGNORE
    _mika_popup_subtitle.add_theme_font_size_override("font_size", 22)
    _mika_popup_subtitle.add_theme_color_override("font_color", Color(0.90, 0.98, 1.0, 0.96))
    win_panel.add_child(_mika_popup_subtitle)

    again_button = Button.new()
    again_button.name = "MagneticPlayAgain"
    again_button.focus_mode = Control.FOCUS_NONE
    _mika_popup_button_style(again_button, Color(0.12, 0.61, 0.86, 0.94))
    again_button.pressed.connect(_reset_game)
    win_panel.add_child(again_button)

    exit_button = Button.new()
    exit_button.name = "MagneticBack"
    exit_button.focus_mode = Control.FOCUS_NONE
    _mika_popup_button_style(exit_button, Color(0.18, 0.44, 0.73, 0.94))
    exit_button.pressed.connect(_go_back)
    win_panel.add_child(exit_button)


func _mika_popup_button_style(button: Button, fill: Color) -> void:
    for state in ["normal", "hover", "pressed", "focus"]:
        var style := StyleBoxFlat.new()
        style.bg_color = fill.darkened(0.15) if state == "pressed" else fill
        style.border_color = Color(0.79, 0.97, 1.0, 0.91)
        style.set_border_width_all(2)
        style.set_corner_radius_all(20)
        style.shadow_color = Color(0.10, 0.80, 1.0, 0.38)
        style.shadow_size = 9
        button.add_theme_stylebox_override(state, style)
    button.add_theme_color_override("font_color", Color.WHITE)
    button.add_theme_color_override("font_hover_color", Color.WHITE)
    button.add_theme_color_override("font_pressed_color", Color.WHITE)
    button.add_theme_font_size_override("font_size", 26)


func _apply_localized_text() -> void:
    # Original game already translates the action buttons in six languages.
    super._apply_localized_text()
    var locale: String = String(LanguageService.interface_locale).substr(0, 2)
    win_label.text = RESULT_TITLE.get(locale, RESULT_TITLE["en"])
    _mika_popup_subtitle.text = RESULT_SUBTITLE.get(locale, RESULT_SUBTITLE["en"])


func _layout() -> void:
    # Keep all v2.2 responsive stage/maze/sun/physics layout untouched.
    super._layout()
    if win_panel == null or _mika_popup_inner_frame == null:
        return
    var view: Vector2 = get_viewport_rect().size
    win_overlay.position = Vector2.ZERO
    win_overlay.size = view
    var width: float = minf(view.x - 32.0, 610.0)
    var height: float = minf(view.y - 28.0, 360.0)
    var size: Vector2 = Vector2(width, height)
    win_panel.position = (view - size) * 0.5
    win_panel.size = size
    _mika_popup_inner_frame.position = Vector2(10.0, 10.0)
    _mika_popup_inner_frame.size = size - Vector2(20.0, 20.0)
    var stars: Label = win_panel.get_node("VictoryStars") as Label
    stars.position = Vector2(size.x * 0.08, size.y * 0.045)
    stars.size = Vector2(size.x * 0.84, size.y * 0.15)
    win_label.position = Vector2(size.x * 0.075, size.y * 0.195)
    win_label.size = Vector2(size.x * 0.85, size.y * 0.27)
    _mika_popup_subtitle.position = Vector2(size.x * 0.075, size.y * 0.465)
    _mika_popup_subtitle.size = Vector2(size.x * 0.85, size.y * 0.17)
    var action_y: float = size.y * 0.715
    var action_height: float = size.y * 0.19
    var action_width: float = size.x * 0.38
    again_button.position = Vector2(size.x * 0.085, action_y)
    again_button.size = Vector2(action_width, action_height)
    exit_button.position = Vector2(size.x * 0.535, action_y)
    exit_button.size = Vector2(action_width, action_height)
    var button_font: int = int(clampf(size.y * 0.075, 19.0, 27.0))
    again_button.add_theme_font_size_override("font_size", button_font)
    exit_button.add_theme_font_size_override("font_size", button_font)
    win_label.add_theme_font_size_override("font_size", int(clampf(size.y * 0.103, 27.0, 38.0)))
    _mika_popup_subtitle.add_theme_font_size_override("font_size", int(clampf(size.y * 0.063, 18.0, 23.0)))
