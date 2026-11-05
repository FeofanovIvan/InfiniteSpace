class_name BasketballTrajectory
extends Control

# Visual changes only. The original quadratic trajectory is preserved.
const STEPS := 72
const HEAD_LENGTH := 30.0
const HEAD_HALF_WIDTH := 15.0
const TAIL_HALF_WIDTH := 21.0
const NECK_HALF_WIDTH := 4.0
const ARROW_COLOR := Color(0.96, 0.16, 0.19, 0.90)
const EDGE_COLOR := Color(1.0, 1.0, 1.0, 0.95)

var start_point := Vector2.ZERO
var end_point := Vector2.ZERO
var arc_height := 240.0


func configure(from: Vector2, to: Vector2, height: float) -> void:
	start_point = from
	end_point = to
	arc_height = height
	queue_redraw()


func _draw() -> void:
	if start_point.distance_squared_to(end_point) < 4.0:
		return

	# Exactly the same control point and quadratic arc as the original script.
	var control := Vector2((start_point.x + end_point.x) * 0.5, minf(start_point.y, end_point.y) - arc_height)
	var curve := PackedVector2Array()
	for i in range(STEPS + 1):
		curve.append(_quadratic(start_point, control, end_point, float(i) / float(STEPS)))

	# Find the arrowhead base along the ACTUAL curved path, not along a
	# straight line from the target. This keeps the arrowhead integrated.
	var target_head_length := minf(HEAD_LENGTH, start_point.distance_to(end_point) * 0.25)
	var base_index := STEPS - 1
	var remaining := 0.0
	while base_index > 1:
		remaining += curve[base_index + 1].distance_to(curve[base_index])
		if remaining >= target_head_length:
			break
		base_index -= 1

	var neck_center := curve[base_index]
	var tangent := (curve[min(base_index + 1, STEPS)] - curve[maxi(base_index - 1, 0)]).normalized()
	if tangent.length_squared() < 0.001:
		tangent = (end_point - start_point).normalized()
	var normal := tangent.orthogonal()

	# Single continuous shape: triple-width rounded tail, gently tapered
	# shaft, shoulders and pointed head. No line is drawn under or past tip.
	var left := PackedVector2Array()
	var right := PackedVector2Array()
	for i in range(base_index + 1):
		var direction := (curve[min(i + 1, STEPS)] - curve[maxi(i - 1, 0)]).normalized()
		if direction.length_squared() < 0.001:
			direction = tangent
		var side := direction.orthogonal()
		var progress := float(i) / float(maxi(base_index, 1))
		var half_width := lerpf(TAIL_HALF_WIDTH, NECK_HALF_WIDTH, progress)
		left.append(curve[i] + side * half_width)
		right.append(curve[i] - side * half_width)

	# Draw short convex quads instead of one long concave polygon.
	# On strongly curved shots the old polygon could self-intersect,
	# making the red fill disappear and leaving just the white outline.
	for i in range(base_index):
		var section := PackedVector2Array([left[i], left[i + 1], right[i + 1], right[i]])
		draw_colored_polygon(section, ARROW_COLOR)

	# Continue the shaft straight into the arrowhead without drawing
	# a centre-line over the tip. The little shoulder bridge is convex.
	var left_shoulder := neck_center + normal * HEAD_HALF_WIDTH
	var right_shoulder := neck_center - normal * HEAD_HALF_WIDTH
	draw_colored_polygon(PackedVector2Array([left[base_index], left_shoulder, right_shoulder, right[base_index]]), ARROW_COLOR)
	draw_colored_polygon(PackedVector2Array([left_shoulder, end_point, right_shoulder]), ARROW_COLOR)

	# The complete silhouette gets one consistent white border.
	# Alpha remains fixed: no conditional opacity or hover/aim variants.
	var left_edge := left.duplicate()
	left_edge.append(left_shoulder)
	left_edge.append(end_point)
	var right_edge := right.duplicate()
	right_edge.append(right_shoulder)
	right_edge.append(end_point)
	draw_polyline(left_edge, EDGE_COLOR, 2.6, true)
	draw_polyline(right_edge, EDGE_COLOR, 2.6, true)
	# Rounded start, matching the same fixed red and white colours.
	draw_circle(start_point, TAIL_HALF_WIDTH, EDGE_COLOR, true)
	draw_circle(start_point, TAIL_HALF_WIDTH - 2.0, ARROW_COLOR, true)


func _quadratic(a: Vector2, b: Vector2, c: Vector2, t: float) -> Vector2:
	var inv := 1.0 - t
	return inv * inv * a + 2.0 * inv * t * b + t * t * c
