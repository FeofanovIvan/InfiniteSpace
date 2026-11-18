extends RefCounted
## Closed polar-spline race corridors. All calculations use world units.
const SOLAR = preload("res://scripts/SolarSystem.gd")
const SAMPLES: int = 240
const TRACK_SEPARATION: float = 55.0
const SHIP_MARGIN: float = 48.0
const PLANET_MARGIN: float = 45.0

static func bodies() -> Array[Dictionary]:
	var result: Array[Dictionary] = [{"name": "Sun", "world": Vector2.ZERO, "radius": 160.0}, {"name": "Earth", "world": Vector2(565.0, 0.0), "radius": 115.0}]
	for item in SOLAR.PLANET_ORBITS:
		result.append({"name": str(item["name"]), "world": Vector2.from_angle(float(item["phase"])) * float(item["orbit"]), "radius": float(item["size"]) * 0.72 + (70.0 if str(item["name"]) == "Saturn" else 0.0)})
	return result

# The existing circular radar displays approximately 2250 world units from the Sun.
# Keep BOTH edges of the race corridor inside that same radius.
const RADAR_RADIUS: float = 3500.0
const RADAR_PADDING: float = 55.0

static func generate(seed_value: int, target_length: float = 12000.0, width: float = 650.0) -> Dictionary:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	var obstacles: Array[Dictionary] = bodies()
	var maximum_center_radius: float = RADAR_RADIUS - RADAR_PADDING - width * 0.5
	var best := PackedVector2Array()
	var best_score: float = INF
	var best_length: float = 0.0
	var best_margin: float = -INF
	var best_separation: float = -INF
	# Generate inside the fixed radar disc; never enlarge a failed candidate.
	# Higher harmonics yield bends while a radial graph avoids self crossings.
	for attempt in range(220):
		var base_radius: float = rng.randf_range(2050.0, maximum_center_radius * 0.90)
		var a: float = rng.randf_range(0.14, 0.28)
		var b: float = rng.randf_range(0.045, 0.13)
		var c: float = rng.randf_range(0.012, 0.055)
		var pa: float = rng.randf_range(0.0, TAU)
		var pb: float = rng.randf_range(0.0, TAU)
		var pc: float = rng.randf_range(0.0, TAU)
		var frequency: int = rng.randi_range(3, 6)
		var curve := PackedVector2Array()
		for i in range(SAMPLES):
			var t: float = TAU * float(i) / float(SAMPLES)
			var radius: float = base_radius * (1.0 + a * sin(float(frequency) * t + pa) + b * sin(float(frequency + 2) * t + pb) + c * sin(float(frequency + 4) * t + pc))
			curve.append(Vector2.from_angle(t) * minf(radius, maximum_center_radius))
		var length: float = _length(curve)
		var margin: float = _minimum_margin(curve, obstacles) - width * 0.5 - PLANET_MARGIN
		# A smooth centerline alone is not enough: two distant sections of a
		# wide corridor must never overlap, and bends need room for both edges.
		var separation: float = _corridor_clearance(curve, width)
		# Prefer clear corridors and the requested length, but NEVER breach radar.
		var score: float = maxf(0.0, -margin) * 250.0 + maxf(0.0, -separation) * 350.0 + absf(length - target_length)
		if score < best_score:
			best = curve
			best_score = score
			best_length = length
			best_margin = margin
			best_separation = separation
		if margin >= 0.0 and separation >= 0.0 and absf(length - target_length) < target_length * 0.08:
			break
	return {"points": best, "seed": seed_value, "length": best_length, "target_length": target_length, "width": width, "clearance": best_margin, "corridor_clearance": best_separation, "radar_radius": RADAR_RADIUS, "within_radar": true}

# Sampled non-neighbor corridor separation and local radius of curvature.
# Negative values mean the chosen corridor is too wide for that bend/spacing.
static func _corridor_clearance(points: PackedVector2Array, width: float) -> float:
	var n: int = points.size()
	var half: float = width * 0.5
	var worst: float = INF
	# For a regular closed curve the local curvature radius must exceed the
	# half-width; otherwise offset boundaries fold back into little crosses.
	for i in range(0, n, 2):
		var a: Vector2 = points[(i - 2 + n) % n]
		var b: Vector2 = points[i]
		var c: Vector2 = points[(i + 2) % n]
		var ab: Vector2 = b - a
		var bc: Vector2 = c - b
		var ac: Vector2 = c - a
		var cross: float = absf(ab.cross(ac))
		if cross > 0.0001:
			var radius: float = ab.length() * bc.length() * ac.length() / (2.0 * cross)
			worst = minf(worst, radius - half - 55.0)
	# Distant segments may be close even if the centerline does not cross.
	# Exclude a local neighborhood (about 10% of the route), whose points
	# naturally sit close together along the same piece of track.
	var skip: int = maxi(12, n / 12)
	for i in range(0, n, 3):
		for j in range(i + skip, n, 3):
			if n - (j - i) < skip:
				continue
			worst = minf(worst, points[i].distance_to(points[j]) - width - TRACK_SEPARATION)
	return worst

static func _average(points: PackedVector2Array) -> Vector2:
	var center := Vector2.ZERO
	for point in points:
		center += point
	return center / maxf(1.0, float(points.size()))

static func _length(points: PackedVector2Array) -> float:
	var result: float = 0.0
	for i in range(points.size()):
		result += points[i].distance_to(points[(i + 1) % points.size()])
	return result

static func _minimum_margin(points: PackedVector2Array, obstacles: Array[Dictionary]) -> float:
	var result: float = INF
	for p in points:
		for obstacle in obstacles:
			result = minf(result, p.distance_to(Vector2(obstacle["world"])) - float(obstacle["radius"]))
	return result

static func nearest_on_track(world: Vector2, points: PackedVector2Array) -> Dictionary:
	var best_distance: float = INF
	var nearest := Vector2.ZERO
	var tangent := Vector2.RIGHT
	var index: int = 0
	for i in range(points.size()):
		var a: Vector2 = points[i]
		var b: Vector2 = points[(i + 1) % points.size()]
		var segment: Vector2 = b - a
		var t: float = clampf((world - a).dot(segment) / maxf(segment.length_squared(), 0.0001), 0.0, 1.0)
		var closest: Vector2 = a + segment * t
		var distance: float = world.distance_squared_to(closest)
		if distance < best_distance:
			best_distance = distance
			nearest = closest
			tangent = segment.normalized()
			index = i
	return {"point": nearest, "tangent": tangent, "index": index, "distance": sqrt(best_distance)}
