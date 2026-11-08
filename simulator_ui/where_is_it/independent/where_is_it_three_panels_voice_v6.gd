extends "res://simulator_ui/where_is_it/independent/where_is_it_shared_template_viewportsafe_v5.gd"
## MIKA Where Is It v6 — three approved-style panels, full-width adaptive word tiles,
## and native MikaVoice pronunciation. 3D cube, rounds, score and SFX unchanged.

const V6_UI_KIT = preload("res://simulator_ui/scripts/mika_minigame_ui_kit_v11.gd")
const V6_TOOL_TIPS = {
    "en": ["Undo last word", "Previous round", "Next round"],
    "ru": ["Отменить последнее слово", "Предыдущее задание", "Следующее задание"],
    "pt": ["Desfazer a última palavra", "Rodada anterior", "Próxima rodada"],
    "es": ["Deshacer la última palabra", "Ronda anterior", "Siguiente ronda"],
    "fr": ["Annuler le dernier mot", "Manche précédente", "Manche suivante"],
    "de": ["Letztes Wort zurücknehmen", "Vorherige Runde", "Nächste Runde"]
}

var _v6_left_panel: Panel = null
var _v6_cube_panel: Panel = null
var _v6_right_panel: Panel = null
var _v6_rotate_caption: Label = null
var _v6_last_word: String = ""
var _v6_last_spoken_ms: int = -100000


func _build_stage() -> void:
    super._build_stage()
    # The approved v5 title, native back glyph and genuine PlanetHub counter
    # stay untouched. Replace only the central shared backdrop with three panels.
    _shared_body.hide()
    _v6_left_panel = _v6_make_panel("WhereV6_LeftControls")
    _v6_cube_panel = _v6_make_panel("WhereV6_ExactCubeViewportFrame")
    _v6_right_panel = _v6_make_panel("WhereV6_RightControls")
    _v6_rotate_caption = stage.get_node_or_null("RotateHeading") as Label
    if _v6_rotate_caption != null:
        _v6_rotate_caption.show()
        _v6_rotate_caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
        _v6_rotate_caption.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
        _v6_rotate_caption.clip_text = true
        _v6_rotate_caption.mouse_filter = Control.MOUSE_FILTER_IGNORE
    _native_undo_button.text = "↩"
    _native_undo_button.tooltip_text = "Undo last word"
    _v6_style_controls()


func _v6_make_panel(node_name: String) -> Panel:
    var pane := Panel.new()
    pane.name = node_name
    pane.mouse_filter = Control.MOUSE_FILTER_IGNORE
    var style := V6_UI_KIT.stage_style()
    # Identical palette/glow from the shared kit; smaller radius suits narrow rails.
    style.set_corner_radius_all(20)
    pane.add_theme_stylebox_override("panel", style)
    stage.add_child(pane)
    # The panels are backgrounds, never placed over the cube or touch controls.
    stage.move_child(pane, viewport_box.get_index())
    return pane


func _v6_style_controls() -> void:
    for control in [prev_view_button, next_view_button, reset_view_button,
            _native_undo_button, _native_round_prev, _native_round_next]:
        var button: Button = control as Button
        if button == null:
            continue
        button.add_theme_stylebox_override("normal", V6_UI_KIT.button_style())
        button.add_theme_stylebox_override("hover", V6_UI_KIT.button_style(true))
        var pressed_style := V6_UI_KIT.button_style(true)
        pressed_style.bg_color = Color("#0b2847")
        button.add_theme_stylebox_override("pressed", pressed_style)
        var disabled_style := V6_UI_KIT.button_style()
        disabled_style.bg_color = V6_UI_KIT.NAVY.darkened(0.15)
        disabled_style.border_color = V6_UI_KIT.CYAN.darkened(0.55)
        button.add_theme_stylebox_override("disabled", disabled_style)
        button.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
        button.add_theme_color_override("font_color", V6_UI_KIT.PAPER)
        button.add_theme_color_override("font_hover_color", Color.WHITE)
        button.add_theme_color_override("font_pressed_color", V6_UI_KIT.PAPER)
        button.add_theme_color_override("font_disabled_color", V6_UI_KIT.MUTED)
        button.focus_mode = Control.FOCUS_NONE


func _layout_for_viewport(view_size: Vector2) -> void:
    super._layout_for_viewport(view_size)
    if _v6_cube_panel == null or _shared_body == null:
        return
    var body := Rect2(_shared_body.position, _shared_body.size)
    if body.size.x < 250.0 or body.size.y < 130.0:
        return
    var gap: float = clampf(minf(body.size.x, body.size.y) * 0.035, 7.0, 16.0)
    var landscape: bool = stage.size.x >= stage.size.y * 0.92
    var left_rect: Rect2
    var cube_rect: Rect2
    var right_rect: Rect2
    if landscape:
        var side: float = clampf(body.size.x * 0.155, 100.0, 200.0)
        side = minf(side, maxf(90.0, (body.size.x - 240.0 - 2.0 * gap) * 0.5))
        left_rect = Rect2(body.position, Vector2(side, body.size.y))
        right_rect = Rect2(Vector2(body.end.x - side, body.position.y), Vector2(side, body.size.y))
        cube_rect = Rect2(Vector2(left_rect.end.x + gap, body.position.y),
                Vector2(body.size.x - 2.0 * side - 2.0 * gap, body.size.y))
    else:
        # Portrait fallback: controls occupy two compact panels over the cube.
        var controls_h: float = clampf(body.size.y * 0.22, 116.0, 157.0)
        var side: float = (body.size.x - gap) * 0.5
        left_rect = Rect2(body.position, Vector2(side, controls_h))
        right_rect = Rect2(Vector2(body.position.x + side + gap, body.position.y), Vector2(side, controls_h))
        cube_rect = Rect2(Vector2(body.position.x, body.position.y + controls_h + gap),
                Vector2(body.size.x, maxf(130.0, body.size.y - controls_h - gap)))
    _v6_left_panel.position = left_rect.position
    _v6_left_panel.size = left_rect.size
    _v6_cube_panel.position = cube_rect.position
    _v6_cube_panel.size = cube_rect.size
    _v6_right_panel.position = right_rect.position
    _v6_right_panel.size = right_rect.size
    # The central panel wraps the real dark-blue 3D SubViewport, with a 3px edge.
    # stretch=true means the container itself controls the child SubViewport size.
    viewport_box.position = cube_rect.position + Vector2(3.0, 3.0)
    viewport_box.size = Vector2(maxf(1.0, cube_rect.size.x - 6.0), maxf(1.0, cube_rect.size.y - 6.0))
    _v6_layout_left_buttons(left_rect, not landscape)
    _v6_layout_right_buttons(right_rect, not landscape)
    feedback.position = Vector2(cube_rect.position.x + 10.0,
            cube_rect.end.y - minf(34.0, cube_rect.size.y * 0.20))
    feedback.size = Vector2(maxf(50.0, cube_rect.size.x - 20.0), 27.0)
    feedback.add_theme_font_size_override("font_size", clampi(roundi(cube_rect.size.y * 0.055), 11, 19))
    feedback.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    feedback.clip_text = true
    feedback.z_index = 2  # Feedback remains legible over the 3D viewport
    _shared_layout_chips()
    _shared_request_projection()


func _v6_layout_left_buttons(pane: Rect2, compact: bool) -> void:
    var inset: float = clampf(pane.size.x * 0.08, 7.0, 16.0)
    if _v6_rotate_caption != null:
        _v6_rotate_caption.position = pane.position + Vector2(inset, 7.0)
        _v6_rotate_caption.size = Vector2(pane.size.x - 2.0 * inset, 31.0)
        _v6_rotate_caption.add_theme_font_size_override("font_size",
                clampi(roundi(pane.size.x * 0.10), 11, 19))
    if compact:
        var gap: float = 5.0
        var b: float = minf(49.0, (pane.size.x - 2.0 * inset - 2.0 * gap) / 3.0)
        var y: float = pane.position.y + pane.size.y * 0.51
        var total: float = 3.0 * b + 2.0 * gap
        var x: float = pane.position.x + (pane.size.x - total) * 0.5
        prev_view_button.position = Vector2(x, y)
        next_view_button.position = Vector2(x + b + gap, y)
        reset_view_button.position = Vector2(x + 2.0 * (b + gap), y)
        for item in [prev_view_button, next_view_button, reset_view_button]:
            item.size = Vector2(b, 44.0)
            item.add_theme_font_size_override("font_size", 27)
    else:
        var gap: float = clampf(pane.size.x * 0.045, 5.0, 12.0)
        var b_w: float = minf(75.0, (pane.size.x - 2.0 * inset - gap) * 0.5)
        var b_h: float = clampf(pane.size.y * 0.22, 38.0, 62.0)
        var center: float = pane.position.x + pane.size.x * 0.5
        var row_y: float = pane.position.y + pane.size.y * 0.40 - b_h * 0.5
        prev_view_button.position = Vector2(center - b_w - gap * 0.5, row_y)
        next_view_button.position = Vector2(center + gap * 0.5, row_y)
        for item in [prev_view_button, next_view_button]:
            item.size = Vector2(b_w, b_h)
            item.add_theme_font_size_override("font_size", 34)
        reset_view_button.size = Vector2(minf(pane.size.x - 2.0 * inset, 134.0), b_h)
        reset_view_button.position = Vector2(center - reset_view_button.size.x * 0.5,
                pane.position.y + pane.size.y * 0.67 - b_h * 0.5)
        reset_view_button.add_theme_font_size_override("font_size", 33)


func _v6_layout_right_buttons(pane: Rect2, compact: bool) -> void:
    var inset: float = clampf(pane.size.x * 0.08, 7.0, 16.0)
    var center: float = pane.position.x + pane.size.x * 0.5
    if compact:
        var gap: float = 5.0
        var b: float = minf(50.0, (pane.size.x - 2.0 * inset - 2.0 * gap) / 3.0)
        var y: float = pane.position.y + pane.size.y * 0.51
        var total: float = b * 3.0 + gap * 2.0
        var x: float = center - total * 0.5
        _native_undo_button.position = Vector2(x, y)
        _native_round_prev.position = Vector2(x + b + gap, y)
        _native_round_next.position = Vector2(x + 2.0 * (b + gap), y)
        for item in [_native_undo_button, _native_round_prev, _native_round_next]:
            item.size = Vector2(b, 44.0)
            item.add_theme_font_size_override("font_size", 29)
        _native_round_number.position = Vector2(center - 39.0, pane.position.y + 9.0)
        _native_round_number.size = Vector2(78.0, 29.0)
    else:
        var b_h: float = clampf(pane.size.y * 0.21, 38.0, 62.0)
        _native_undo_button.size = Vector2(minf(115.0, pane.size.x - 2.0 * inset), b_h)
        _native_undo_button.position = Vector2(center - _native_undo_button.size.x * 0.5,
                pane.position.y + pane.size.y * 0.32 - b_h * 0.5)
        _native_undo_button.add_theme_font_size_override("font_size", 33)
        var gap: float = clampf(pane.size.x * 0.06, 5.0, 12.0)
        var b_w: float = minf(65.0, (pane.size.x - 2.0 * inset - gap) * 0.5)
        var y: float = pane.position.y + pane.size.y * 0.61 - b_h * 0.5
        _native_round_prev.position = Vector2(center - gap * 0.5 - b_w, y)
        _native_round_next.position = Vector2(center + gap * 0.5, y)
        for item in [_native_round_prev, _native_round_next]:
            item.size = Vector2(b_w, b_h)
            item.add_theme_font_size_override("font_size", 36)
        _native_round_number.position = Vector2(center - 45.0,
                pane.position.y + pane.size.y * 0.82 - 13.0)
        _native_round_number.size = Vector2(90.0, 26.0)
    _native_round_number.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    _native_round_number.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
    _native_round_number.add_theme_color_override("font_color", V6_UI_KIT.PAPER)
    _native_round_number.add_theme_font_size_override("font_size", 18)


func _shared_layout_chips() -> void:
    if chip_strip == null or chips.is_empty():
        return
    var words: Array = chips.keys()
    var count: int = words.size()
    var tray_w: float = chip_strip.size.x
    var tray_h: float = chip_strip.size.y
    if tray_w < 80.0 or tray_h < 40.0:
        return
    var padding: float = clampf(tray_w * 0.014, 8.0, 22.0)
    var gap: float = clampf(tray_w * 0.011, 6.0, 18.0)
    var single_width: float = (tray_w - 2.0 * padding - float(count - 1) * gap) / float(count)
    # On genuinely narrow portrait screens use a centered two-row layout.
    # Game remains landscape-first as specified in the main project.
    var rows: int = 2 if single_width < 112.0 and count >= 4 else 1
    var columns: int = ceili(float(count) / float(rows))
    var width: float = (tray_w - 2.0 * padding - float(columns - 1) * gap) / float(columns)
    var vertical_pad: float = 8.0 if rows == 2 else clampf(tray_h * 0.095, 8.0, 18.0)
    var vertical_gap: float = 6.0 if rows == 2 else 0.0
    var height: float = maxf(32.0, (tray_h - 2.0 * vertical_pad - vertical_gap * float(rows - 1)) / float(rows))
    for i in range(count):
        var card: Button = chips[words[i]] as Button
        if card == null:
            continue
        var row_idx: int = floori(float(i) / float(columns))
        var col_idx: int = i % columns
        var n_in_row: int = mini(columns, count - row_idx * columns)
        var row_width: float = float(n_in_row) * width + float(n_in_row - 1) * gap
        var start_x: float = (tray_w - row_width) * 0.5
        card.position = Vector2(start_x + float(col_idx) * (width + gap),
                vertical_pad + float(row_idx) * (height + vertical_gap))
        card.size = Vector2(width, height)
        var text_length: int = maxi(1, card.text.length())
        var by_width: float = (width - 17.0) / maxf(1.0, float(text_length) * 0.56)
        var chosen_font: int = clampi(roundi(minf(height * 0.36, by_width)), 11, 32)
        card.add_theme_font_size_override("font_size", chosen_font)


func _update_language() -> void:
    super._update_language()
    var locale: String = "en"
    if language_index >= 0 and language_index < languages.size():
        locale = str(languages[language_index].get("code", "en"))
    var captions: Array = V6_TOOL_TIPS.get(locale, V6_TOOL_TIPS["en"])
    if _native_undo_button != null:
        _native_undo_button.tooltip_text = str(captions[0])
    if _native_round_prev != null:
        _native_round_prev.tooltip_text = str(captions[1])
    if _native_round_next != null:
        _native_round_next.tooltip_text = str(captions[2])


func _begin_chip_press(key: String, point: Vector2) -> void:
    super._begin_chip_press(key, point)
    _v6_speak_preposition(key)


func _try_place(key: String, destination: String) -> void:
    var valid: bool = (key == destination and not bool(solved.get(destination, false)))
    super._try_place(key, destination)
    if valid and bool(solved.get(key, false)):
        # A long drag deserves another pronunciation. A quick drop keeps the
        # single spoken word heard on selection, avoiding voice stutter.
        _v6_speak_preposition(key)


func _v6_speak_preposition(key: String) -> void:
    if not active_keys.has(key):
        return
    var speech: Node = get_node_or_null("/root/MikaVoice")
    if speech == null or not speech.has_method("speak_text"):
        return
    var now: int = Time.get_ticks_msec()
    if key == _v6_last_word and now - _v6_last_spoken_ms < 1250:
        return
    var locale: String = "en"
    if language_index >= 0 and language_index < languages.size():
        locale = str(languages[language_index].get("code", "en"))
    if locale == "pt":
        locale = "pt_BR"
    # The project's existing system-TTS service chooses an available local
    # voice, respects its enabled/volume settings, and supports all six locales.
    var success: bool = bool(speech.call("speak_text", _word(key).to_lower(), locale, "tablet"))
    if success:
        _v6_last_word = key
        _v6_last_spoken_ms = now


func _native_voice(correct: bool) -> void:
    # Keep KTS praise/retry; allow time for pronunciation before praise starts.
    var audio: Node = get_node_or_null("/root/SFX")
    if audio == null:
        return
    var position: Vector2 = get_viewport_rect().size * 0.5
    if correct and audio.has_method("play_praise"):
        audio.call("play_praise", position, 1.65)
    elif not correct and audio.has_method("play_retry"):
        audio.call("play_retry", position, 0.18)
