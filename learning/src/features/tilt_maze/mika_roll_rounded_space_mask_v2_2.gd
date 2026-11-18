extends Control
## Roll the Ball v2.2 — real rounded stencil for the COSMIC BACKGROUND ONLY.
## The rounded silhouette is rendered as an alpha mask, not a blue overlay.
## In particular the maze, ball and HUD are NOT descendants of this mask.

var _mask_shape: StyleBoxFlat

func _ready() -> void:
    mouse_filter = Control.MOUSE_FILTER_IGNORE
    clip_children = CanvasItem.CLIP_CHILDREN_ONLY
    _mask_shape = StyleBoxFlat.new()
    _mask_shape.bg_color = Color.WHITE
    _mask_shape.set_border_width_all(0)
    _mask_shape.set_corner_radius_all(26)
    _mask_shape.anti_aliasing = true
    resized.connect(queue_redraw)
    queue_redraw()

func _draw() -> void:
    if _mask_shape != null and size.x > 0.0 and size.y > 0.0:
        # Godot's alpha stencil masks ALL children to these rounded corners.
        # CLIP_CHILDREN_ONLY suppresses the white mask itself from the picture.
        draw_style_box(_mask_shape, Rect2(Vector2.ZERO, size))
