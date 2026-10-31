class_name BasketballPowerGauge
extends Control

# Compact rounded power meter, matching the blue controls.
# The visual meter is passive: press-and-hold on the throw button still charges it.
const IDEAL_POWER := 0.60
const RAIL_COLOR := Color("#173f65")
const BORDER_COLOR := Color("#dffaff")
const BLUE := Color("#42b9ec")
const GREEN := Color("#5be3a2")
const ORANGE := Color("#ffae69")

var value := 0.0:
	set(next_value):
		value = clampf(next_value, 0.0, 1.0)
		queue_redraw()


func _draw() -> void:
	var w: float = size.x
	var h: float = size.y
	if w < 20.0 or h < 32.0:
		return
	# A dark backing creates enough contrast against both the bright sky and the court.
	var outer := Rect2(3.0, 3.0, w - 6.0, h - 6.0)
	draw_style_box(_rounded_box(RAIL_COLOR, BORDER_COLOR, 17, 3), outer)
	var track := Rect2(11.0, 12.0, w - 22.0, h - 24.0)
	draw_style_box(_rounded_box(Color("#255a80"), Color.TRANSPARENT, 9, 0), track)
	# Keep the filled area rounded, even when the power is nearly empty.
	var filled_height: float = track.size.y * value
	if filled_height > 2.0:
		var filled := Rect2(track.position.x, track.end.y - filled_height, track.size.x, filled_height)
		var fill_color: Color = BLUE.lerp(GREEN, clampf(value / IDEAL_POWER, 0.0, 1.0))
		if value > IDEAL_POWER:
			fill_color = GREEN.lerp(ORANGE, clampf((value - IDEAL_POWER) / (1.0 - IDEAL_POWER), 0.0, 1.0))
		draw_style_box(_rounded_box(fill_color, Color.TRANSPARENT, 9, 0), filled)
	# The target is a short clean indicator, rather than a line crossing the outline.
	var ideal_y: float = track.end.y - track.size.y * IDEAL_POWER
	draw_line(Vector2(track.position.x - 2.0, ideal_y), Vector2(track.end.x + 2.0, ideal_y), Color("#fff6b0"), 3.0, true)
	# Small white thumb, inset inside the track, never outside the corners.
	var marker_y: float = clampf(track.end.y - track.size.y * value, track.position.y + 4.0, track.end.y - 4.0)
	draw_line(Vector2(track.position.x + 3.0, marker_y), Vector2(track.end.x - 3.0, marker_y), Color.WHITE, 4.0, true)


func _rounded_box(fill: Color, border: Color, radius: int, border_width: int) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = fill
	box.border_color = border
	box.set_border_width_all(border_width)
	box.set_corner_radius_all(radius)
	box.anti_aliasing = true
	return box
