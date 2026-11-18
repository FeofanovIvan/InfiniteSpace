extends "res://simulator_ui/action_cards/scripts/action_lab_v125.gd"
## MIKA Action Lab v126: a genuinely SQUARE drag/drop card.
## The question and SVG are both CHILDREN of the same square target panel;
## they are laid out inside it, not two separate decorations under one cover.
## Success reveals the correct Mika and advances automatically, without Next.

const V126_SUCCESS_HOLD_SECONDS: float = 1.65
var _v126_round_serial: int = 0


func _build_interface() -> void:
    super._build_interface()
    # Move the actual SVG drawing control into the SAME interactive square
    # as the '?' label. Reparenting (not enlarging an overlay) preserves the
    # existing SVG's reveal logic, source texture, and child-free touch target.
    if stage_art != null and target_panel != null:
        stage_art.reparent(target_panel, false)
        stage_art.mouse_filter = Control.MOUSE_FILTER_IGNORE
        target_panel.clip_contents = true
    if next_button != null:
        next_button.visible = false
        next_button.disabled = true
        next_button.mouse_filter = Control.MOUSE_FILTER_IGNORE


func _fit_to_viewport() -> void:
    super._fit_to_viewport()
    if stage_panel == null or target_panel == null or stage_art == null or prompt_word == null:
        return
    var view: Vector2 = size
    if view.x < 10.0 or view.y < 10.0:
        view = get_viewport_rect().size
    var s: float = clampf(minf(view.x / 1280.0, view.y / 720.0), 0.50, 1.55)
    var main_w: float = stage_panel.size.x
    var main_h: float = stage_panel.size.y
    if main_w <= 0.0 or main_h <= 0.0:
        return

    # Reserve a small strip BELOW the square for verb + repeat speaker.
    # The entire remainder is offered to the question card, subject to a
    # strict 1:1 aspect ratio even on very wide or short mobile displays.
    var edge: float = maxf(6.0, 10.0 * s)
    var caption_h: float = clampf(main_h * 0.145, 30.0 * s, 54.0 * s)
    var between: float = maxf(5.0, 9.0 * s)
    var available_h: float = main_h - 2.0 * edge - caption_h - between
    var available_w: float = main_w - 2.0 * edge
    var side: float = maxf(1.0, minf(minf(available_h, available_w), 450.0 * s))
    var square_x: float = (main_w - side) * 0.5
    var square_y: float = edge + maxf(0.0, (available_h - side) * 0.22)
    target_panel.position = Vector2(square_x, square_y)
    target_panel.size = Vector2(side, side) # ALWAYS SQUARE (1:1).
    target_panel.add_theme_stylebox_override("panel", _style(Color("0F2B4E"), Color("86E4FC"), 25, 3))

    # One square, two vertically stacked contents. '?' occupies its upper
    # portion. SVG occupies the lower portion at its native 560:160 aspect.
    # Both belong to target_panel; neither can become detached under resizing.
    var inset: float = maxf(5.0 * s, side * 0.045)
    var question_h: float = side * 0.43
    question_label.position = Vector2(inset, inset)
    question_label.size = Vector2(side - 2.0 * inset, question_h)
    question_label.add_theme_font_size_override("font_size", maxi(25, roundi(minf(question_h * 0.66, 100.0 * s))))
    question_label.mouse_filter = Control.MOUSE_FILTER_IGNORE

    var svg_region_top: float = inset + question_h + maxf(2.0, side * 0.028)
    var svg_region_h: float = maxf(2.0, side - svg_region_top - inset)
    var svg_max_w: float = maxf(2.0, side - 2.0 * inset)
    var svg_w: float = minf(svg_max_w, svg_region_h * 3.5)
    var svg_h: float = svg_w / 3.5
    stage_art.position = Vector2((side - svg_w) * 0.5,
        svg_region_top + (svg_region_h - svg_h) * 0.5)
    stage_art.size = Vector2(svg_w, svg_h)
    stage_art.queue_redraw()

    # Verb and replay speaker are in the surrounding MIDDLE PANEL, just
    # BELOW the square; the toolbar contains no action verb.
    var word_y: float = square_y + side + between
    var speaker_size: float = minf(47.0 * s, caption_h)
    var label_gap: float = 9.0 * s
    var label_w: float = minf(main_w * 0.50, 470.0 * s)
    var group_w: float = label_w + label_gap + speaker_size
    var word_x: float = (main_w - group_w) * 0.5
    prompt_word.position = Vector2(word_x, word_y)
    prompt_word.size = Vector2(label_w, caption_h)
    prompt_word.add_theme_font_size_override("font_size", maxi(13, roundi((22.0 if prompt_word.text.length() > 13 else 30.0) * s)))
    if _v125_speaker != null:
        _v125_speaker.position = Vector2(word_x + label_w + label_gap, word_y + (caption_h - speaker_size) * 0.5)
        _v125_speaker.size = Vector2(speaker_size, speaker_size)
        _v125_speaker.queue_redraw()

    # Success image occupies the former square and is not clipped by it;
    # the entire question/SVG square disappears on correct placement.
    if win_sprite != null:
        var win_side: float = side * 0.90
        win_sprite.position = Vector2(square_x + (side - win_side) * 0.5,
            square_y + (side - win_side) * 0.5)
        win_sprite.size = Vector2(win_side, win_side)
        win_sprite.pivot_offset = win_sprite.size * 0.5

    if next_button != null:
        next_button.visible = false


func _start_next_round() -> void:
    _v126_round_serial += 1
    super._start_next_round()
    if next_button != null:
        next_button.visible = false
    if question_label != null:
        question_label.visible = true
    if stage_art != null:
        stage_art.visible = true
        # The whole SVG is a readable hint before the child chooses Mika.
        stage_art.reveal = 1.0


func _finish_correct() -> void:
    super._finish_correct()
    if not answer_solved:
        return
    # The inherited code exposes Next. The button stays invisible/disabled.
    if next_button != null:
        next_button.visible = false
    var serial: int = _v126_round_serial
    _v126_advance_later(serial)


func _v126_advance_later(serial: int) -> void:
    # Simulator pauses space flight. SceneTree timers process during pause.
    await get_tree().create_timer(V126_SUCCESS_HOLD_SECONDS, true).timeout
    if not is_inside_tree() or serial != _v126_round_serial or not answer_solved:
        return
    _start_next_round()
