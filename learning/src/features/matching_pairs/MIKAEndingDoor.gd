extends "res://learning/src/features/matching_pairs/mika_matching_door_octagon_v3_1.gd"
## MIKA_CH07_PAIRS_ENDING_V2 — ordinary native door until assigned an ending.
## Same original frame, leaves, aperture mask, input, and slide animation.
var ending_art: Texture2D
var _ending_preview: TextureRect

func set_ending_art(art: Texture2D) -> void:
    ending_art = art
    if not is_instance_valid(_ending_preview):
        _ending_preview = TextureRect.new()
        _ending_preview.name = "EndingBehindDoor"
        _ending_preview.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
        _ending_preview.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
        _ending_preview.mouse_filter = Control.MOUSE_FILTER_IGNORE
        _mask.add_child(_ending_preview)
        _mask.move_child(_ending_preview, 0)
    _ending_preview.texture = art
    _ending_preview.visible = art != null
    _on_resized()
    queue_redraw()

func _on_resized() -> void:
    super._on_resized()
    if is_instance_valid(_ending_preview):
        # Cover the whole octagonal stencil. The mask clips the excess;
        # keep the source ratio, no stretching, insets or letterboxing.
        _ending_preview.position = Vector2.ZERO
        _ending_preview.size = size

func _draw() -> void:
    if ending_art == null:
        super._draw()
    elif size.x > 0.0 and size.y > 0.0:
        draw_texture_rect(OCTAGON_ALPHA, Rect2(Vector2.ZERO, size), false, Color("#08192e"))
