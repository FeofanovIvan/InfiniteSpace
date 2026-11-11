extends TextureRect
## Same main-flight circle geometry as scripts/ActionButton.gd, decorative only.
func _ready() -> void:
    texture = null
    mouse_filter = Control.MOUSE_FILTER_IGNORE
    queue_redraw()

func _draw() -> void:
    var center: Vector2 = size * 0.5
    draw_circle(center, 83.0, Color(0.02, 0.10, 0.18, 0.47))
    draw_circle(center, 67.0, Color(0.04, 0.17, 0.28, 0.76))
    draw_arc(center, 67.0, 0.0, TAU, 64, Color(0.38, 0.80, 1.0, 0.76), 2.5, true)
    draw_arc(center, 49.0, 0.0, TAU, 64, Color(0.18, 0.51, 0.70, 0.30), 1.5, true)
