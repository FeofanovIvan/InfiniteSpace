extends Control
var remaining: float = 3.0

func _draw() -> void:
 var panel := StyleBoxFlat.new()
 panel.bg_color = Color(0.025, 0.065, 0.13, 0.93)
 panel.border_color = Color(0.22, 0.79, 0.96, 0.88)
 panel.set_border_width_all(2)
 panel.set_corner_radius_all(17)
 panel.shadow_color = Color(0.0, 0.8, 1.0, 0.18)
 panel.shadow_size = 7
 draw_style_box(panel, Rect2(Vector2.ZERO, size))
 var colors: Array[Color] = [Color(1.0, 0.19, 0.24), Color(1.0, 0.76, 0.16), Color(0.22, 1.0, 0.48)]
 for i in range(3):
  var center := Vector2(43.0 + float(i) * 54.0, 35.0)
  var active: bool = (remaining > 2.0 and i == 0) or (remaining <= 2.0 and remaining > 1.0 and i == 1) or (remaining <= 1.0 and remaining >= 0.0 and i == 2) or (remaining < 0.0 and i == 2)
  draw_circle(center, 21.0, Color(0.0, 0.02, 0.055, 0.92))
  var c: Color = colors[i]
  c.a = 1.0 if active else 0.20
  if active:
   draw_circle(center, 19.0, Color(c.r, c.g, c.b, 0.19))
  draw_circle(center, 15.5, c)
  draw_arc(center, 18.0, 0.0, TAU, 36, Color(0.5, 0.85, 1.0, 0.26), 1.5, true)
