extends Control
## Racing standings, rendered without external fonts or assets.
var elapsed: float = 0.0
var standings: Array[Dictionary] = []
const BG := Color(0.025, 0.085, 0.15, 0.96)
const BORDER := Color(0.20, 0.73, 0.93)
const WHITE := Color(0.86, 0.96, 1.0)
const MUTED := Color(0.57, 0.77, 0.86)
const CYAN := Color(0.44, 0.91, 1.0)

func _time_label(value: float) -> String:
 var secs: float = maxf(0.0, value)
 return "%02d:%04.1f" % [int(secs / 60.0), fmod(secs, 60.0)]

func _draw() -> void:
 var factor: float = size.x / 320.0
 var font: Font = ThemeDB.fallback_font
 var box := Rect2(Vector2.ZERO, size)
 draw_rect(box, BG, true)
 draw_rect(box, BORDER, false, 2.0 * factor)
 draw_string(font, Vector2(13, 24) * factor, "SPACE RACING", HORIZONTAL_ALIGNMENT_LEFT, -1, 14 * factor, CYAN)
 draw_string(font, Vector2(195, 24) * factor, _time_label(elapsed), HORIZONTAL_ALIGNMENT_LEFT, -1, 18 * factor, WHITE)
 draw_string(font, Vector2(12, 49) * factor, "#     PILOT", HORIZONTAL_ALIGNMENT_LEFT, -1, 12 * factor, MUTED)
 draw_string(font, Vector2(181, 49) * factor, "TIME", HORIZONTAL_ALIGNMENT_LEFT, -1, 12 * factor, MUTED)
 draw_string(font, Vector2(266, 49) * factor, "LAP", HORIZONTAL_ALIGNMENT_LEFT, -1, 12 * factor, MUTED)
 for i in range(mini(5, standings.size())):
  var racer: Dictionary = standings[i]
  var y: float = (57.0 + float(i) * 33.0) * factor
  var highlight: bool = bool(racer.get("mika", false))
  draw_rect(Rect2(Vector2(8.0 * factor, y), Vector2(size.x - 16.0 * factor, 30.0 * factor)), Color(0.075, 0.27, 0.38, 0.96) if highlight else Color(0.055, 0.17, 0.27, 0.93), true)
  var ink: Color = CYAN if highlight else WHITE
  draw_string(font, Vector2(15.0, 77.0 + float(i) * 33.0) * factor, str(i + 1), HORIZONTAL_ALIGNMENT_LEFT, -1, 15 * factor, ink)
  draw_string(font, Vector2(45.0, 77.0 + float(i) * 33.0) * factor, str(racer.get("name", "")), HORIZONTAL_ALIGNMENT_LEFT, -1, 14 * factor, ink)
  draw_string(font, Vector2(181.0, 77.0 + float(i) * 33.0) * factor, _time_label(float(racer.get("time", 0.0))), HORIZONTAL_ALIGNMENT_LEFT, -1, 14 * factor, WHITE)
  draw_string(font, Vector2(269.0, 77.0 + float(i) * 33.0) * factor, "%d/3" % int(racer.get("lap", 1)), HORIZONTAL_ALIGNMENT_LEFT, -1, 14 * factor, Color(0.46, 0.92, 0.72))
