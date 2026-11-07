extends Control
## MIKA v8.5.3: tall blue-glass power bar, fill rises green -> yellow -> red.
# MIKA_BUBBLE_VERTICAL_STRENGTH_V8_5_3
var strength: float = 0.12:
	set(value):
		strength = clampf(value, 0.0, 1.0)
		queue_redraw()

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	resized.connect(queue_redraw)

func _draw() -> void:
	if size.x < 8.0 or size.y < 18.0:
		return
	var shell := StyleBoxFlat.new()
	shell.bg_color = Color(0.025, 0.11, 0.20, 0.90)
	shell.border_color = Color(0.32, 0.83, 1.0, 0.97)
	shell.set_corner_radius_all(15)
	shell.set_border_width_all(2)
	shell.shadow_color = Color(0.03, 0.57, 0.88, 0.30)
	shell.shadow_size = 4
	draw_style_box(shell, Rect2(Vector2.ZERO, size))
	var pad: float = 6.0
	var inner_w: float = maxf(1.0, size.x - pad * 2.0)
	var inner_h: float = maxf(1.0, size.y - pad * 2.0)
	var fill_h: float = inner_h * strength
	var steps: int = 64
	# Fixed spectrum by height, not stretched as the strength changes.
	for i in range(steps):
		var f: float = float(i) / float(steps)
		if f > strength:
			break
		var low: Color = Color("4fe489")
		var middle: Color = Color("ffe466")
		var high: Color = Color("ed3652")
		var color: Color = low.lerp(middle, f * 2.0) if f < 0.5 else middle.lerp(high, (f - 0.5) * 2.0)
		var step_bottom: float = size.y - pad - f * inner_h
		draw_rect(Rect2(pad, step_bottom - maxf(1.5, inner_h / float(steps)), inner_w, maxf(1.5, inner_h / float(steps)) + 0.4), color, true)
	var cursor_y: float = size.y - pad - fill_h
	draw_line(Vector2(3.0, cursor_y), Vector2(size.x - 3.0, cursor_y), Color("e8fbff"), 2.4, true)
