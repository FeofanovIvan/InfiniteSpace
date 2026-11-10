extends "res://education/playtown/src/features/piano/piano_game_mika_synth_v3_2.gd"
## MIKA Piano Synth v3.3.1 • ONE full-stage cabinet, clean case edges.
## Original MIDI/event/song data, original keys, audio and modes stay inherited.
## The shared game toolbar Back replaces the redundant simulator Back only while
## this Piano scene is active; the original simulator button is restored on exit.

var _mika_simulator_back_to_restore: Control = null
var _mika_simulator_back_mouse_filter: int = Control.MOUSE_FILTER_STOP
var _mika_simulator_back_initially_visible: bool = false


func _ready() -> void:
    super._ready()
    # v3.2 hides this button when embedded. The user wants the toolbar's own
    # real back button, not the simulator's separate button above this scene.
    if _mika_back != null:
        _mika_back.show()
        _mika_back.mouse_filter = Control.MOUSE_FILTER_STOP
    _hide_host_simulator_back()

    # The main stage draws the full physical body. Never overlay another box.
    _synth_cabinet.hide()
    _synth_case_ridge.hide()      # Unwanted stripe through MIKA branding.
    _synth_keyboard_rail.hide()   # Unwanted stripe above the keys.
    var case_style := _mika_panel_skin(Color("#493e94"), Color("#9aeaff"), 27, 4, 16)
    case_style.shadow_color = Color(0.24, 0.17, 0.82, 0.48)
    _mika_stage.add_theme_stylebox_override("panel", case_style)
    # Low-opacity REAL nebulae above the purple-blue enamel, not a black layer.
    _mika_sky.modulate = Color(0.93, 0.88, 1.0, 0.09)
    _mika_sky_tint.color = Color(0.12, 0.05, 0.32, 0.10)
    _layout()


func _hide_host_simulator_back() -> void:
    # Piano is launched in the original SubViewport of MikoMainMenu. The
    # extra simulator Back is a SIBLING of the viewport, not a Piano child.
    var ancestor: Node = get_parent()
    for _i in range(26):
        if ancestor == null:
            break
        if ancestor.has_method("_return_to_cards"):
            var host_back: Node = ancestor.find_child("ReturnToEducationalCards", true, false)
            if host_back is Control:
                _mika_simulator_back_to_restore = host_back as Control
                _mika_simulator_back_mouse_filter = _mika_simulator_back_to_restore.mouse_filter
                _mika_simulator_back_initially_visible = _mika_simulator_back_to_restore.visible
                _mika_simulator_back_to_restore.hide()
                _mika_simulator_back_to_restore.mouse_filter = Control.MOUSE_FILTER_IGNORE
            return
        ancestor = ancestor.get_parent()


func _exit_tree() -> void:
    # The simulator can immediately launch another game: restore its native
    # Back even if Piano is closed through a different navigation route.
    if is_instance_valid(_mika_simulator_back_to_restore):
        _mika_simulator_back_to_restore.visible = _mika_simulator_back_initially_visible
        _mika_simulator_back_to_restore.mouse_filter = _mika_simulator_back_mouse_filter
    _mika_simulator_back_to_restore = null


func _layout_synth_shell(view: Vector2) -> void:
    # v2.1 has already confined its cosmic stage to the OS safe area.
    var stage: Rect2 = Rect2(_mika_stage.position, _mika_stage.size)
    if stage.size.x < 170.0 or stage.size.y < 110.0:
        return
    # The stage itself IS the instrument chassis: no smaller nested cabinet.
    # Only a thin internal margin protects the actual keys and control surfaces.
    var inner_pad: float = clampf(minf(stage.size.x, stage.size.y) * 0.018, 5.0, 13.0)
    var content: Rect2 = stage.grow(-inner_pad)
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
    # No decorative divider over the keys. The keyboard tray meets the case.


