extends Node2D
## Gameplay asteroids + fixed-position MIKO crystal debris.
## World-space movement and proximity contacts; no physics-engine RigidBody yet.
## The supplied MIKO asteroid/crystal sprites are drawn as lightweight batches.

signal asteroid_impact(asteroid_type: int, target_name: String, world_position: Vector2)

const WorldAddress = preload("res://scripts/WorldPosition.gd")
const MAX_ASTEROIDS: int = 1
const MAX_ASTEROIDS_FOREIGN: int = 4
const MAX_DEBRIS: int = 350
const ROCK_TYPES: Array[int] = [1, 3, 4, 6]
const ROCK_TEXTURES: Array[Texture2D] = [
	preload("res://asteroid_assets/original/01_gray_cratered.png"),
	preload("res://asteroid_assets/original/03_dark_fissured.png"),
	preload("res://asteroid_assets/original/04_blue_mineral.png"),
	preload("res://asteroid_assets/original/06_violet_mineral.png")
]
const CRYSTAL_FOLDERS: Array[String] = ["01_gray", "03_ember", "04_blue", "06_violet"]
const SHAPES: Array[String] = ["needle_crown", "twin_prisms", "radial_bloom", "broken_geode", "side_spear", "three_shards", "crystal_wedge", "mineral_veins", "star_cluster"]

var _solar: Node
var _npc: Node
var _rng: RandomNumberGenerator = RandomNumberGenerator.new()
var _asteroids: Array[Dictionary] = []
var _debris: Array[Dictionary] = []
var _fragment_textures: Dictionary = {}
var _camera_world: Vector2 = Vector2.ZERO
var _ship_world: Vector2 = Vector2.ZERO
var _view_size: Vector2 = Vector2(1280.0, 720.0)
var _spawn_timer: float = 65.0
var _time: float = 0.0
var _f9_was_pressed: bool = false
var _total_impacts: int = 0


func configure(solar_system: Node, npc_traffic: Node) -> void:
	_solar = solar_system
	_npc = npc_traffic


func _ready() -> void:
	_rng.seed = 790421
	# Rare sightings: the first naturally arrives after 40-65 seconds.
	_spawn_timer = _rng.randf_range(40.0, 65.0)
	queue_redraw()


func set_camera_address(sector: Vector2i, local_position: Vector2, camera_offset: Vector2) -> void:
	_camera_world = Vector2(sector) * WorldAddress.SECTOR_SIZE + local_position + camera_offset


func set_ship_world(ship_position: Vector2) -> void:
	_ship_world = ship_position

func reset_for_region(region_id: String) -> void:
	# Never carry asteroid and collectible world coordinates across galaxies.
	_asteroids.clear()
	_debris.clear()
	_spawn_timer = _rng.randf_range(5.0, 11.0) if region_id not in ["mw", "crossroads"] else _rng.randf_range(40.0, 65.0)
	queue_redraw()


func resize_view(view_size: Vector2) -> void:
	_view_size = view_size


func active_count() -> int:
	return _asteroids.size()


func fragment_count() -> int:
	return _debris.size()


func impact_count() -> int:
	return _total_impacts


func _random_type() -> int:
	var roll: float = _rng.randf()
	if roll < 0.30:
		return 0
	if roll < 0.55:
		return 1
	if roll < 0.83:
		return 2
	return 3


func _spawn_asteroid() -> void:
	var max_rocks: int = MAX_ASTEROIDS if _solar.current_id == "mw" else MAX_ASTEROIDS_FOREIGN
	if _asteroids.size() >= max_rocks:
		return
	# Rare solar fly-by: a fixed, predictable arc around the Sun.
	# It approaches, swings past the Sun outside its collision radius,
	# and heads back toward the outer system. No NPC/player teleporting.
	if _camera_world.length() < 1800.0 and _rng.randf() < 0.40:
		_spawn_solar_flyby()
		return
	var half: Vector2 = _view_size * 0.5
	var edge: int = _rng.randi_range(0, 3)
	var start_screen: Vector2
	if edge == 0:
		start_screen = Vector2(-105.0, _rng.randf_range(-30.0, _view_size.y + 30.0))
	elif edge == 1:
		start_screen = Vector2(_view_size.x + 105.0, _rng.randf_range(-30.0, _view_size.y + 30.0))
	elif edge == 2:
		start_screen = Vector2(_rng.randf_range(-30.0, _view_size.x + 30.0), -105.0)
	else:
		start_screen = Vector2(_rng.randf_range(-30.0, _view_size.x + 30.0), _view_size.y + 105.0)
	var start_world: Vector2 = _camera_world + start_screen - half
	var target_world: Vector2 = _camera_world + Vector2(_rng.randf_range(-half.x * 0.64, half.x * 0.64), _rng.randf_range(-half.y * 0.64, half.y * 0.64))
	# Some incoming rocks naturally cross planets and stations.
	if _solar != null and _rng.randf() < 0.42:
		var bodies: Array[Dictionary] = _solar.get_navigation_bodies()
		var close: Array[Dictionary] = []
		for body in bodies:
			if Vector2(body["world"]).distance_to(_camera_world) < maxf(_view_size.x, _view_size.y) * 0.82:
				close.append(body)
		if not close.is_empty():
			target_world = Vector2(close[_rng.randi_range(0, close.size() - 1)]["world"])
	var direction: Vector2 = (target_world - start_world).normalized()
	if direction.length_squared() < 0.001:
		direction = Vector2.RIGHT
	var speed: float = _rng.randf_range(125.0, 235.0)
	var asteroid: Dictionary = {
		"world": start_world,
		"velocity": direction * speed,
		"size": _rng.randf_range(46.0, 78.0),
		"type": _random_type(),
		"angle": _rng.randf_range(-PI, PI),
		"spin": _rng.randf_range(-0.75, 0.75),
		"turn": _rng.randf_range(-0.26, 0.26),
		"phase": _rng.randf_range(0.0, TAU),
		"speed": speed,
		"age": 0.0
	}
	_asteroids.append(asteroid)


func _spawn_solar_flyby() -> void:
	var start_angle: float = _camera_world.angle() + _rng.randf_range(-0.65, 0.65)
	var direction: float = -1.0 if _rng.randf() < 0.5 else 1.0
	var outside_radius: float = _rng.randf_range(1050.0, 1480.0)
	var perihelion_radius: float = _rng.randf_range(225.0, 340.0)
	var duration: float = _rng.randf_range(14.0, 21.0)
	var initial_position: Vector2 = Vector2.from_angle(start_angle) * outside_radius
	_asteroids.append({
		"world": initial_position,
		"velocity": Vector2.ZERO,
		"size": _rng.randf_range(44.0, 68.0),
		"type": _random_type(),
		"angle": _rng.randf_range(-PI, PI),
		"spin": _rng.randf_range(-0.50, 0.50),
		"turn": 0.0,
		"phase": 0.0,
		"speed": 0.0,
		"age": 0.0,
		"flyby": true,
		"flyby_angle": start_angle,
		"flyby_sign": direction,
		"flyby_outer": outside_radius,
		"flyby_near": perihelion_radius,
		"flyby_duration": duration
	})


func _flyby_position(rock: Dictionary, progress: float) -> Vector2:
	var t: float = clampf(progress, 0.0, 1.0)
	var distance_fraction: float = pow(absf(t * 2.0 - 1.0), 1.36)
	var radius: float = lerpf(float(rock["flyby_near"]), float(rock["flyby_outer"]), distance_fraction)
	var orbit_angle: float = float(rock["flyby_angle"]) + float(rock["flyby_sign"]) * 2.85 * t
	return Vector2.from_angle(orbit_angle) * radius


func _physics_process(delta: float) -> void:
	_time += delta
	_spawn_timer -= delta
	if _spawn_timer <= 0.0:
		_spawn_asteroid()
		_spawn_timer = _rng.randf_range(60.0, 120.0) if _solar.current_id == "mw" else _rng.randf_range(12.0, 23.0)
	# One asteroid per F9 key press (no repeats while the key is held).
	var f9_pressed: bool = Input.is_key_pressed(KEY_F9)
	if f9_pressed and not _f9_was_pressed:
		_spawn_asteroid()
	_f9_was_pressed = f9_pressed
	var bodies: Array[Dictionary] = []
	if _solar != null:
		bodies = _solar.get_navigation_bodies()
	for i in range(_asteroids.size() - 1, -1, -1):
		var asteroid: Dictionary = _asteroids[i]
		var position: Vector2 = Vector2(asteroid["world"])
		if bool(asteroid.get("flyby", false)):
			var flyby_age: float = float(asteroid["age"]) + delta
			var duration: float = float(asteroid["flyby_duration"])
			if flyby_age >= duration:
				_asteroids.remove_at(i)
				continue
			var next_position: Vector2 = _flyby_position(asteroid, flyby_age / duration)
			asteroid["velocity"] = (next_position - position) / maxf(delta, 0.001)
			position = next_position
		else:
			var velocity: Vector2 = Vector2(asteroid["velocity"])
			var spin_turn: float = float(asteroid["turn"]) * (0.35 + 0.65 * sin(_time * 0.64 + float(asteroid["phase"])))
			velocity = velocity.rotated(spin_turn * delta)
			asteroid["velocity"] = velocity
			position += velocity * delta
		asteroid["world"] = position
		asteroid["angle"] = float(asteroid["angle"]) + float(asteroid["spin"]) * delta
		asteroid["age"] = float(asteroid["age"]) + delta
		var rock_radius: float = float(asteroid["size"]) * 0.40
		var target: String = _find_contact(position, rock_radius, bodies)
		if target != "":
			_shatter(asteroid, target)
			_asteroids.remove_at(i)
			continue
		if position.distance_to(_camera_world) > maxf(_view_size.x, _view_size.y) * 2.4 + 500.0 or float(asteroid["age"]) > 48.0:
			_asteroids.remove_at(i)
			continue
		_asteroids[i] = asteroid
	# Asteroids also collide with one another. They shatter into debris.
	var a: int = 0
	while a < _asteroids.size():
		var collided: bool = false
		for b in range(a + 1, _asteroids.size()):
			var left: Dictionary = _asteroids[a]
			var right: Dictionary = _asteroids[b]
			var collision_range: float = (float(left["size"]) + float(right["size"])) * 0.39
			if Vector2(left["world"]).distance_squared_to(Vector2(right["world"])) < collision_range * collision_range:
				_shatter(right, "Asteroid")
				_shatter(left, "Asteroid")
				_asteroids.remove_at(b)
				_asteroids.remove_at(a)
				collided = true
				break
		if not collided:
			a += 1
	for i in range(_debris.size()):
		var fragment: Dictionary = _debris[i]
		var v: Vector2 = Vector2(fragment["velocity"])
		if v.length_squared() > 1.0:
			fragment["world"] = Vector2(fragment["world"]) + v * delta
			fragment["velocity"] = v.move_toward(Vector2.ZERO, 120.0 * delta)
			fragment["rotation"] = float(fragment["rotation"]) + float(fragment["spin"]) * delta
			_debris[i] = fragment
	queue_redraw()


func _find_contact(position: Vector2, radius: float, bodies: Array[Dictionary]) -> String:
	if position.distance_squared_to(_ship_world) <= pow(radius + 35.0, 2.0):
		return "Player"
	for body in bodies:
		var name: String = str(body["name"])
		var body_radius: float = 64.0
		if name == "Sun":
			body_radius = 95.0
		elif name == "EarthStation":
			body_radius = 53.0
		elif name == "Moon":
			body_radius = 19.0
		elif name == "Jupiter":
			body_radius = 118.0
		elif name == "Saturn":
			body_radius = 110.0
		elif name == "Uranus":
			body_radius = 94.0
		elif name == "Neptune":
			body_radius = 96.0
		if position.distance_squared_to(Vector2(body["world"])) <= pow(radius + body_radius, 2.0):
			return name
	if _solar.current_id == "mw" and _npc != null and _npc.try_asteroid_impact(position, radius):
		return "NPC"
	return ""


func _shatter(asteroid: Dictionary, target: String) -> void:
	var asteroid_index: int = int(asteroid["type"])
	var source_id: int = ROCK_TYPES[asteroid_index]
	var burst_point: Vector2 = Vector2(asteroid["world"])
	var fragments_to_spawn: int = _rng.randi_range(3, 6)
	# Fragments persist for the current session. If full, never evict old minerals
	# silently; future releases will serialize debris by world sector.
	fragments_to_spawn = mini(fragments_to_spawn, MAX_DEBRIS - _debris.size())
	var chosen: Array[int] = []
	for variant in range(SHAPES.size()):
		chosen.append(variant)
	for part in range(fragments_to_spawn):
		var selection: int = _rng.randi_range(0, chosen.size() - 1)
		var shape_id: int = chosen.pop_at(selection)
		var theta: float = TAU * float(part) / float(maxi(1, fragments_to_spawn)) + _rng.randf_range(-0.24, 0.24)
		var tangent: Vector2 = Vector2.from_angle(theta)
		_debris.append({
			"world": burst_point + tangent * _rng.randf_range(7.0, 18.0),
			"velocity": tangent * _rng.randf_range(65.0, 120.0),
			"size": _rng.randf_range(23.0, 40.0),
			"kind": asteroid_index,
			"shape": shape_id,
			"rotation": _rng.randf_range(-PI, PI),
			"spin": _rng.randf_range(-1.7, 1.7),
			"collectible": source_id != 1
		})
	_total_impacts += 1
	asteroid_impact.emit(source_id, target, burst_point)


func _fragment_texture(kind: int, variant: int) -> Texture2D:
	var texture_key: String = "%d_%d" % [kind, variant]
	if not _fragment_textures.has(texture_key):
		var path: String = "res://" + "asteroid_assets/fragments/%s/%s.png" % [CRYSTAL_FOLDERS[kind], SHAPES[variant]]
		_fragment_textures[texture_key] = load(path) as Texture2D
	return _fragment_textures[texture_key] as Texture2D


func _visible(screen: Vector2, extra: float = 70.0) -> bool:
	return screen.x >= -extra and screen.y >= -extra and screen.x <= _view_size.x + extra and screen.y <= _view_size.y + extra


func _draw() -> void:
	var screen_center: Vector2 = _view_size * 0.5
	for fragment in _debris:
		var screen: Vector2 = Vector2(fragment["world"]) - _camera_world + screen_center
		if not _visible(screen):
			continue
		var tex: Texture2D = _fragment_texture(int(fragment["kind"]), int(fragment["shape"]))
		if tex == null:
			continue
		var scale_factor: float = float(fragment["size"]) / 320.0
		draw_set_transform(screen, float(fragment["rotation"]), Vector2.ONE * scale_factor)
		draw_texture_rect(tex, Rect2(Vector2(-160.0, -160.0), Vector2(320.0, 320.0)), false)
	for asteroid in _asteroids:
		var screen: Vector2 = Vector2(asteroid["world"]) - _camera_world + screen_center
		if not _visible(screen):
			continue
		var tex: Texture2D = ROCK_TEXTURES[int(asteroid["type"])]
		var scale_factor: float = float(asteroid["size"]) / 512.0
		draw_set_transform(screen, float(asteroid["angle"]), Vector2.ONE * scale_factor)
		draw_texture_rect(tex, Rect2(Vector2(-256.0, -256.0), Vector2(512.0, 512.0)), false)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
