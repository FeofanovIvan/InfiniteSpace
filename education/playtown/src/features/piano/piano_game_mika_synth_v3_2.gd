extends "res://education/playtown/src/features/piano/piano_game_mika_cosmos_v2_1.gd"
## MIKA Piano v3.2: refined mini-synth cabinet with lighter body styling and
## scrollable LCD song browser. The original PianoGame data, sounds, keyboard
## hit areas, Listen/Learn mechanics and song library remain unchanged.
## Godot 4.7.1.

const SYNTH_CAPTIONS := {
    "ru": {"browse":"ВЫБРАТЬ", "melodies":"МЕЛОДИИ", "display":"ЭКРАН МЕЛОДИИ", "scroll":"ПРОКРУТИ И ВЫБЕРИ", "track":"МЕЛОДИЯ", "controls":"УПРАВЛЕНИЕ", "model":"МИКА  /  КОСМИЧЕСКИЙ СИНТЕЗАТОР"},
    "en": {"browse":"SELECT", "melodies":"MELODIES", "display":"MELODY DISPLAY", "scroll":"SCROLL AND SELECT", "track":"SONG", "controls":"CONTROLS", "model":"MIKA  /  COSMIC SYNTHESIZER"},
    "pt": {"browse":"ESCOLHER", "melodies":"MELODIAS", "display":"TELA DA MELODIA", "scroll":"ROLE E ESCOLHA", "track":"MÚSICA", "controls":"CONTROLES", "model":"MIKA  /  SINTETIZADOR CÓSMICO"},
    "es": {"browse":"ELEGIR", "melodies":"MELODÍAS", "display":"PANTALLA DE MELODÍA", "scroll":"DESLIZA Y ELIGE", "track":"CANCIÓN", "controls":"CONTROLES", "model":"MIKA  /  SINTETIZADOR CÓSMICO"},
    "fr": {"browse":"CHOISIR", "melodies":"MÉLODIES", "display":"ÉCRAN DE MÉLODIE", "scroll":"FAIS DÉFILER ET CHOISIS", "track":"CHANSON", "controls":"COMMANDES", "model":"MIKA  /  SYNTHÉTISEUR COSMIQUE"},
    "de": {"browse":"WÄHLEN", "melodies":"MELODIEN", "display":"MELODIEANZEIGE", "scroll":"SCROLLE UND WÄHLE", "track":"LIED", "controls":"STEUERUNG", "model":"MIKA  /  KOSMISCHER SYNTHESIZER"}
}

var _synth_cabinet: Panel
var _synth_case_ridge: ColorRect
var _synth_bezel: Panel
var _synth_well: Panel
var _synth_glass: Panel
var _synth_glare: ColorRect
var _synth_scanlines: Array[ColorRect] = []
var _synth_screen_heading: Label
var _synth_screen_track: Label
var _synth_screen_hint: Label
var _synth_status_led: Label
var _synth_note_strip: RichTextLabel
var _synth_song_scroll: ScrollContainer
var _synth_song_rows: VBoxContainer
var _synth_song_buttons: Array[Button] = []
var _synth_browse_button: Button
var _synth_model_label: Label
var _synth_control_caption: Label
var _synth_keyboard_rail: ColorRect
var _synth_browser_open: bool = false
var _synth_ready: bool = false
var _synth_scroll_dragging: bool = false


func _ready() -> void:
    # Parent builds the original functioning piano + its standard shared header.
    super._ready()
    # Simulator already renders its native Back. Hide ONLY the Piano duplicate.
    # In standalone PlayTown, retain the Piano back as a usable fallback.
    var host: Node = get_parent()
    var embedded: bool = false
    for _i in range(22):
        if host == null:
            break
        if host.has_method("_return_to_cards"):
            embedded = true
            break
        host = host.get_parent()
    if embedded and _mika_back != null:
        _mika_back.hide()
        _mika_back.mouse_filter = Control.MOUSE_FILTER_IGNORE
    # The original PlayTown exit button was hidden by v2.1 and stays hidden.
    # A restrained cosmic atmosphere remains visible around the synth cabinet.
    _mika_stage.add_theme_stylebox_override("panel", _mika_panel_skin(Color("#12153a"), Color("#72e6ff"), 28, 3, 12))
    _mika_sky.modulate = Color(0.80, 0.84, 1.0, 0.22)
    _mika_sky_tint.color = Color(0.08, 0.05, 0.16, 0.54)
    _build_synth_hardware()
    _style_synth_controls()
    _synth_ready = true
    _refresh_synth_locale()
    _show_synth_browser(false)
    _layout()


func _build_synth_hardware() -> void:
    _synth_cabinet = Panel.new()
    _synth_cabinet.name = "WholeMiniSynthCabinet"
    _synth_cabinet.z_index = -9
    _synth_cabinet.mouse_filter = Control.MOUSE_FILTER_IGNORE
    _synth_cabinet.add_theme_stylebox_override("panel", _mika_panel_skin(Color("#403787"), Color("#90f1ff"), 30, 4, 16))
    add_child(_synth_cabinet)

    _synth_case_ridge = ColorRect.new()
    _synth_case_ridge.name = "SynthUpperAccentRidge"
    _synth_case_ridge.color = Color(0.74, 0.94, 1.0, 0.20)
    _synth_case_ridge.mouse_filter = Control.MOUSE_FILTER_IGNORE
    add_child(_synth_case_ridge)

    # Physical inset display: bezel > recessed dark well > blue-grey glass.
    _synth_bezel = Panel.new()
    _synth_bezel.name = "MikaSynthInsetDisplayBezel"
    _synth_bezel.z_index = -3
    _synth_bezel.mouse_filter = Control.MOUSE_FILTER_IGNORE
    _synth_bezel.add_theme_stylebox_override("panel", _mika_panel_skin(Color("#071526"), Color("#416d88"), 20, 4, 6))
    add_child(_synth_bezel)

    _synth_well = Panel.new()
    _synth_well.name = "RecessedLCDDarkWell"
    _synth_well.mouse_filter = Control.MOUSE_FILTER_IGNORE
    _synth_well.add_theme_stylebox_override("panel", _mika_panel_skin(Color("#030e1a"), Color("#1a4158"), 13, 3, 1))
    _synth_bezel.add_child(_synth_well)

    _synth_glass = Panel.new()
    _synth_glass.name = "BlueGreySongLCD"
    _synth_glass.mouse_filter = Control.MOUSE_FILTER_IGNORE
    _synth_glass.clip_contents = true
    var glass_skin: StyleBoxFlat = _mika_panel_skin(Color("#b7d7df"), Color("#86c9da"), 9, 2, 0)
    glass_skin.shadow_color = Color(0.0, 0.08, 0.16, 0.0)
    _synth_glass.add_theme_stylebox_override("panel", glass_skin)
    _synth_well.add_child(_synth_glass)

    _synth_glare = ColorRect.new()
    _synth_glare.name = "LCDGlassSoftReflection"
    _synth_glare.color = Color(1.0, 1.0, 1.0, 0.14)
    _synth_glare.mouse_filter = Control.MOUSE_FILTER_IGNORE
    _synth_glass.add_child(_synth_glare)
    # Understated horizontal scan-lines: subtle physical-display texture.
    for i in range(13):
        var scan := ColorRect.new()
        scan.name = "LCDScanline_%02d" % i
        scan.color = Color(0.13, 0.29, 0.35, 0.035)
        scan.mouse_filter = Control.MOUSE_FILTER_IGNORE
        _synth_glass.add_child(scan)
        _synth_scanlines.append(scan)

    _synth_screen_heading = _synth_label(Color("#21516b"))
    _synth_screen_heading.name = "LCDModeTitle"
    add_child(_synth_screen_heading)
    _synth_screen_track = _synth_label(Color("#254b64"))
    _synth_screen_track.name = "LCDSongTitle"
    add_child(_synth_screen_track)
    _synth_screen_hint = _synth_label(Color("#356278"))
    _synth_screen_hint.name = "LCDHint"
    add_child(_synth_screen_hint)
    _synth_status_led = _synth_label(Color("#0f8a72"))
    _synth_status_led.name = "SynthReadyIndicator"
    _synth_status_led.text = "●"
    add_child(_synth_status_led)
    # Small score strip on the LCD: note names come from the ORIGINAL song data.
    _synth_note_strip = RichTextLabel.new()
    _synth_note_strip.name = "LCDOriginalMelodyNotes"
    _synth_note_strip.bbcode_enabled = true
    _synth_note_strip.fit_content = false
    _synth_note_strip.scroll_active = false
    _synth_note_strip.mouse_filter = Control.MOUSE_FILTER_IGNORE
    add_child(_synth_note_strip)

    _synth_song_scroll = ScrollContainer.new()
    _synth_song_scroll.name = "LCDScrollableSongLibrary"
    _synth_song_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
    _synth_song_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_SHOW_NEVER
    _synth_song_scroll.gui_input.connect(_on_song_browser_gui_input)
    _synth_song_scroll.follow_focus = false
    _synth_song_scroll.clip_contents = true
    _synth_song_scroll.mouse_filter = Control.MOUSE_FILTER_STOP
    _synth_song_scroll.visible = false
    add_child(_synth_song_scroll)
    _synth_song_rows = VBoxContainer.new()
    _synth_song_rows.name = "MelodySelectionRows"
    _synth_song_rows.add_theme_constant_override("separation", 5)
    _synth_song_rows.mouse_filter = Control.MOUSE_FILTER_PASS
    _synth_song_scroll.add_child(_synth_song_rows)
    for index in range(songs.size()):
        var button := Button.new()
        button.name = "Song_%02d" % index
        button.focus_mode = Control.FOCUS_NONE
        button.alignment = HORIZONTAL_ALIGNMENT_LEFT
        button.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
        button.mouse_filter = Control.MOUSE_FILTER_STOP
        button.gui_input.connect(_on_song_button_gui_input.bind(index))
        button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        button.pressed.connect(_select_synth_song.bind(index))
        _synth_song_rows.add_child(button)
        _synth_song_buttons.append(button)

    _synth_browse_button = Button.new()
    _synth_browse_button.name = "SelectMelodyOnLCD"
    _synth_browse_button.focus_mode = Control.FOCUS_NONE
    _synth_browse_button.pressed.connect(_on_synth_browse_pressed)
    side_panel.add_child(_synth_browse_button)
    _synth_model_label = _synth_label(Color("#9edcf5"))
    _synth_model_label.name = "OriginalMIKASynthBrand"
    _synth_model_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
    side_panel.add_child(_synth_model_label)
    _synth_control_caption = _synth_label(Color("#65d9f3"))
    _synth_control_caption.name = "SynthSongControlCaption"
    _synth_control_caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
    side_panel.add_child(_synth_control_caption)
    _synth_keyboard_rail = ColorRect.new()
    _synth_keyboard_rail.name = "SynthMetalDividerAboveKeys"
    _synth_keyboard_rail.color = Color(0.43, 0.86, 1.0, 0.57)
    _synth_keyboard_rail.mouse_filter = Control.MOUSE_FILTER_IGNORE
    add_child(_synth_keyboard_rail)


func _synth_label(color: Color) -> Label:
    var label := Label.new()
    label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
    label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
    label.clip_text = true
    label.mouse_filter = Control.MOUSE_FILTER_IGNORE
    label.add_theme_color_override("font_color", color)
    return label


func _style_synth_controls() -> void:
    # Retain the existing original keyboard; the case and keys are two materials.
    keyboard_panel.add_theme_stylebox_override("panel", _mika_panel_skin(Color("#251d62"), Color("#9cf3ff"), 22, 3, 7))
    side_panel.add_theme_stylebox_override("panel", _mika_panel_skin(Color("#203774"), Color("#7bdfff"), 20, 3, 7))
    _synth_browse_button.add_theme_stylebox_override("normal", _mika_panel_skin(Color("#6b56bb"), Color("#bdf7ff"), 15, 2, 2))
    _synth_browse_button.add_theme_stylebox_override("hover", _mika_panel_skin(Color("#7d68d3"), Color("#ecffff"), 15, 2, 3))
    _synth_browse_button.add_theme_stylebox_override("pressed", _mika_panel_skin(Color("#5644a8"), Color("#a8f3ff"), 15, 2, 1))
    _synth_browse_button.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
    _synth_browse_button.add_theme_color_override("font_color", Color("#f2ffff"))
    _synth_browse_button.add_theme_color_override("font_hover_color", Color("#ffffff"))
    _style_action_button(listen_button, Color("#46aef3"))
    _style_action_button(learn_button, Color("#59d1b6"))
    # The original selector is still populated and used internally by the game.
    # Its visible menu is replaced by a touch-friendly list on the LCD.
    song_selector.hide()
    song_selector.mouse_filter = Control.MOUSE_FILTER_IGNORE
    song_title.hide()
    music_label.add_theme_color_override("font_color", Color("#37677f"))
    music_label.add_theme_color_override("font_outline_color", Color("#b7d7df"))
    music_label.add_theme_constant_override("outline_size", 0)
    music_label.text = "♫"
    note_label.add_theme_color_override("font_color", Color("#17647a"))
    note_label.add_theme_color_override("font_outline_color", Color("#c1e6ed"))
    note_label.add_theme_constant_override("outline_size", 0)
    progress_label.add_theme_color_override("font_color", Color("#87f3d9"))
    mode_label.add_theme_color_override("font_color", Color("#b3dcef"))
    _refresh_lyrics()
    _refresh_synth_notes(0)


func _refresh_lyrics() -> void:
    if _synth_glass == null:
        super._refresh_lyrics()
        return
    var main_font: int = maxi(11, lyric_font_size)
    var syllable_font: int = roundi(float(main_font) * 1.14)
    var text_value := "[center][color=#204961][font_size=%d][b]%s[/b][/font_size][/color]" % [main_font, current_line]
    if not current_syllable.is_empty():
        text_value += "\n[color=#087c96][font_size=%d][b]%s[/b][/font_size][/color]" % [syllable_font, current_syllable]
    text_value += "[/center]"
    lyrics_label.text = text_value


func _refresh_synth_notes(highlight: int) -> void:
    # The LCD shows an excerpt of the real note sequence; NO synthesizer audio
    # or timings are recomputed. The current note is highlighted as it plays.
    if _synth_note_strip == null:
        return
    var events: Array = selected_song.get("events", [])
    if events.is_empty():
        _synth_note_strip.text = ""
        return
    var first: int = clampi(highlight - 2, 0, maxi(0, events.size() - 6))
    var last: int = mini(events.size(), first + 6)
    var fragments := PackedStringArray()
    for index in range(first, last):
        var event: Dictionary = events[index]
        var code: String = str(event.get("note", ""))
        var name: String = str(NOTE_DISPLAY.get(code, code))
        if index == highlight:
            fragments.append("[color=#007b97][b]❯ %s[/b][/color]" % name)
        else:
            fragments.append("[color=#4a7788]%s[/color]" % name)
    _synth_note_strip.text = "[center]" + "     ".join(fragments) + "[/center]"


func _show_event(event: Dictionary, progress: int) -> void:
    super._show_event(event, progress)
    _refresh_synth_notes(progress - 1)


func _show_song_ready() -> void:
    super._show_song_ready()
    _refresh_synth_notes(0)


func _stop_playback() -> void:
    super._stop_playback()
    _refresh_synth_notes(0)


func _on_mika_locale_changed(locale: String) -> void:
    super._on_mika_locale_changed(locale)
    if _synth_ready:
        _refresh_synth_locale()
        _layout()


func _synth_caption(key: String) -> String:
    var locale: String = _piano_locale()
    var group: Dictionary = SYNTH_CAPTIONS.get(locale, SYNTH_CAPTIONS["en"])
    return str(group.get(key, key))


func _refresh_synth_locale() -> void:
    if _synth_browse_button == null:
        return
    _synth_browse_button.text = "▤  " + _synth_caption("browse")
    _synth_browse_button.tooltip_text = _synth_caption("melodies")
    _synth_model_label.text = _synth_caption("model")
    _synth_control_caption.text = _synth_caption("controls")
    for i in range(_synth_song_buttons.size()):
        var song: Dictionary = songs[i]
        _synth_song_buttons[i].text = "%02d   %s" % [i + 1, _localized_song_title(song)]
    _refresh_synth_display()


func _refresh_synth_display() -> void:
    if _synth_screen_heading == null:
        return
    if _synth_browser_open:
        _synth_screen_heading.text = _synth_caption("melodies")
        _synth_screen_track.text = "%d  %s" % [songs.size(), _synth_caption("track")]
        _synth_screen_hint.text = _synth_caption("scroll")
    else:
        _synth_screen_heading.text = _synth_caption("display")
        _synth_screen_track.text = _localized_song_title(selected_song) if not selected_song.is_empty() else "MIKA"
        _synth_screen_hint.text = _synth_caption("track") + "  •  MIKA"
    var chosen: int = song_selector.selected
    for index in range(_synth_song_buttons.size()):
        var button: Button = _synth_song_buttons[index]
        var active: bool = index == chosen
        button.add_theme_stylebox_override("normal", _mika_panel_skin(Color("#80b6c5") if active else Color(0.76, 0.92, 0.96, 0.45), Color("#34748b") if active else Color(0.31, 0.51, 0.60, 0.26), 9, 1, 0))
        button.add_theme_stylebox_override("hover", _mika_panel_skin(Color("#9ecee0"), Color("#377c92"), 9, 1, 0))
        button.add_theme_stylebox_override("pressed", _mika_panel_skin(Color("#69a9c1"), Color("#245b76"), 9, 1, 0))
        for state in ["font_color", "font_hover_color", "font_pressed_color"]:
            button.add_theme_color_override(state, Color("#102f48"))


func _show_synth_browser(open_browser: bool) -> void:
    if _synth_song_scroll == null:
        return
    if open_browser and mode != PlayMode.FREE:
        _stop_playback()
    _synth_browser_open = open_browser
    _synth_song_scroll.visible = open_browser
    lyrics_label.visible = not open_browser
    music_label.visible = not open_browser
    note_label.visible = not open_browser
    _synth_note_strip.visible = not open_browser
    _refresh_synth_display()


func _on_synth_browse_pressed() -> void:
    _show_synth_browser(not _synth_browser_open)


func _select_synth_song(index: int) -> void:
    if index < 0 or index >= songs.size():
        return
    # Use the exact original song selection flow, changing no data or mechanics.
    song_selector.select(index)
    _on_song_selected(index)
    _show_synth_browser(false)


func _on_listen_pressed() -> void:
    if _synth_browser_open:
        _show_synth_browser(false)
    super._on_listen_pressed()


func _on_learn_pressed() -> void:
    if _synth_browser_open:
        _show_synth_browser(false)
    super._on_learn_pressed()




func _on_song_browser_gui_input(event: InputEvent) -> void:
    _handle_song_browser_input(event)


func _on_song_button_gui_input(event: InputEvent, _index: int) -> void:
    _handle_song_browser_input(event)


func _handle_song_browser_input(event: InputEvent) -> void:
    if _synth_song_scroll == null or not _synth_browser_open:
        return
    if event is InputEventMouseButton:
        if event.pressed and event.button_index == MOUSE_BUTTON_WHEEL_UP:
            _scroll_song_browser(-56.0)
            get_viewport().set_input_as_handled()
        elif event.pressed and event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
            _scroll_song_browser(56.0)
            get_viewport().set_input_as_handled()
        elif event.button_index == MOUSE_BUTTON_LEFT:
            _synth_scroll_dragging = event.pressed
            if not event.pressed:
                await get_tree().create_timer(0.02).timeout
                _synth_scroll_dragging = false
    elif event is InputEventMouseMotion and _synth_scroll_dragging and Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
        if absf(event.relative.y) > 0.1:
            _scroll_song_browser(-event.relative.y)
            get_viewport().set_input_as_handled()
    elif event is InputEventScreenTouch:
        _synth_scroll_dragging = event.pressed
        if not event.pressed:
            await get_tree().create_timer(0.02).timeout
            _synth_scroll_dragging = false
    elif event is InputEventScreenDrag:
        if absf(event.relative.y) > 0.1:
            _scroll_song_browser(-event.relative.y)
            get_viewport().set_input_as_handled()


func _scroll_song_browser(delta_y: float) -> void:
    if _synth_song_scroll == null:
        return
    _synth_song_scroll.scroll_vertical = maxi(0, _synth_song_scroll.scroll_vertical + roundi(delta_y))

func _layout() -> void:
    if _synth_bezel == null:
        # v2.1's _ready() and locale listener invoke this before our shell exists.
        super._layout()
        return
    super._layout()
    var view: Vector2 = get_viewport_rect().size
    if view.x < 100.0 or view.y < 100.0:
        return
    _layout_synth_shell(view)


func _layout_synth_shell(view: Vector2) -> void:
    # v2.1 has already confined its cosmic stage to the OS safe area.
    var stage: Rect2 = Rect2(_mika_stage.position, _mika_stage.size)
    if stage.size.x < 170.0 or stage.size.y < 110.0:
        return
    var inset: float = clampf(minf(stage.size.x, stage.size.y) * 0.028, 6.0, 22.0)
    var cabinet: Rect2 = stage.grow(-inset)
    _synth_cabinet.position = cabinet.position
    _synth_cabinet.size = cabinet.size
    _synth_case_ridge.position = cabinet.position + Vector2(cabinet.size.x * 0.04, cabinet.size.y * 0.072)
    _synth_case_ridge.size = Vector2(cabinet.size.x * 0.92, clampf(cabinet.size.y * 0.018, 2.0, 6.0))
    var inner_pad: float = clampf(minf(cabinet.size.x, cabinet.size.y) * 0.04, 8.0, 24.0)
    var content: Rect2 = cabinet.grow(-inner_pad)
    var gap: float = clampf(minf(content.size.x, content.size.y) * 0.025, 6.0, 18.0)
    var key_h: float = minf(content.size.y * 0.50, content.size.y - gap - 110.0)
    key_h = maxf(74.0, key_h)
    var top_h: float = maxf(42.0, content.size.y - key_h - gap)
    var left_ratio: float = 0.57
    var display_w: float = content.size.x * left_ratio
    display_w = minf(display_w, content.size.x - gap - 132.0)
    display_w = maxf(120.0, display_w)
    var controls_w: float = content.size.x - display_w - gap

    _synth_bezel.position = content.position
    _synth_bezel.size = Vector2(display_w, top_h)
    var bezel_inset: float = clampf(minf(display_w, top_h) * 0.049, 5.0, 14.0)
    _synth_well.position = Vector2.ONE * bezel_inset
    _synth_well.size = (_synth_bezel.size - Vector2.ONE * bezel_inset * 2.0).max(Vector2.ONE)
    var inner_inset: float = clampf(minf(_synth_well.size.x, _synth_well.size.y) * 0.038, 3.0, 8.0)
    _synth_glass.position = Vector2.ONE * inner_inset
    _synth_glass.size = (_synth_well.size - Vector2.ONE * inner_inset * 2.0).max(Vector2.ONE)
    _synth_glare.position = Vector2.ZERO
    _synth_glare.size = Vector2(_synth_glass.size.x, _synth_glass.size.y * 0.28)
    for i in range(_synth_scanlines.size()):
        var scan: ColorRect = _synth_scanlines[i]
        scan.position = Vector2(0.0, _synth_glass.size.y * float(i + 1) / 14.0)
        scan.size = Vector2(_synth_glass.size.x, 1.0)

    var display_p: Vector2 = _synth_bezel.position + _synth_well.position + _synth_glass.position
    var display_s: Vector2 = _synth_glass.size
    var screen_pad: float = clampf(minf(display_s.x, display_s.y) * 0.05, 6.0, 18.0)
    var screen_label_h: float = clampf(display_s.y * 0.16, 13.0, 31.0)
    var screen_font: int = maxi(10, roundi(clampf(display_s.y * 0.081, 10.0, 17.0)))
    _synth_screen_heading.position = display_p + Vector2(screen_pad, screen_pad * 0.40)
    _synth_screen_heading.size = Vector2(display_s.x * 0.62, screen_label_h)
    _synth_screen_heading.add_theme_font_size_override("font_size", screen_font)
    _synth_screen_track.position = display_p + Vector2(screen_pad, screen_label_h + screen_pad * 0.28)
    _synth_screen_track.size = Vector2(display_s.x - screen_pad * 2.0, screen_label_h)
    _synth_screen_track.add_theme_font_size_override("font_size", maxi(10, roundi(screen_font * 0.88)))
    _synth_status_led.position = display_p + Vector2(display_s.x - screen_pad - 20.0, screen_pad * 0.40)
    _synth_status_led.size = Vector2(16.0, screen_label_h)
    _synth_status_led.add_theme_font_size_override("font_size", maxi(11, roundi(screen_font * 1.12)))
    _synth_screen_hint.position = display_p + Vector2(screen_pad, display_s.y - screen_label_h - screen_pad * 0.55)
    _synth_screen_hint.size = Vector2(display_s.x - screen_pad * 2.0, screen_label_h)
    _synth_screen_hint.add_theme_font_size_override("font_size", maxi(9, roundi(screen_font * 0.82)))

    var text_top: float = display_p.y + screen_label_h * 2.15 + screen_pad
    var text_bottom: float = _synth_screen_hint.position.y - screen_pad * 0.28
    var text_h: float = maxf(20.0, text_bottom - text_top)
    lyrics_label.position = Vector2(display_p.x + display_s.x * 0.10, text_top)
    lyrics_label.size = Vector2(display_s.x * 0.80, text_h * 0.69)
    lyric_font_size = maxi(13, roundi(clampf(minf(display_s.x * 0.047, text_h * 0.36), 13.0, 38.0)))
    _refresh_lyrics()
    _synth_note_strip.position = Vector2(display_p.x + screen_pad, text_top + text_h * 0.70)
    _synth_note_strip.size = Vector2(display_s.x - screen_pad * 2.0, text_h * 0.29)
    _synth_note_strip.add_theme_font_size_override("normal_font_size", maxi(10, roundi(clampf(display_s.x * 0.028, 10.0, 18.0))))
    _synth_note_strip.visible = not _synth_browser_open and text_h >= 40.0
    music_label.position = Vector2(display_p.x + screen_pad, text_top)
    music_label.size = Vector2(display_s.x * 0.105, text_h)
    music_label.add_theme_font_size_override("font_size", maxi(16, roundi(clampf(text_h * 0.26, 16.0, 38.0))))
    note_label.position = Vector2(display_p.x + display_s.x * 0.83, text_top)
    note_label.size = Vector2(display_s.x * 0.14, text_h)
    note_label.add_theme_font_size_override("font_size", maxi(18, roundi(clampf(text_h * 0.40, 18.0, 56.0))))

    _synth_song_scroll.position = Vector2(display_p.x + screen_pad, text_top)
    _synth_song_scroll.size = Vector2(maxf(20.0, display_s.x - screen_pad * 2.0), text_h)
    _synth_song_rows.custom_minimum_size = Vector2(_synth_song_scroll.size.x - 3.0, 0.0)
    var row_h: float = clampf(text_h * 0.36, 25.0, 45.0)
    for button in _synth_song_buttons:
        button.custom_minimum_size = Vector2(0.0, row_h)
        button.add_theme_font_size_override("font_size", maxi(11, roundi(clampf(display_s.x * 0.034, 11.0, 19.0))))

    side_panel.position = Vector2(content.position.x + display_w + gap, content.position.y)
    side_panel.size = Vector2(controls_w, top_h)
    _layout_side_panel(minf(view.x / 1280.0, view.y / 720.0))

    keyboard_panel.position = Vector2(content.position.x, content.end.y - key_h)
    keyboard_panel.size = Vector2(content.size.x, key_h)
    var key_padding: float = clampf(key_h * 0.043, 5.0, 20.0)
    keyboard.position = Vector2.ONE * key_padding
    keyboard.size = (keyboard_panel.size - Vector2.ONE * key_padding * 2.0).max(Vector2(80.0, 45.0))
    _synth_keyboard_rail.position = Vector2(content.position.x + gap, keyboard_panel.position.y - maxf(2.0, gap * 0.45))
    _synth_keyboard_rail.size = Vector2(content.size.x - gap * 2.0, 2.0)


func _layout_side_panel(scale_factor: float) -> void:
    if _synth_browse_button == null:
        super._layout_side_panel(scale_factor)
        return
    var w: float = side_panel.size.x
    var h: float = side_panel.size.y
    if w < 40.0 or h < 40.0:
        return
    var pad: float = clampf(minf(w, h) * 0.07, 6.0, 18.0)
    var usable: float = w - pad * 2.0
    var gap: float = clampf(h * 0.035, 3.0, 9.0)
    var header_h: float = clampf(h * 0.115, 15.0, 25.0)
    var control_cap_h: float = clampf(h * 0.10, 13.0, 21.0)
    _synth_model_label.position = Vector2(pad, pad * 0.55)
    _synth_model_label.size = Vector2(usable, header_h)
    _synth_model_label.add_theme_font_size_override("font_size", maxi(9, roundi(clampf(w * 0.030, 9.0, 14.0))))
    var cap_y: float = _synth_model_label.position.y + header_h + gap * 0.35
    _synth_control_caption.position = Vector2(pad, cap_y)
    _synth_control_caption.size = Vector2(usable, control_cap_h)
    _synth_control_caption.add_theme_font_size_override("font_size", maxi(10, roundi(clampf(w * 0.039, 10.0, 16.0))))
    var action_y: float = cap_y + control_cap_h + gap
    var remaining: float = h - action_y - pad
    var browse_h: float = maxf(27.0, minf(56.0, remaining * 0.33))
    var two_h: float = maxf(27.0, minf(54.0, remaining * 0.31))
    # Never overrun the cabinet on a short mobile safe-area viewport.
    if browse_h + two_h + 2.0 * gap > remaining:
        browse_h = maxf(20.0, remaining * 0.42 - gap)
        two_h = maxf(20.0, remaining * 0.40 - gap)
    _synth_browse_button.position = Vector2(pad, action_y)
    _synth_browse_button.size = Vector2(usable, browse_h)
    var next_y: float = action_y + browse_h + gap
    var half_w: float = maxf(25.0, (usable - gap) * 0.5)
    listen_button.position = Vector2(pad, next_y)
    listen_button.size = Vector2(half_w, two_h)
    learn_button.position = Vector2(pad + half_w + gap, next_y)
    learn_button.size = Vector2(half_w, two_h)
    var font_px: int = maxi(10, roundi(clampf(minf(w * 0.049, two_h * 0.39), 10.0, 20.0)))
    for button in [_synth_browse_button, listen_button, learn_button]:
        button.add_theme_font_size_override("font_size", font_px)
    var status_y: float = next_y + two_h + gap * 0.55
    var status_h: float = maxf(0.0, h - status_y - pad * 0.55)
    progress_label.position = Vector2(pad, status_y)
    progress_label.size = Vector2(usable * 0.28, status_h)
    progress_label.add_theme_font_size_override("font_size", maxi(9, roundi(font_px * 0.90)))
    mode_label.position = Vector2(pad + usable * 0.30, status_y)
    mode_label.size = Vector2(usable * 0.68, status_h)
    mode_label.add_theme_font_size_override("font_size", maxi(9, roundi(font_px * 0.75)))
    song_title.hide()
    song_selector.hide()
