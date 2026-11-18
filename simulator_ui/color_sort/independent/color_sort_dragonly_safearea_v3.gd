extends "res://simulator_ui/color_sort/independent/color_sort_dragonly_rapid_v2.gd"
## MIKA Color Sort v3: respect safe-area insets for the central stage ONLY.
## The original toolbar, baskets, draggable shapes, voices, sound effects,
## crystal rewards, and checkpoint controls stay fully inherited.

const MIKA_SAFE_STAGE_UI := preload("res://simulator_ui/scripts/mika_minigame_ui_kit_v11.gd")


func _mika_safe_stage_rect_for(safe: Rect2, top: float, bottom: float) -> Rect2:
    # The parent already lays out the baskets and the toolbar in this same
    # logical-coordinate safe rectangle. Use it for the *visible* main frame.
    var horizontal_inset: float = clampf(safe.size.x * 0.014, 9.0, 24.0)
    var vertical_inset: float = clampf(safe.size.y * 0.012, 6.0, 14.0)
    var frame_left: float = safe.position.x + horizontal_inset
    var frame_right: float = safe.end.x - horizontal_inset
    var frame_top: float = maxf(safe.position.y + vertical_inset, top - 14.0)
    var frame_bottom: float = minf(safe.end.y - vertical_inset, bottom + 21.0)
    return Rect2(
        Vector2(frame_left, frame_top),
        Vector2(maxf(1.0, frame_right - frame_left), maxf(1.0, frame_bottom - frame_top))
    )


func _mika_current_safe_stage_rect() -> Rect2:
    return _mika_safe_stage_rect_for(_ui_safe_area(), play_top, play_bottom)


func _draw_background() -> void:
    # Keep decorative space beyond the frame, but clip its ACTUAL visible
    # game panel to the same OS-safe region used by the basket geometry.
    draw_rect(Rect2(Vector2.ZERO, size), Color(0.008, 0.024, 0.060, 0.13), true)
    var stage: Rect2 = _mika_current_safe_stage_rect()
    draw_style_box(MIKA_SAFE_STAGE_UI.stage_style(), stage)
    # Glows are decorative only, centered on the safe stage itself.
    _draw_glow(Vector2(stage.position.x + stage.size.x * 0.11, stage.position.y + stage.size.y * 0.32),
               minf(205.0, stage.size.x * 0.25), Color("285fb0"), 0.05)
    _draw_glow(Vector2(stage.position.x + stage.size.x * 0.88, stage.position.y + stage.size.y * 0.70),
               minf(205.0, stage.size.x * 0.25), Color("1a7a9b"), 0.05)
