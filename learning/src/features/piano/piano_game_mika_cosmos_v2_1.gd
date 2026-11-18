extends "res://learning/src/features/piano/piano_game.gd"
## MIKA Piano v2.1 • presentation-only adaptation of the original PlayTown piano.
## Original songs, audio, key hit boxes, guided mode and free play are inherited.
## Godot 4.7.1; uses project-native space and native MIKA shared header.

const MIKA_TOOLBAR := preload("res://simulator_ui/scripts/mika_shared_tracing_toolbar_v2.gd")
const MIKA_HUD := preload("res://planet_hub/scripts/bottom_hud.gd")
const MIKA_BACK_GLYPH := preload("res://simulator_ui/back_arrow_glyph.gd")
const MIKA_SPACE := preload("res://simulator_ui/scripts/real_space_background.gd")

const MIKA_CAPTIONS := {
    "ru": ["ПИАНИНО", "Выбери мелодию, слушай и учись"],
    "en": ["PIANO", "Choose a melody, listen and learn"],
    "pt": ["PIANO", "Escolha uma melodia, ouça e aprenda"],
    "es": ["PIANO", "Elige una melodía, escucha y aprende"],
    "fr": ["PIANO", "Choisis une mélodie, écoute et apprends"],
    "de": ["KLAVIER", "Wähle eine Melodie, höre zu und lerne"]
}

var _mika_canvas: ColorRect
var _mika_stage: Panel
var _mika_sky: Control
var _mika_sky_tint: ColorRect
var _mika_toolbar_layer: CanvasLayer
var _mika_toolbar_root: Control
var _mika_back: Button
var _mika_counter: Control
var _mika_title_panel: Panel
var _mika_title: Label
var _mika_subtitle: Label
var _mika_stage_rect: Rect2 = Rect2()


func _ready() -> void:
    # _layout is virtual. During the original _ready(), it falls back to the
    # original geometry; after construction we switch to the responsive layout.
    super._ready()
    if exit_button != null:
        exit_button.hide()
        exit_button.mouse_filter = Control.MOUSE_FILTER_IGNORE
        exit_button.focus_mode = Control.FOCUS_NONE
    background.hide()
    tint.hide()
    _build_mika_space()
    _build_mika_toolbar()
    _style_mika_existing_ui()
    var mobile: Node = get_node_or_null("/root/MobileLocale")
    if mobile != null and mobile.has_signal("language_changed"):
        if not mobile.is_connected("language_changed", Callable(self, "_on_mika_locale_changed")):
            mobile.connect("language_changed", Callable(self, "_on_mika_locale_changed"))
    _on_mika_locale_changed("")
    _layout()


func _build_mika_space() -> void:
    _mika_canvas = ColorRect.new()
    _mika_canvas.name = "MikaPianoDeepSpaceOutsideStage"
    _mika_canvas.color = Color("#030b1b")
    _mika_canvas.z_index = -24
    _mika_canvas.mouse_filter = Control.MOUSE_FILTER_IGNORE
    add_child(_mika_canvas)

    _mika_stage = Panel.new()
    _mika_stage.name = "MikaPianoOneSafeAreaCosmicStage"
    _mika_stage.z_index = -14
    _mika_stage.mouse_filter = Control.MOUSE_FILTER_IGNORE
    _mika_stage.clip_contents = true
    _mika_stage.add_theme_stylebox_override("panel", _mika_panel_skin(Color("#050e25"), Color("#57cfff"), 30, 2, 11))
    add_child(_mika_stage)

    # Reuse the actual procedural flight nebulae, not a substitute image.
    _mika_sky = MIKA_SPACE.new() as Control
    _mika_sky.name = "MikaPianoOriginalFlightSpaceNebulae"
    _mika_sky.mouse_filter = Control.MOUSE_FILTER_IGNORE
    _mika_sky.modulate = Color(0.72, 0.82, 1.0, 0.83)
    _mika_stage.add_child(_mika_sky)
    _mika_sky.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

    _mika_sky_tint = ColorRect.new()
    _mika_sky_tint.name = "MikaPianoGentleStarfieldContrast"
    _mika_sky_tint.color = Color(0.002, 0.008, 0.022, 0.35)
    _mika_sky_tint.mouse_filter = Control.MOUSE_FILTER_IGNORE
    _mika_stage.add_child(_mika_sky_tint)
    _mika_sky_tint.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)


func _build_mika_toolbar() -> void:
    _mika_toolbar_layer = CanvasLayer.new()
    _mika_toolbar_layer.name = "MikaPianoSharedGameHeader"
    _mika_toolbar_layer.layer = 2
    add_child(_mika_toolbar_layer)
    _mika_toolbar_root = Control.new()
    _mika_toolbar_root.name = "MikaPianoHeaderLayout"
    _mika_toolbar_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
    _mika_toolbar_root.size = get_viewport_rect().size
    _mika_toolbar_layer.add_child(_mika_toolbar_root)

    _mika_back = Button.new()
    _mika_back.name = "MikaPianoNativeBack"
    _mika_back.text = ""
    _mika_back.focus_mode = Control.FOCUS_NONE
    _mika_back.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
    _mika_back.add_theme_stylebox_override("normal", _mika_panel_skin(Color("#061c38"), Color("#26dfff"), 22, 2, 5))
    _mika_back.add_theme_stylebox_override("hover", _mika_panel_skin(Color("#113a60"), Color("#65e7ff"), 22, 2, 6))
    _mika_back.add_theme_stylebox_override("pressed", _mika_panel_skin(Color("#143752"), Color("#a4f1ff"), 22, 2, 4))
    _mika_back.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
    _mika_back.pressed.connect(_on_mika_back_pressed)
    _mika_toolbar_root.add_child(_mika_back)
    var glyph: Control = MIKA_BACK_GLYPH.new() as Control
    glyph.name = "OriginalMikaBackArrow"
    glyph.mouse_filter = Control.MOUSE_FILTER_IGNORE
    _mika_back.add_child(glyph)
    glyph.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

    _mika_counter = MIKA_HUD.new() as Control
    _mika_counter.name = "MikaPianoOriginalPlanetHubCrystalCounter"
    _mika_counter.size = Vector2(1680.0, 158.0)
    _mika_counter.mouse_filter = Control.MOUSE_FILTER_IGNORE
    _mika_toolbar_root.add_child(_mika_counter)
    var sim: Control = _mika_counter.get_node_or_null("SimulatorButton") as Control
    var launch: Control = _mika_counter.get_node_or_null("LaunchButton") as Control
    if sim != null:
        sim.hide()
    if launch != null:
        launch.hide()
    # UI-only task: do not award game currency or show a fabricated score.
    _mika_counter.set("crystal_count", 0)

    _mika_title_panel = Panel.new()
    _mika_title_panel.name = "MikaPianoSharedTitlePlaque"
    _mika_title_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
    MIKA_TOOLBAR.apply_title_style(_mika_title_panel)
    _mika_toolbar_root.add_child(_mika_title_panel)
    _mika_title = _mika_label(Color("#f0fcff"))
    _mika_subtitle = _mika_label(Color("#b7e7fa"))
    _mika_title_panel.add_child(_mika_title)
    _mika_title_panel.add_child(_mika_subtitle)


func _style_mika_existing_ui() -> void:
    keyboard_panel.add_theme_stylebox_override("panel", _mika_panel_skin(Color(0.019, 0.06, 0.125, 0.96), Color("#4bdcff"), 26, 3, 12))
    side_panel.add_theme_stylebox_override("panel", _mika_panel_skin(Color(0.014, 0.046, 0.112, 0.96), Color("#6edbff"), 24, 2, 7))
    _style_selector(song_selector)
    _style_action_button(listen_button, Color("#8b5bd1"))
    _style_action_button(learn_button, Color("#55ae54"))
    music_label.text = "♪   ♫   ♪"
    music_label.add_theme_color_override("font_color", Color("#68d6ff"))
    music_label.add_theme_color_override("font_outline_color", Color("#06172d"))
    music_label.add_theme_constant_override("outline_size", 4)
    note_label.add_theme_color_override("font_color", Color("#ffcf78"))
    note_label.add_theme_color_override("font_outline_color", Color("#06192f"))
    note_label.add_theme_constant_override("outline_size", 5)
    song_title.visible = true
    song_title.add_theme_color_override("font_color", Color("#9bdaef"))
    progress_label.add_theme_color_override("font_color", Color("#92f1d7"))
    mode_label.add_theme_color_override("font_color", Color("#b8daf0"))
    _refresh_lyrics()


func _mika_label(color: Color) -> Label:
    var label := Label.new()
    label.mouse_filter = Control.MOUSE_FILTER_IGNORE
    label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
    label.clip_text = true
    label.add_theme_color_override("font_color", color)
    label.add_theme_color_override("font_outline_color", Color("#07162c"))
    label.add_theme_constant_override("outline_size", 2)
    return label


func _mika_panel_skin(fill: Color, outline: Color, radius: int, stroke: int, shadow: int) -> StyleBoxFlat:
    var style := StyleBoxFlat.new()
    style.anti_aliasing = true
    style.bg_color = fill
    style.border_color = outline
    style.set_border_width_all(stroke)
    style.set_corner_radius_all(radius)
    style.shadow_color = Color(0.06, 0.49, 0.88, 0.30)
    style.shadow_size = shadow
    style.shadow_offset = Vector2.ZERO
    return style


func _style_selector(selector: OptionButton) -> void:
    if selector == null:
        return
    for state in ["normal", "hover", "pressed", "disabled"]:
        var fill := Color("#0a2847") if state != "pressed" else Color("#165076")
        var outline := Color("#5599c3") if state != "hover" else Color("#7feaff")
        var s := _mika_panel_skin(fill, outline, 16, 2, 3)
        s.content_margin_left = 14.0
        s.content_margin_right = 33.0
        selector.add_theme_stylebox_override(state, s)
    for key in ["font_color", "font_hover_color", "font_pressed_color", "font_disabled_color"]:
        selector.add_theme_color_override(key, Color("#e7faff"))
    _style_song_popup(selector.get_popup())


func _style_song_popup(popup: PopupMenu) -> void:
    if popup == null:
        return
    popup.transparent_bg = true
    for key in ["font_color", "font_hover_color", "font_pressed_color"]:
        popup.add_theme_color_override(key, Color("#e5f9ff"))
    popup.add_theme_color_override("font_outline_color", Color("#030c20"))
    popup.add_theme_constant_override("outline_size", 2)
    popup.add_theme_constant_override("item_start_padding", 16)
    popup.add_theme_constant_override("item_end_padding", 16)
    var panel := _mika_panel_skin(Color("#09213b"), Color("#54daff"), 18, 2, 8)
    panel.content_margin_left = 10.0
    panel.content_margin_right = 10.0
    panel.content_margin_top = 10.0
    panel.content_margin_bottom = 10.0
    popup.add_theme_stylebox_override("panel", panel)
    var hover := _mika_panel_skin(Color("#17486b"), Color("#77ecff"), 12, 1, 0)
    hover.content_margin_left = 6.0
    hover.content_margin_right = 6.0
    popup.add_theme_stylebox_override("hover", hover)
    var separator := StyleBoxLine.new()
    separator.color = Color("#3f6f8b")
    separator.thickness = 1
    popup.add_theme_stylebox_override("separator", separator)


func _style_action_button(button: Button, color: Color) -> void:
    if button == null:
        return
    var accent := Color("#6acfff") if color.b > color.g else Color("#82eac9")
    for state in ["normal", "hover", "pressed", "disabled"]:
        var fill := Color("#0d3452") if state != "pressed" else Color("#195577")
        if state == "hover":
            fill = Color("#144365")
        button.add_theme_stylebox_override(state, _mika_panel_skin(fill, accent, 16, 2, 3))
    button.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
    for key in ["font_color", "font_hover_color", "font_pressed_color", "font_disabled_color"]:
        button.add_theme_color_override(key, Color("#f2fcff"))


func _refresh_lyrics() -> void:
    # Only the palette changes. Phrases, syllables and timing remain inherited.
    if lyrics_label == null:
        return
    var size_main := maxi(12, lyric_font_size)
    var size_syllable := roundi(float(size_main) * 1.16)
    var shown := "[center][color=#e2faff][font_size=%d]%s[/font_size][/color]" % [size_main, current_line]
    if not current_syllable.is_empty():
        shown += "\n[color=#ffd27d][font_size=%d][b]%s[/b][/font_size][/color]" % [size_syllable, current_syllable]
    shown += "[/center]"
    lyrics_label.text = shown


func _on_mika_locale_changed(_locale: String) -> void:
    if _mika_title == null or _mika_subtitle == null:
        return
    var locale := _piano_locale()
    var captions: Array = MIKA_CAPTIONS.get(locale, MIKA_CAPTIONS["en"])
    _mika_title.text = captions[0]
    _mika_subtitle.text = captions[1]
    _mika_back.tooltip_text = captions[0]
    song_title.text = _text("song").to_upper()
    for i in range(mini(song_selector.item_count, songs.size())):
        song_selector.set_item_text(i, "♫  %s" % _localized_song_title(songs[i]))
    if mode == PlayMode.FREE:
        _show_song_ready()
    _update_button_texts()
    _layout()


func _on_mika_back_pressed() -> void:
    _stop_playback()
    # While embedded in the ship's simulator, return to its original game cards.
    var parent: Node = get_parent()
    for i in range(20):
        if parent == null:
            break
        if parent.has_method("_return_to_cards"):
            parent.call("_return_to_cards")
            return
        parent = parent.get_parent()
    # Standalone PlayTown fallback: preserve the original scene transition.
    super._go_back()


func _layout() -> void:
    if _mika_stage == null:
        # Called from the original _ready() before the adapter is constructed.
        super._layout()
        return
    var view: Vector2 = get_viewport_rect().size
    if view.x < 100.0 or view.y < 100.0:
        return
    var insets: Vector4 = _safe_area_insets(view)
    var safe := Rect2(Vector2(insets.x, insets.y), view - Vector2(insets.x + insets.z, insets.y + insets.w))
    if safe.size.x < 80.0 or safe.size.y < 80.0:
        return
    _mika_canvas.position = Vector2.ZERO
    _mika_canvas.size = view
    _mika_toolbar_root.size = view
    var header_end := MIKA_TOOLBAR.relayout(view, safe, _mika_back, _mika_counter, _mika_title_panel, _mika_title, _mika_subtitle)
    var edge := clampf(safe.size.x * 0.017, 7.0, 29.0)
    var gap_above := clampf(safe.size.y * 0.018, 5.0, 22.0)
    var lower_margin := clampf(safe.size.y * 0.018, 6.0, 25.0)
    var top := maxf(safe.position.y + 58.0, header_end + gap_above)
    var stage_w := safe.size.x - 2.0 * edge
    # The stage must never extend below the logical safe-area bottom, even
    # when a device reports an unusually short usable height.
    var stage_h := maxf(1.0, safe.end.y - lower_margin - top)
    _mika_stage_rect = Rect2(safe.position + Vector2(edge, top - safe.position.y), Vector2(stage_w, stage_h))
    _mika_stage.position = _mika_stage_rect.position
    _mika_stage.size = _mika_stage_rect.size
    # Both children use PRESET_FULL_RECT. Their anchor system follows the
    # panel automatically: assigning size here conflicts with their anchors
    # and triggers Godot 4.7.1's 'non-equal opposite anchors' warning.

    var inner := clampf(minf(stage_w, stage_h) * 0.028, 7.0, 27.0)
    var content := _mika_stage_rect.grow(-inner)
    var compact := content.size.x < 600.0
    var row_h := clampf(content.size.y * (0.245 if compact else 0.178), 51.0 if not compact else 88.0, 125.0)
    row_h = minf(row_h, content.size.y * 0.36)
    side_panel.position = content.position
    side_panel.size = Vector2(content.size.x, row_h)
    var ui_scale := minf(view.x / 1280.0, view.y / 720.0)
    _layout_side_panel(ui_scale)

    var between := clampf(content.size.y * 0.020, 5.0, 21.0)
    var text_h := clampf(content.size.y * 0.19, 28.0, 140.0)
    var room_keyboard := content.size.y - row_h - text_h - between * 2.0
    var key_h := minf(content.size.y * 0.575, content.size.x / 8.0 * 2.40)
    key_h = minf(key_h, room_keyboard)
    key_h = maxf(45.0, key_h)
    var key_y := content.end.y - key_h
    keyboard_panel.position = Vector2(content.position.x, key_y)
    keyboard_panel.size = Vector2(content.size.x, key_h)
    var key_padding := clampf(key_h * 0.048, 5.0, 22.0)
    keyboard.position = Vector2.ONE * key_padding
    keyboard.size = keyboard_panel.size - Vector2.ONE * key_padding * 2.0

    var lyric_top := content.position.y + row_h + between
    var lyric_bottom := key_y - between
    var lyric_h := maxf(16.0, lyric_bottom - lyric_top)
    lyrics_label.position = Vector2(content.position.x + content.size.x * 0.16, lyric_top)
    lyrics_label.size = Vector2(content.size.x * 0.68, lyric_h)
    lyric_font_size = int(clampf(33.0 * ui_scale, 14.0, 42.0))
    _refresh_lyrics()

    music_label.position = Vector2(content.position.x + content.size.x * 0.03, lyric_top)
    music_label.size = Vector2(content.size.x * 0.11, lyric_h)
    music_label.add_theme_font_size_override("font_size", int(clampf(27.0 * ui_scale, 13.0, 42.0)))
    music_label.modulate.a = 0.55
    note_label.position = Vector2(content.end.x - content.size.x * 0.16, lyric_top)
    note_label.size = Vector2(content.size.x * 0.13, lyric_h)
    note_label.add_theme_font_size_override("font_size", int(clampf(54.0 * ui_scale, 21.0, 74.0)))


func _layout_side_panel(scale_factor: float) -> void:
    if _mika_stage == null:
        super._layout_side_panel(scale_factor)
        return
    var w := side_panel.size.x
    var h := side_panel.size.y
    if w <= 1.0 or h <= 1.0:
        return
    var pad := clampf(h * 0.12, 5.0, 15.0)
    var gap := clampf(w * 0.010, 5.0, 14.0)
    var usable := w - pad * 2.0
    var line_h := clampf(h * 0.53, 26.0, 62.0)
    line_h = minf(line_h, h - pad * 1.7)
    var status_y := pad + line_h + 2.0
    var status_h := maxf(12.0, h - status_y - 3.0)
    var text_sz := maxi(10, roundi(clampf(19.0 * scale_factor, 11.0, 26.0)))
    var small_sz := maxi(9, roundi(clampf(16.0 * scale_factor, 10.0, 21.0)))

    if usable >= 580.0:
        song_title.visible = true
        var title_w := clampf(usable * 0.10, 54.0, 100.0)
        var selector_w := usable * 0.45
        var buttons_w := maxf(85.0, (usable - title_w - selector_w - gap * 3.0) * 0.5)
        song_title.position = Vector2(pad, pad)
        song_title.size = Vector2(title_w, line_h)
        song_selector.position = Vector2(pad + title_w + gap, pad)
        song_selector.size = Vector2(selector_w, line_h)
        var button_x := song_selector.position.x + selector_w + gap
        listen_button.position = Vector2(button_x, pad)
        listen_button.size = Vector2(buttons_w, line_h)
        learn_button.position = Vector2(button_x + buttons_w + gap, pad)
        learn_button.size = Vector2(buttons_w, line_h)
    else:
        song_title.visible = false
        song_selector.position = Vector2(pad, pad)
        song_selector.size = Vector2(usable * 0.45, line_h)
        var button_start := song_selector.position.x + song_selector.size.x + gap
        var action_w := maxf(28.0, (usable - song_selector.size.x - gap * 2.0) * 0.5)
        listen_button.position = Vector2(button_start, pad)
        listen_button.size = Vector2(action_w, line_h)
        learn_button.position = Vector2(button_start + action_w + gap, pad)
        learn_button.size = Vector2(action_w, line_h)

    song_title.add_theme_font_size_override("font_size", small_sz)
    song_selector.add_theme_font_size_override("font_size", text_sz)
    listen_button.add_theme_font_size_override("font_size", text_sz)
    learn_button.add_theme_font_size_override("font_size", text_sz)
    var popup: PopupMenu = song_selector.get_popup()
    popup.add_theme_font_size_override("font_size", maxi(13, roundi(text_sz * 1.05)))
    popup.add_theme_constant_override("v_separation", maxi(7, roundi(9.0 * scale_factor)))
    popup.min_size = Vector2(maxf(180.0, song_selector.size.x), 0.0)
    progress_label.position = Vector2(pad + 1.0, status_y)
    progress_label.size = Vector2(usable * 0.16, status_h)
    progress_label.add_theme_font_size_override("font_size", small_sz)
    mode_label.position = Vector2(pad + usable * 0.17, status_y)
    mode_label.size = Vector2(usable * 0.81, status_h)
    mode_label.add_theme_font_size_override("font_size", small_sz)
