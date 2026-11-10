extends Control
## Decorative, deterministic cosmic background. No external artwork or animation.
## Ships as native Godot drawing so it adapts to phones and tablets.

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	resized.connect(queue_redraw)
	queue_redraw()


func _draw() -> void:
	var w: float = maxf(size.x, 1.0)
	var h: float = maxf(size.y, 1.0)
	draw_rect(Rect2(Vector2.ZERO, Vector2(w, h)), Color("#09172f"))
	# Quiet, layered glows; the area behind the text stays dark enough to read.
	var glows: Array = [
		{"p": Vector2(w * 0.82, h * 0.20), "r": minf(w * 0.49, h * 0.83), "c": Color("#5d48a6")},
		{"p": Vector2(w * 0.17, h * 0.89), "r": minf(w * 0.46, h * 0.79), "c": Color("#186e83")},
		{"p": Vector2(w * 1.03, h * 0.96), "r": minf(w * 0.39, h * 0.66), "c": Color("#8c3d7c")}
	]
	for glow in glows:
		for layer in range(13, 0, -1):
			var proportion: float = float(layer) / 13.0
			var alpha: float = 0.015 + 0.004 * (1.0 - proportion)
			var shade: Color = glow["c"]
			shade.a = alpha
			draw_circle(glow["p"], glow["r"] * proportion, shade, true, -1.0, true)
	# Light orbital lines suggest a star map without competing with the cards.
	var ring_center := Vector2(w * 0.86, h * 0.44)
	for ring_index in range(3):
		var radius: float = minf(w, h) * (0.23 + float(ring_index) * 0.105)
		draw_arc(ring_center, radius, -1.35, 2.48, 75, Color(0.49, 0.70, 0.90, 0.085), 1.3, true)
	# Fixed positions: no layout jumping, no particle load on mobile.
	for i in range(99):
		var x: float = float((i * 433 + 73) % 997) / 997.0 * w
		var y: float = float((i * 197 + 211) % 991) / 991.0 * h
		var size_px: float = 1.15 if i % 7 != 0 else 1.95
		var alpha: float = 0.12 + float(i % 5) * 0.052
		draw_circle(Vector2(x, y), size_px, Color(0.80, 0.93, 1.0, alpha))
	# A small four-point star, away from the primary reading area.
	var star := Vector2(w * 0.935, h * 0.11)
	var glow_color := Color(0.96, 0.87, 0.65, 0.31)
	draw_line(star + Vector2(-8, 0), star + Vector2(8, 0), glow_color, 1.8, true)
	draw_line(star + Vector2(0, -8), star + Vector2(0, 8), glow_color, 1.8, true)
