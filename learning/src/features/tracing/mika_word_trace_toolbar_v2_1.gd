extends "res://learning/src/features/tracing/mika_word_trace_toolbar_v2.gd"
## MIKA Trace Words v2.1
## Makes traced word geometry smoother, especially for rounded letters like S,
## C, O, G, Q and the bowls/legs in R.

const SMOOTHING_PASSES: int = 2
const CURVE_ROUND_PRECISION_V21: int = 28

func _load_word(play_voice: bool = true) -> void:
	super._load_word(play_voice)
	_smooth_current_word_geometry()

func _smooth_current_word_geometry() -> void:
	if strokes.is_empty():
		return
	for i in range(strokes.size()):
		var src: PackedVector2Array = strokes[i]
		var smoothed: PackedVector2Array = _chaikin(src, SMOOTHING_PASSES)
		if smoothed.size() >= 2:
			strokes[i] = smoothed
			stroke_samples[i] = _resample(smoothed, sample_step)
			if i < outline_lines.size() and outline_lines[i] != null and is_instance_valid(outline_lines[i]):
				outline_lines[i].points = smoothed
			if i < body_lines.size() and body_lines[i] != null and is_instance_valid(body_lines[i]):
				body_lines[i].points = smoothed
			if i < fill_lines.size() and fill_lines[i] != null and is_instance_valid(fill_lines[i]):
				fill_lines[i].points = PackedVector2Array()
	_polish_trace_lines_v21()
	if hint_drawer != null:
		hint_drawer.queue_redraw()

func _chaikin(points: PackedVector2Array, passes: int) -> PackedVector2Array:
	if points.size() < 3 or passes <= 0:
		return points
	var current: PackedVector2Array = points
	for _i in range(passes):
		if current.size() < 3:
			break
		var next_pts := PackedVector2Array()
		next_pts.append(current[0])
		for idx in range(current.size() - 1):
			var p0: Vector2 = current[idx]
			var p1: Vector2 = current[idx + 1]
			var q: Vector2 = p0.lerp(p1, 0.25)
			var r: Vector2 = p0.lerp(p1, 0.75)
			next_pts.append(q)
			next_pts.append(r)
		next_pts.append(current[current.size() - 1])
		current = next_pts
	return current

func _polish_trace_lines_v21() -> void:
	for line in outline_lines:
		if line != null and is_instance_valid(line):
			line.antialiased = true
			line.joint_mode = Line2D.LINE_JOINT_ROUND
			line.begin_cap_mode = Line2D.LINE_CAP_ROUND
			line.end_cap_mode = Line2D.LINE_CAP_ROUND
			line.round_precision = CURVE_ROUND_PRECISION_V21
	for line in body_lines:
		if line != null and is_instance_valid(line):
			line.antialiased = true
			line.joint_mode = Line2D.LINE_JOINT_ROUND
			line.begin_cap_mode = Line2D.LINE_CAP_ROUND
			line.end_cap_mode = Line2D.LINE_CAP_ROUND
			line.round_precision = CURVE_ROUND_PRECISION_V21
	for line in fill_lines:
		if line != null and is_instance_valid(line):
			line.antialiased = true
			line.joint_mode = Line2D.LINE_JOINT_ROUND
			line.begin_cap_mode = Line2D.LINE_CAP_ROUND
			line.end_cap_mode = Line2D.LINE_CAP_ROUND
			line.round_precision = CURVE_ROUND_PRECISION_V21
