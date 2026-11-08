@tool
extends "res://simulator_ui/scripts/simulator_game_card.gd"
## v94: PlanetHub simulator frame with a translucent ice-blue artwork bay.
## PNG icons remain 100% transparent and are displayed with CONTAIN, never cropped.

func _draw() -> void:
    # Preserve the approved PlanetHub outline, neon accents and lower caption.
    super._draw()
    var w: float = size.x
    var h: float = size.y
    if w < 4.0 or h < 4.0:
        return
    var s: float = minf(w / 430.0, h / 540.0)
    var art_top: float = 23.0 * s
    var art_bottom: float = h * GAME_CAPTION_TOP - 10.0 * s
    var bay: Rect2 = Rect2(23.0 * s, art_top,
        maxf(1.0, w - 46.0 * s), maxf(1.0, art_bottom - art_top))
    var plate := StyleBoxFlat.new()
    plate.bg_color = Color(0.78, 0.92, 1.0, 0.62)
    plate.border_color = Color(0.52, 0.84, 1.0, 0.90)
    plate.set_border_width_all(maxi(1, roundi(2.0 * s)))
    plate.set_corner_radius_all(maxi(4, roundi(22.0 * s)))
    plate.anti_aliasing = true
    draw_style_box(plate, bay)
