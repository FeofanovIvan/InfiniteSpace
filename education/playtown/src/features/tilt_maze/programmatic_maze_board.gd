extends Node2D

const DESIGN_SIZE := 1000.0
const CENTER := Vector2(500.0, 500.0)
const OUTER_RADIUS := 472.0
const WALL_WIDTH := 34.0
const START_POINT := Vector2(231.3, 159.5)
const RING_RADII := [382.0, 292.0, 202.0, 116.0]
const GAP_SIZE_RANGES := [
	Vector2(0.50, 0.70),
	Vector2(0.54, 0.76),
	Vector2(0.62, 0.88),
	Vector2(1.05, 1.30)
]
const MIN_GAP_DISTANCE := 0.78
const MIN_PARTITION_DISTANCE := 0.88
var rng := RandomNumberGenerator.new()
var outer_gap_center := -2.25
var outer_gap_size := 0.50
var rings: Array = []
var radial_walls: Array = []

func _ready() -> void:
	generate_layout()

func generate_layout() -> void:
	rng.randomize()
	outer_gap_center = rng.randf_range(-PI, PI)
	outer_gap_size = rng.randf_range(0.46, 0.62)
	rings.clear()
	var gap_angles: Array[float] = [outer_gap_center]
	for index in range(RING_RADII.size()):
		var size_range: Vector2 = GAP_SIZE_RANGES[index]
		var gap_angle := _pick_separated_angle(gap_angles, MIN_GAP_DISTANCE)
		rings.append([
			RING_RADII[index],
			gap_angle,
			rng.randf_range(size_range.x, size_range.y)
		])
		gap_angles.append(gap_angle)
	radial_walls.clear()
	var partition_angles: Array[float] = []
	for index in range(RING_RADII.size()):
		var from_radius: float = RING_RADII[index]
		var to_radius: float = OUTER_RADIUS if index == 0 else RING_RADII[index - 1]
		var inner_gap: float = rings[index][1]
		var inner_gap_size: float = rings[index][2]
		var outer_gap: float = outer_gap_center if index == 0 else rings[index - 1][1]
		var outer_gap_size_value: float = outer_gap_size if index == 0 else rings[index - 1][2]
		var wall_angle := _pick_partition_angle(
			inner_gap,
			inner_gap_size,
			outer_gap,
			outer_gap_size_value,
			index == 0,
			partition_angles
		)
		radial_walls.append([wall_angle, from_radius, to_radius])
		partition_angles.append(wall_angle)
	queue_redraw()

func _pick_partition_angle(
	inner_gap: float,
	inner_gap_size: float,
	outer_gap: float,
	outer_gap_size_value: float,
	avoid_start: bool,
	partition_angles: Array[float]
) -> float:
	var start_angle := atan2(START_POINT.y - CENTER.y, START_POINT.x - CENTER.x)
	for _attempt in range(80):
		var candidate := rng.randf_range(-PI, PI)
		var clear_inner := inner_gap_size * 0.5 + 0.28
		var clear_outer := outer_gap_size_value * 0.5 + 0.28
		if _angle_distance(candidate, inner_gap) <= clear_inner:
			continue
		if _angle_distance(candidate, outer_gap) <= clear_outer:
			continue
		if avoid_start and _angle_distance(candidate, start_angle) <= 0.22:
			continue
		if not _is_separated(candidate, partition_angles, MIN_PARTITION_DISTANCE):
			continue
		return candidate
	return _pick_best_separated_angle(partition_angles)

func _pick_separated_angle(existing_angles: Array[float], minimum_distance: float) -> float:
	for _attempt in range(80):
		var candidate := rng.randf_range(-PI, PI)
		if _is_separated(candidate, existing_angles, minimum_distance):
			return candidate
	return _pick_best_separated_angle(existing_angles)

func _is_separated(candidate: float, existing_angles: Array[float], minimum_distance: float) -> bool:
	for existing_angle in existing_angles:
		if _angle_distance(candidate, existing_angle) < minimum_distance:
			return false
	return true

func _pick_best_separated_angle(existing_angles: Array[float]) -> float:
	if existing_angles.is_empty():
		return rng.randf_range(-PI, PI)
	var best_angle := 0.0
	var best_distance := -1.0
	for index in range(96):
		var candidate := -PI + TAU * float(index) / 96.0
		var nearest_distance := PI
		for existing_angle in existing_angles:
			nearest_distance = minf(nearest_distance, _angle_distance(candidate, existing_angle))
		if nearest_distance > best_distance:
			best_distance = nearest_distance
			best_angle = candidate
	return best_angle

func _angle_distance(first: float, second: float) -> float:
	return absf(wrapf(first - second, -PI, PI))

func _draw() -> void:
	draw_circle(CENTER + Vector2(0, 12), OUTER_RADIUS + 16.0, Color(0.25, 0.48, 0.17, 0.22))
	draw_circle(CENTER, OUTER_RADIUS + 13.0, Color(0.28, 0.61, 0.20))
	draw_circle(CENTER, OUTER_RADIUS - 7.0, Color(1.0, 0.94, 0.72))
	_draw_wall_arc(
		OUTER_RADIUS,
		outer_gap_center + outer_gap_size * 0.5,
		outer_gap_center + TAU - outer_gap_size * 0.5,
		WALL_WIDTH + 4.0
	)
	for ring in rings:
		var radius: float = ring[0]
		var gap_center: float = ring[1]
		var gap_size: float = ring[2]
		_draw_wall_arc(radius, gap_center + gap_size * 0.5, gap_center + TAU - gap_size * 0.5, WALL_WIDTH)
	for wall in radial_walls:
		var angle: float = wall[0]
		var from_radius: float = wall[1]
		var to_radius: float = wall[2]
		var direction := Vector2(cos(angle), sin(angle))
		_draw_wall_segment(CENTER + direction * from_radius, CENTER + direction * to_radius)
	draw_circle(CENTER, 75.0, Color(1.0, 0.57, 0.05))
	draw_circle(CENTER, 63.0, Color(1.0, 0.88, 0.23))
	draw_circle(CENTER + Vector2(-21, -8), 7.0, Color(0.10, 0.10, 0.08))
	draw_circle(CENTER + Vector2(21, -8), 7.0, Color(0.10, 0.10, 0.08))
	var smile := PackedVector2Array()
	for i in range(25):
		var angle := lerpf(0.18, PI - 0.18, float(i) / 24.0)
		smile.append(CENTER + Vector2(cos(angle) * 29.0, sin(angle) * 21.0 + 3.0))
	draw_polyline(smile, Color(0.15, 0.12, 0.05), 5.0, true)

func _draw_wall_arc(radius: float, start_angle: float, end_angle: float, width: float) -> void:
	var points := PackedVector2Array()
	var count := maxi(28, int((end_angle - start_angle) * radius / 12.0))
	for i in range(count + 1):
		var angle := lerpf(start_angle, end_angle, float(i) / float(count))
		points.append(CENTER + Vector2(cos(angle), sin(angle)) * radius)
	var shadow := PackedVector2Array()
	for point in points:
		shadow.append(point + Vector2(0, 7))
	draw_polyline(shadow, Color(0.18, 0.42, 0.12, 0.30), width + 8.0, true)
	draw_polyline(points, Color(0.20, 0.49, 0.12), width + 6.0, true)
	draw_polyline(points, Color(0.31, 0.68, 0.18), width, true)
	draw_polyline(points, Color(0.52, 0.82, 0.28), 7.0, true)
	_draw_wall_cap(points[0], width)
	_draw_wall_cap(points[points.size() - 1], width)

func _draw_wall_segment(from: Vector2, to: Vector2) -> void:
	draw_line(from + Vector2(0, 7), to + Vector2(0, 7), Color(0.54, 0.27, 0.04, 0.28), WALL_WIDTH + 8.0, true)
	draw_line(from, to, Color(0.78, 0.36, 0.04), WALL_WIDTH + 6.0, true)
	draw_line(from, to, Color(1.0, 0.57, 0.05), WALL_WIDTH, true)
	draw_line(from, to, Color(1.0, 0.79, 0.20), 7.0, true)
	_draw_partition_cap(from)
	_draw_partition_cap(to)

func _draw_wall_cap(point: Vector2, width: float) -> void:
	draw_circle(point + Vector2(0, 7), (width + 8.0) * 0.5, Color(0.18, 0.42, 0.12, 0.30))
	draw_circle(point, (width + 6.0) * 0.5, Color(0.20, 0.49, 0.12))
	draw_circle(point, width * 0.5, Color(0.31, 0.68, 0.18))
	draw_circle(point - Vector2(0, width * 0.24), 3.5, Color(0.52, 0.82, 0.28))

func _draw_partition_cap(point: Vector2) -> void:
	draw_circle(point + Vector2(0, 7), (WALL_WIDTH + 8.0) * 0.5, Color(0.54, 0.27, 0.04, 0.28))
	draw_circle(point, (WALL_WIDTH + 6.0) * 0.5, Color(0.78, 0.36, 0.04))
	draw_circle(point, WALL_WIDTH * 0.5, Color(1.0, 0.57, 0.05))
	draw_circle(point - Vector2(0, WALL_WIDTH * 0.24), 3.5, Color(1.0, 0.79, 0.20))

func hits_wall(point: Vector2, ball_radius: float) -> bool:
	var relative := point - CENTER
	var radius := relative.length()
	if radius + ball_radius >= OUTER_RADIUS - WALL_WIDTH * 0.5:
		return true
	var angle := atan2(relative.y, relative.x)
	var clearance := ball_radius + WALL_WIDTH * 0.5
	for ring in rings:
		var ring_radius: float = ring[0]
		var gap_center: float = ring[1]
		var gap_size: float = ring[2]
		if absf(radius - ring_radius) <= clearance and not _angle_in_gap(angle, gap_center, gap_size, radius, clearance):
			return true
	for wall in radial_walls:
		var wall_angle: float = wall[0]
		var from_radius: float = wall[1]
		var to_radius: float = wall[2]
		var direction := Vector2(cos(wall_angle), sin(wall_angle))
		var from := CENTER + direction * from_radius
		var to := CENTER + direction * to_radius
		if _distance_to_segment(point, from, to) <= clearance:
			return true
	return false

func _angle_in_gap(angle: float, gap_center: float, gap_size: float, radius: float, clearance: float) -> bool:
	var angular_clearance := asin(clampf(clearance / maxf(radius, clearance + 1.0), 0.0, 0.95))
	var usable_half_gap := gap_size * 0.5 - angular_clearance
	return absf(wrapf(angle - gap_center, -PI, PI)) < usable_half_gap

func _distance_to_segment(point: Vector2, from: Vector2, to: Vector2) -> float:
	var segment := to - from
	var length_squared := segment.length_squared()
	if length_squared <= 0.001:
		return point.distance_to(from)
	var amount := clampf((point - from).dot(segment) / length_squared, 0.0, 1.0)
	return point.distance_to(from + segment * amount)
