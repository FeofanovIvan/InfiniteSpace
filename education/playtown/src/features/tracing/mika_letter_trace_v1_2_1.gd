extends "res://education/playtown/src/features/tracing/mika_letter_trace_v1_2.gd"
## MIKA Trace Letters v1.2.1
## Fine-tunes traced letter geometry:
## - slightly smaller letters with safer padding inside the left tile;
## - smoother curves for letters like S and R;
## - antialiased rounded lines for cleaner shapes.

const LETTER_SCALE: Vector2 = Vector2(0.92, 0.89)
const LETTER_OFFSET_PX: Vector2 = Vector2(0.0, 10.0)
const NORM_Y_OFFSET: float = 0.018
const CURVE_ROUND_PRECISION: int = 24

const CUSTOM_STROKES := {
	"S": [
		[
			Vector2(0.84, 0.13), Vector2(0.76, 0.07), Vector2(0.66, 0.04),
			Vector2(0.55, 0.03), Vector2(0.43, 0.04), Vector2(0.32, 0.08),
			Vector2(0.23, 0.15), Vector2(0.18, 0.24), Vector2(0.20, 0.34),
			Vector2(0.27, 0.42), Vector2(0.39, 0.48), Vector2(0.53, 0.52),
			Vector2(0.66, 0.56), Vector2(0.76, 0.62), Vector2(0.82, 0.70),
			Vector2(0.84, 0.79), Vector2(0.81, 0.87), Vector2(0.74, 0.93),
			Vector2(0.64, 0.97), Vector2(0.52, 0.99), Vector2(0.39, 0.98),
			Vector2(0.28, 0.94), Vector2(0.19, 0.87), Vector2(0.14, 0.80)
		]
	],
	"R": [
		[
			Vector2(0.15, 0.02), Vector2(0.15, 1.00)
		],
		[
			Vector2(0.15, 0.02), Vector2(0.48, 0.02), Vector2(0.58, 0.03),
			Vector2(0.67, 0.06), Vector2(0.75, 0.11), Vector2(0.80, 0.18),
			Vector2(0.84, 0.26), Vector2(0.85, 0.34), Vector2(0.83, 0.42),
			Vector2(0.79, 0.49), Vector2(0.72, 0.54), Vector2(0.64, 0.58),
			Vector2(0.54, 0.60), Vector2(0.44, 0.61), Vector2(0.15, 0.61)
		],
		[
			Vector2(0.38, 0.61), Vector2(0.56, 0.70), Vector2(0.70, 0.82),
			Vector2(0.82, 1.00)
		]
	]
}

func _load_letter() -> void:
	super._load_letter()
	_refine_current_letter()

func _refine_current_letter() -> void:
	var letter: String = _current_letter().to_upper()
	if CUSTOM_STROKES.has(letter):
		_apply_custom_normalized_strokes(CUSTOM_STROKES[letter])
	else:
		_shrink_current_geometry()
	_polish_lines()
	if hint_drawer != null:
		hint_drawer.queue_redraw()

func _shrink_current_geometry() -> void:
	for i in range(strokes.size()):
		var adjusted := PackedVector2Array()
		for p in strokes[i]:
			adjusted.append(Vector2(p.x * LETTER_SCALE.x, p.y * LETTER_SCALE.y) + LETTER_OFFSET_PX)
		strokes[i] = adjusted
		stroke_samples[i] = _resample(adjusted, sample_step)
		if i < outline_lines.size():
			outline_lines[i].points = adjusted
		if i < body_lines.size():
			body_lines[i].points = adjusted
		if i < fill_lines.size():
			fill_lines[i].points = PackedVector2Array()

func _apply_custom_normalized_strokes(source: Array) -> void:
	strokes.clear()
	stroke_samples.clear()
	for i in range(source.size()):
		var pts := _normalized_to_local(_transform_normalized(source[i]))
		strokes.append(pts)
		stroke_samples.append(_resample(pts, sample_step))
		if i < outline_lines.size():
			outline_lines[i].points = pts
		if i < body_lines.size():
			body_lines[i].points = pts
		if i < fill_lines.size():
			fill_lines[i].points = PackedVector2Array()

func _transform_normalized(source_stroke: Array) -> Array:
	var result: Array = []
	for p in source_stroke:
		var q: Vector2 = p - Vector2(0.5, 0.5)
		q = Vector2(q.x * LETTER_SCALE.x, q.y * LETTER_SCALE.y)
		q += Vector2(0.5, 0.5 + NORM_Y_OFFSET)
		result.append(q)
	return result

func _normalized_to_local(source_stroke: Array) -> PackedVector2Array:
	var center: Vector2 = _letter_center()
	var pts := PackedVector2Array()
	for p in source_stroke:
		pts.append(BOX_POS + Vector2(p.x * BOX_SIZE.x, p.y * BOX_SIZE.y) - center)
	return pts

func _polish_lines() -> void:
	for line in outline_lines + body_lines + fill_lines:
		if line == null or not is_instance_valid(line):
			continue
		line.antialiased = true
		line.joint_mode = Line2D.LINE_JOINT_ROUND
		line.begin_cap_mode = Line2D.LINE_CAP_ROUND
		line.end_cap_mode = Line2D.LINE_CAP_ROUND
		line.round_precision = CURVE_ROUND_PRECISION
