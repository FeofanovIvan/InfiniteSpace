@tool
extends "res://planet_hub/scripts/planet_card.gd"
## v83: exact PlanetHub outer border, but the art bay reaches the ONLY
## bottom caption. No legacy 68.5%-height title divider/description section.
const GAME_CAPTION_TOP: float = 0.84

func _layout_content() -> void:
    super._layout_content()
    if title_label == null or artwork == null:
        return
    var w: float = size.x
    var h: float = size.y
    if w < 4.0 or h < 4.0:
        return
    var s: float = minf(w / 430.0, h / 540.0)
    var plaque_y: float = h * GAME_CAPTION_TOP
    var pad: float = 23.0 * s

    # Reserve EVERYTHING above the bottom caption for the future game image.
    artwork.position = Vector2(pad, 22.0 * s)
    artwork.size = Vector2(maxf(1.0, w - 2.0 * pad), maxf(1.0, plaque_y - 29.0 * s))
    _update_artwork_fit()
    image_hint.position = artwork.position
    image_hint.size = artwork.size
    image_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    image_hint.vertical_alignment = VERTICAL_ALIGNMENT_CENTER

    # Only one caption, vertically centred in the small bottom plaque.
    title_label.position = Vector2(25.0 * s, plaque_y + 3.0 * s)
    title_label.size = Vector2(maxf(1.0, w - 50.0 * s), maxf(1.0, h - plaque_y - 11.0 * s))
    title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    title_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
    title_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    title_label.clip_text = true
    title_label.add_theme_font_size_override("font_size", maxi(17, roundi(34.0 * s)))
    if subtitle_label != null:
        subtitle_label.visible = false
    if description_label != null:
        description_label.visible = false
    queue_redraw()


func _draw() -> void:
    # Base PlanetHub card's outer shape/glow/highlights, but not its
    # representative-specific plaque divider at 68.5% of card height.
    var w: float = size.x
    var h: float = size.y
    if w <= 3.0 or h <= 3.0:
        return
    var s: float = minf(w / 430.0, h / 540.0)
    var border: PackedVector2Array = _corners(Rect2(4.0 * s, 4.0 * s, w - 8.0 * s, h - 8.0 * s), 24.0 * s)
    draw_colored_polygon(border, Color(0.006, 0.028, 0.075, 0.91))
    _stroke(border, Color(0.04, 0.60, 1.0, 0.12), 12.0 * s)
    _stroke(border, Color(0.01, 0.42, 0.95, 0.36), 7.0 * s)
    _stroke(border, Color(0.25, 0.81, 1.0, 0.97), 2.8 * s)

    var plaque_y: float = h * GAME_CAPTION_TOP
    var plaque: PackedVector2Array = PackedVector2Array([
        Vector2(8.0 * s, plaque_y), Vector2(w - 8.0 * s, plaque_y),
        Vector2(w - 8.0 * s, h - 32.0 * s), Vector2(w - 32.0 * s, h - 8.0 * s),
        Vector2(29.0 * s, h - 8.0 * s), Vector2(8.0 * s, h - 29.0 * s)
    ])
    draw_colored_polygon(plaque, Color(0.006, 0.055, 0.13, 0.98))
    draw_rect(Rect2(19.0 * s, plaque_y - 3.0 * s, w - 38.0 * s, 3.0 * s), Color(0.08, 0.57, 0.99, 0.80))

    # Placeholder technical grid extends over the FORMER TITLE BAY too.
    # When art is assigned later, the entire area is its image rectangle.
    if not is_instance_valid(artwork) or artwork.texture == null:
        var left: float = 25.0 * s
        var right: float = w - 25.0 * s
        var top: float = 24.0 * s
        var bottom: float = plaque_y - 8.0 * s
        if bottom > top and right > left:
            draw_rect(Rect2(left, top, right - left, bottom - top), Color(0.07, 0.16, 0.25, 0.38), true)
            for ix in range(1, 8):
                var xx: float = lerpf(left, right, float(ix) / 8.0)
                draw_line(Vector2(xx, top), Vector2(xx, bottom), Color(0.35, 0.67, 0.90, 0.12), 1.0 * s)
            for iy in range(1, 7):
                var yy: float = lerpf(top, bottom, float(iy) / 7.0)
                draw_line(Vector2(left, yy), Vector2(right, yy), Color(0.35, 0.67, 0.90, 0.12), 1.0 * s)
            draw_rect(Rect2(left, top, right - left, bottom - top), Color(0.15, 0.58, 0.90, 0.55), false, 1.2 * s)
            var cx: float = w * 0.5
            var cy: float = (top + bottom) * 0.5
            draw_rect(Rect2(cx - 38.0 * s, cy - 28.0 * s, 76.0 * s, 56.0 * s), Color(0.5, 0.78, 0.96, 0.55), false, 2.0 * s)
            draw_circle(Vector2(cx + 19.0 * s, cy - 11.0 * s), 6.0 * s, Color(0.5, 0.78, 0.96, 0.50))
            draw_polyline(PackedVector2Array([
                Vector2(cx - 30.0 * s, cy + 19.0 * s), Vector2(cx - 8.0 * s, cy - 4.0 * s),
                Vector2(cx + 4.0 * s, cy + 9.0 * s), Vector2(cx + 17.0 * s, cy - 3.0 * s),
                Vector2(cx + 30.0 * s, cy + 19.0 * s)
            ]), Color(0.5, 0.78, 0.96, 0.58), 2.0 * s, true)

    draw_line(Vector2(36.0 * s, 8.0 * s), Vector2(111.0 * s, 8.0 * s), accent, 3.0 * s, true)
    draw_line(Vector2(w - 113.0 * s, 8.0 * s), Vector2(w - 36.0 * s, 8.0 * s), accent, 3.0 * s, true)
    draw_line(Vector2(9.0 * s, h - 110.0 * s), Vector2(9.0 * s, h - 53.0 * s), accent, 3.0 * s, true)
    draw_line(Vector2(w - 9.0 * s, h - 110.0 * s), Vector2(w - 9.0 * s, h - 53.0 * s), accent, 3.0 * s, true)
