extends Node2D
## Extremely cheap distant sky phenomena. No imported animations or particles.
## At most two thin meteors, plus a few small twinkling distant stars.
## Independent movement continues while the ship is not accelerating.

const MAX_METEORS: int = 2
const TWINKLE_COUNT: int = 4
const METEOR_MIN_INTERVAL: float = 8.0
const METEOR_MAX_INTERVAL: float = 15.0
const SKY_PARALLAX: float = 0.34

var _screen: Vector2 = Vector2(1280.0, 720.0)
var _random: RandomNumberGenerator = RandomNumberGenerator.new()
var _meteors: Array[Dictionary] = []
var _twinkles: Array[Dictionary] = []
var _spawn_countdown: float = 2.0
var _elapsed: float = 0.0


func _ready() -> void:
	_random.randomize()
	set_process(true)
	resize_sky(get_viewport_rect().size)


func resize_sky(view: Vector2) -> void:
	_screen = view
	_twinkles.clear()
	for i in range(TWINKLE_COUNT):
		_twinkles.append({
			"position": Vector2(_random.randf() * _screen.x, _random.randf() * _screen.y),
			"phase": _random.randf_range(0.0, TAU),
			"frequency": _random.randf_range(0.8, 1.7),
			"size": _random.randf_range(0.75, 1.7)
		})
	queue_redraw()


func advance_camera(world_camera_delta: Vector2) -> void:
	# Moving the camera shifts all distant lights very slightly.
	var screen_shift: Vector2 = -world_camera_delta * SKY_PARALLAX
	for i in range(_meteors.size()):
		var meteor_position: Vector2 = _meteors[i]["position"]
		_meteors[i]["position"] = meteor_position + screen_shift
	for i in range(_twinkles.size()):
		var old_position: Vector2 = _twinkles[i]["position"]
		_twinkles[i]["position"] = Vector2(
			fposmod(old_position.x + screen_shift.x, maxf(_screen.x, 1.0)),
			fposmod(old_position.y + screen_shift.y, maxf(_screen.y, 1.0))
		)
	queue_redraw()


func _process(delta: float) -> void:
	_elapsed += delta
	_spawn_countdown -= delta
	if _spawn_countdown <= 0.0:
		if _meteors.size() < MAX_METEORS:
			_spawn_meteor()
		_spawn_countdown = _random.randf_range(METEOR_MIN_INTERVAL, METEOR_MAX_INTERVAL)
	for i in range(_meteors.size() - 1, -1, -1):
		var meteor: Dictionary = _meteors[i]
		meteor["position"] = meteor["position"] + meteor["direction"] * meteor["speed"] * delta
		meteor["life"] = float(meteor["life"]) + delta
		_meteors[i] = meteor
		if float(meteor["life"]) >= float(meteor["duration"]):
			_meteors.remove_at(i)
	queue_redraw()


func _spawn_meteor() -> void:
	# Short streak entering from one of the side edges.
	var left_to_right: bool = _random.randf() > 0.5
	var start_x: float = -95.0 if left_to_right else _screen.x + 95.0
	var start_y: float = _random.randf_range(_screen.y * 0.12, _screen.y * 0.78)
	var heading: Vector2 = Vector2(1.0 if left_to_right else -1.0, _random.randf_range(-0.22, 0.22)).normalized()
	var speed: float = _random.randf_range(92.0, 165.0)
	_meteors.append({
		"position": Vector2(start_x, start_y),
		"direction": heading,
		"speed": speed,
		"life": 0.0,
		"duration": (_screen.x + 260.0) / (speed * maxf(absf(heading.x), 0.4)),
		"length": _random.randf_range(38.0, 88.0),
		"warm": _random.randf() < 0.22
	})


func _draw() -> void:
	# One sinusoid per star; no shaders, timers or texture allocations.
	for t in _twinkles:
		var p: Vector2 = t["position"]
		var twinkle_phase: float = _elapsed * float(t["frequency"]) + float(t["phase"])
		var level: float = pow(maxf(0.0, sin(twinkle_phase)), 4.0)
		if level < 0.03:
			continue
		var radius: float = float(t["size"])
		draw_circle(p, radius + 0.8 * level, Color(0.25, 0.53, 0.83, 0.025 * level))
		draw_circle(p, radius, Color(0.68, 0.88, 1.0, 0.14 * level))
	for meteor in _meteors:
		var p: Vector2 = meteor["position"]
		var facing: Vector2 = meteor["direction"]
		var age: float = float(meteor["life"])
		var duration: float = float(meteor["duration"])
		var fade: float = minf(1.0, age / 0.7) * minf(1.0, (duration - age) / 1.6)
		if fade <= 0.0:
			continue
		var trail_length: float = float(meteor["length"])
		var tone: Color = Color(1.0, 0.80, 0.52) if bool(meteor["warm"]) else Color(0.65, 0.87, 1.0)
		for layer in range(5):
			var portion: float = float(layer + 1) / 5.0
			var start: Vector2 = p - facing * (trail_length * portion)
			var end: Vector2 = p - facing * (trail_length * float(layer) / 5.0)
			draw_line(start, end, Color(tone.r, tone.g, tone.b, 0.11 * fade * (1.0 - portion * 0.78)), 3.0, true)
		draw_line(p - facing * 10.0, p, Color(tone.r, tone.g, tone.b, 0.62 * fade), 1.5, true)
		draw_circle(p, 5.5, Color(tone.r, tone.g, tone.b, 0.06 * fade))
		draw_circle(p, 1.5, Color(0.95, 0.98, 1.0, 0.95 * fade))
