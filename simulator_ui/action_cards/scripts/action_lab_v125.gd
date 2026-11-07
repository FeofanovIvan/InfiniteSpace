extends "res://simulator_ui/action_cards/scripts/action_lab_v124.gd"
## Action Lab v125: separated native-style top bar, central question > SVG > word + speaker.
## Keep all 20 action PNGs and SVGs, endless shuffle, hit testing and reward logic.

const V125_SPEAKER_SCRIPT: Script = preload("res://addons/mika_voice/SpeakerButton.gd")
const V125_CORRECT_SOUND: AudioStream = preload("res://education/playtown/audio/sfx/correct.ogg")
const V125_WRONG_SOUND: AudioStream = preload("res://education/playtown/audio/sfx/wrong.ogg")

var _v125_title_frame: Panel
var _v125_bottom_frame: Panel
var _v125_speaker: Button
var _v125_voice_locale: String = ""
var _v125_has_success: bool = false

func _build_interface() -> void:
    super._build_interface()
    # v124 had a full-width background and action word inside the header.
    # Reuse its actual arrow, 6-language title, and original crystal art.
    if _v124_toolbar != null:
        _v124_toolbar.visible = false

    _v125_title_frame = Panel.new()
    _v125_title_frame.name = "MiniGameToolbar_TitleCenter"
    _v125_title_frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
    _v125_title_frame.add_theme_stylebox_override("panel", _style(Color("09203E"), Color("6DE3FF"), 22, 3))
    canvas.add_child(_v125_title_frame)
    canvas.move_child(_v125_title_frame, 0)

    _v125_bottom_frame = Panel.new()
    _v125_bottom_frame.name = "ActionLab_BottomChoicesFrame"
    _v125_bottom_frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
    _v125_bottom_frame.add_theme_stylebox_override("panel", _style(Color("0A2445"), Color("47BCEB"), 24, 2))
    canvas.add_child(_v125_bottom_frame)
    canvas.move_child(_v125_bottom_frame, 1)

    # Action caption must belong to the MIDDLE panel only.
    prompt_word.reparent(stage_panel)
    prompt_word.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    prompt_word.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
    prompt_word.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    prompt_word.clip_text = true
    prompt_word.mouse_filter = Control.MOUSE_FILTER_IGNORE
    game_header.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    game_header.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
    status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    status_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
    status_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
    _v125_speaker = V125_SPEAKER_SCRIPT.new() as Button
    _v125_speaker.name = "SpeakActionAgain"
    _v125_speaker.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
    stage_panel.add_child(_v125_speaker)
    _v125_speaker.tooltip_text = "Replay the action"
    _v125_voice_locale = ""
    stage_art.visible = true

func _fit_to_viewport() -> void:
    if canvas == null:
        return
    var view: Vector2 = size
    if view.x < 10.0 or view.y < 10.0:
        view = get_viewport_rect().size
    if view.x < 10.0 or view.y < 10.0:
        return
    canvas.scale = Vector2.ONE
    canvas.position = Vector2.ZERO
    canvas.size = view
    _sky.position = Vector2.ZERO
    _sky.size = view
    var w: float = view.x
    var h: float = view.y
    var s: float = clampf(minf(w / 1280.0, h / 720.0), 0.50, 1.55)
    var pad: float = maxf(9.0, w * 0.021)
    var gap: float = maxf(6.0, 9.0 * s)
    var top_y: float = maxf(6.0, 11.0 * s)
    var toolbar_h: float = clampf(h * 0.114, 55.0 * s, 93.0 * s)

    # Trace Letters/Trace Words pattern: independent original back arrow, a
    # centered caption bar, and an independent crystal counter on the right.
    var back_w: float = 75.0 * s
    _back_button.position = Vector2(pad, top_y)
    _back_button.size = Vector2(back_w, toolbar_h)
    _back_button.add_theme_stylebox_override("normal", _style(Color("071B37"), Color("5EDCFC"), 19, 3))
    _back_button.add_theme_stylebox_override("hover", _style(Color("153958"), Color("B4F3FF"), 19, 3))
    _back_button.add_theme_stylebox_override("pressed", _style(Color("204A69"), Color("D9FBFF"), 19, 3))

    var counter_w: float = 190.0 * s
    var counter_h: float = toolbar_h * 0.81
    var counter_x: float = w - pad - counter_w
    _crystal_panel.position = Vector2(counter_x, top_y + (toolbar_h - counter_h) * 0.5)
    _crystal_panel.size = Vector2(counter_w, counter_h)
    _crystal_panel.add_theme_stylebox_override("panel", _style(Color("0B2445"), Color("4CCDF4"), 24, 2))
    _crystal_icon.position = Vector2(10.0 * s, 7.0 * s)
    _crystal_icon.size = Vector2(60.0 * s, counter_h - 14.0 * s)
    _crystal_label.position = Vector2(83.0 * s, 1.0 * s)
    _crystal_label.size = Vector2(maxf(14.0, counter_w - 91.0 * s), counter_h - 2.0 * s)
    _crystal_label.add_theme_font_size_override("font_size", maxi(18, roundi(30.0 * s)))

    var title_x: float = pad + back_w + 12.0 * s
    var title_w: float = maxf(110.0, counter_x - title_x - 13.0 * s)
    if _v125_title_frame != null:
        _v125_title_frame.position = Vector2(title_x, top_y)
        _v125_title_frame.size = Vector2(title_w, toolbar_h)
    game_header.position = Vector2(title_x + 14.0 * s, top_y + 4.0 * s)
    game_header.size = Vector2(maxf(15.0, title_w - 28.0 * s), toolbar_h * 0.49)
    game_header.add_theme_font_size_override("font_size", maxi(14, roundi((23.0 if game_header.text.length() > 17 else 30.0) * s)))
    status_label.position = Vector2(title_x + 13.0 * s, top_y + toolbar_h * 0.50)
    status_label.size = Vector2(maxf(15.0, title_w - 26.0 * s), toolbar_h * 0.42)
    status_label.add_theme_font_size_override("font_size", maxi(11, roundi(16.0 * s)))

    var main_y: float = top_y + toolbar_h + gap
    var bottom_h: float = clampf(h * 0.233, 102.0 * s, 185.0 * s)
    var bottom_y: float = h - bottom_h - gap
    var main_h: float = maxf(160.0 * s, bottom_y - main_y - gap)
    var content_w: float = w - pad * 2.0
    stage_panel.position = Vector2(pad, main_y)
    stage_panel.size = Vector2(content_w, main_h)
    stage_panel.add_theme_stylebox_override("panel", _style(Color("102C51"), Color("48CEF6"), 24, 2))
    if _v125_bottom_frame != null:
        _v125_bottom_frame.position = Vector2(pad, bottom_y)
        _v125_bottom_frame.size = Vector2(content_w, bottom_h)
    if _v124_mini_floor != null:
        _v124_mini_floor.visible = false

    # Correct central stack: QUESTION CARD, SVG DIRECTLY BELOW, ACTION WORD + SPEAKER.
    var target_h: float = clampf(main_h * 0.34, 68.0 * s, 138.0 * s)
    var target_w: float = minf(186.0 * s, content_w * 0.20)
    var svg_h: float = clampf(main_h * 0.33, 43.0 * s, 148.0 * s)
    # Centre the entire question/SVG/caption stack, not just the question card.
    var target_y: float = maxf(9.0 * s, (main_h - target_h - svg_h - 57.0 * s) * 0.5)
    target_panel.position = Vector2((content_w - target_w) * 0.5, target_y)
    target_panel.size = Vector2(target_w, target_h)
    target_panel.add_theme_stylebox_override("panel", _style(Color("0F2B4E"), Color("86E4FC"), 25, 3))
    question_label.position = Vector2.ZERO
    question_label.size = target_panel.size
    question_label.add_theme_font_size_override("font_size", maxi(29, roundi(minf(target_h * 0.67, 87.0 * s))))

    var svg_w: float = minf(content_w * 0.67, svg_h * 3.50)
    var svg_y: float = target_y + target_h + 2.0 * s
    stage_art.position = Vector2((content_w - svg_w) * 0.5, svg_y)
    stage_art.size = Vector2(svg_w, svg_h)
    stage_art.queue_redraw()

    var word_y: float = minf(main_h - 46.0 * s, svg_y + svg_h + 1.0 * s)
    var voice_w: float = 47.0 * s
    var name_w: float = minf(content_w * 0.48, 430.0 * s)
    var word_group_w: float = name_w + voice_w + 9.0 * s
    var group_x: float = (content_w - word_group_w) * 0.5
    prompt_word.position = Vector2(group_x, word_y)
    prompt_word.size = Vector2(name_w, 40.0 * s)
    prompt_word.add_theme_font_size_override("font_size", maxi(14, roundi((23.0 if prompt_word.text.length() > 13 else 29.0) * s)))
    if _v125_speaker != null:
        _v125_speaker.position = Vector2(group_x + name_w + 9.0 * s, word_y)
        _v125_speaker.size = Vector2(voice_w, 43.0 * s)
        _v125_speaker.queue_redraw()

    # On success the correct Mika occupies the CENTER where the target/SVG sat.
    var win_h: float = minf(main_h * 0.69, 257.0 * s)
    var win_w: float = win_h
    win_sprite.position = Vector2((content_w - win_w) * 0.5, maxf(0.0, target_y + (word_y - target_y - win_h) * 0.5))
    win_sprite.size = Vector2(win_w, win_h)
    win_sprite.pivot_offset = win_sprite.size * 0.5

    # All five Mika images stay in one separate bottom strip.
    var inner_pad: float = 14.0 * s
    var tile_gap: float = 10.0 * s
    var tile_w: float = (content_w - 2.0 * inner_pad - 4.0 * tile_gap) / 5.0
    var tile_h: float = bottom_h - 18.0 * s
    for i in range(OPTIONS_COUNT):
        var tile: Panel = option_panels[i]
        tile.position = Vector2(pad + inner_pad + float(i) * (tile_w + tile_gap), bottom_y + 9.0 * s)
        tile.size = Vector2(tile_w, tile_h)
        option_images[i].position = Vector2(5.0 * s, 4.0 * s)
        option_images[i].size = Vector2(maxf(1.0, tile_w - 10.0 * s), maxf(1.0, tile_h - 8.0 * s))

    next_button.position = Vector2(w - pad - 169.0 * s, main_y + main_h * 0.55)
    next_button.size = Vector2(154.0 * s, 58.0 * s)
    next_button.add_theme_font_size_override("font_size", maxi(13, roundi(20.0 * s)))
    ghost.size = Vector2(maxf(58.0, tile_w * 0.86), maxf(62.0, tile_h * 1.08))

func _v125_refresh_speaker() -> void:
    if _v125_speaker == null or current_action.is_empty():
        return
    _v125_voice_locale = _v124_locale()
    var action_word: String = _v124_action_title().to_lower()
    _v125_speaker.call("configure", action_word, _v125_voice_locale, "tablet", "action_lab")

func _v125_speak_action() -> void:
    if not is_inside_tree() or current_action.is_empty() or answer_solved:
        return
    var voice: Node = get_node_or_null("/root/MikaVoice")
    if voice != null and voice.has_method("speak_text"):
        voice.call("speak_text", _v124_action_title().to_lower(), _v124_locale(), "tablet", "action_lab")

func _start_next_round() -> void:
    super._start_next_round()
    if actions.is_empty():
        return
    _v125_has_success = false
    stage_art.visible = true
    target_panel.visible = true
    _v125_refresh_speaker()
    call_deferred("_v125_speak_action")

func _process(delta: float) -> void:
    super._process(delta)
    if _v125_speaker != null and _v125_voice_locale != _v124_locale():
        _v125_refresh_speaker()

func _check_answer(index: int) -> void:
    if answer_solved or index < 0 or index >= candidate_actions.size():
        return
    var correct: bool = str(candidate_actions[index].get("id", "")) == str(current_action.get("id", ""))
    super._check_answer(index)
    if not correct:
        SFX.play_2d(V125_WRONG_SOUND, get_viewport_rect().size * 0.5, -7.0)
        # Zero delay: simulator scenes may run with the flight tree paused.
        SFX.play_retry(get_viewport_rect().size * 0.5, 0.0)

func _finish_correct() -> void:
    super._finish_correct()
    _v125_has_success = true
    # The SVG is a hint only, not a victory overlay.
    stage_art.visible = false
    SFX.play_2d(V125_CORRECT_SOUND, get_viewport_rect().size * 0.5, -5.0)
    # Do not delay praise through a paused SceneTree timer.
    SFX.play_praise(get_viewport_rect().size * 0.5, 0.0)
