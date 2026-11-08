extends "res://simulator_ui/action_cards/scripts/action_lab_v126.gd"
## MIKA Action Lab v127 — one full-bleed silhouette hint card.
## Z order: square's own backing -> FULL-SQUARE action SVG -> translucent
## ice-blue gradient glass -> large question mark.  No extra cards.
## Auto-next, endless random deck, scoring, audio, drag/drop remain v126.

var _v127_veil: TextureRect


func _build_interface() -> void:
    super._build_interface()
    if target_panel == null or stage_art == null or question_label == null:
        return

    # Retain the current, genuinely square drop target.  The image fills it
    # edge-to-edge rather than living in a small lower sub-panel.
    target_panel.clip_contents = true
    stage_art.mouse_filter = Control.MOUSE_FILTER_IGNORE
    stage_art.modulate = Color(0.93, 0.98, 1.0, 0.95)

    # A mildly graduated, 54-58%-transparent cobalt/ice-blue film.  This is
    # overlay art, not a second interactive target or a blurred PNG copy.
    var tint: Gradient = Gradient.new()
    tint.colors = PackedColorArray([
        Color(0.055, 0.25, 0.48, 0.43),
        Color(0.19, 0.48, 0.74, 0.46),
        Color(0.085, 0.34, 0.64, 0.42),
    ])
    tint.offsets = PackedFloat32Array([0.0, 0.53, 1.0])
    var film_texture: GradientTexture2D = GradientTexture2D.new()
    film_texture.gradient = tint
    film_texture.width = 256
    film_texture.height = 256
    film_texture.fill_from = Vector2(0.0, 0.0)
    film_texture.fill_to = Vector2(1.0, 1.0)
    _v127_veil = TextureRect.new()
    _v127_veil.name = "V127_TranslucentBlueFilm_AboveSVG"
    _v127_veil.texture = film_texture
    _v127_veil.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
    _v127_veil.stretch_mode = TextureRect.STRETCH_SCALE
    _v127_veil.mouse_filter = Control.MOUSE_FILTER_IGNORE
    target_panel.add_child(_v127_veil)

    # Explicit draw order is essential.  In v126 the reparented SVG was last
    # and could hide the '?'; v127 always paints the question on top.
    target_panel.move_child(stage_art, 0)
    target_panel.move_child(_v127_veil, 1)
    target_panel.move_child(question_label, target_panel.get_child_count() - 1)
    question_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
    question_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    question_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
    question_label.add_theme_color_override("font_color", Color(0.95, 0.99, 1.0, 0.97))
    question_label.add_theme_color_override("font_outline_color", Color(0.07, 0.23, 0.40, 0.86))


func _fit_to_viewport() -> void:
    super._fit_to_viewport()
    if target_panel == null or stage_art == null or question_label == null or _v127_veil == null:
        return

    # v126 computes a maximal square for each aspect ratio and reserves the
    # verb + speaker underneath.  ONLY change content inside that square.
    var side: float = minf(target_panel.size.x, target_panel.size.y)
    if side <= 0.0:
        return
    stage_art.position = Vector2.ZERO
    stage_art.size = Vector2(side, side)
    stage_art.queue_redraw()
    _v127_veil.position = Vector2.ZERO
    _v127_veil.size = Vector2(side, side)
    question_label.position = Vector2.ZERO
    question_label.size = Vector2(side, side)
    question_label.add_theme_font_size_override("font_size", maxi(46, roundi(side * 0.71)))
    question_label.add_theme_constant_override("outline_size", maxi(3, roundi(side * 0.018)))
