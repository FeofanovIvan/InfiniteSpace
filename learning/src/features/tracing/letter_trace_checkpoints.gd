extends Node2D
var game: Node2D
var _time := 0.0
var dot_end_stroke: int = -1
const DOT_COLOR := Color(0.35, 0.35, 0.35, 0.45)
const DOT_SPACING_PX := 46.0
const MARKER_COLOR := Color(0.13, 0.55, 0.60)
func _ready() -> void:
	z_index = 3
func _process(delta: float) -> void:
	_time += delta
	queue_redraw()
func _draw() -> void:
	if game == null or game.letter_done:
		return
	var dot_every: int = maxi(1, int(DOT_SPACING_PX / game.sample_step))
	for s in range(game.strokes.size()):
		if s < game.cur_stroke:
			continue
		if dot_end_stroke >= 0 and s >= dot_end_stroke:
			continue
		var samples: Array = game.stroke_samples[s]
		var from_idx: int = game.sample_idx if s == game.cur_stroke else 0
		var i := from_idx + dot_every
		while i < samples.size():
			draw_circle(samples[i], 6.0, DOT_COLOR)
			i += dot_every
	var cur_samples: Array = game.stroke_samples[game.cur_stroke]
	var idx: int = game.sample_idx
	var p: Vector2 = cur_samples[idx]
	var ahead: Vector2 = cur_samples[mini(idx + 4, cur_samples.size() - 1)]
	var dir: Vector2 = (ahead - p).normalized()
	if dir == Vector2.ZERO:
		dir = Vector2.RIGHT
	var pulse := 1.0 + 0.1 * sin(_time * 5.0)
	var r := 30.0 * pulse
	draw_circle(p, r + 5.0, Color(1, 1, 1, 0.9))
	draw_circle(p, r, MARKER_COLOR)
	var tip: Vector2 = p + dir * r * 0.55
	var back: Vector2 = p - dir * r * 0.35
	var side: Vector2 = dir.orthogonal() * r * 0.38
	draw_line(back, tip, Color(1, 1, 1), 6.0)
	draw_colored_polygon(
		PackedVector2Array([tip + dir * r * 0.28, tip + side - dir * r * 0.1, tip - side - dir * r * 0.1]),
		Color(1, 1, 1)
	)
