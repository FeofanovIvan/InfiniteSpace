extends Node2D
## Lightweight NPC traffic with anchored planet landing / takeoff animations.
## World-space routes and weighted roles remain from v0.16. NPCs approach a
## moving body, hover with it, shrink into its surface, remain docked,
## reappear and depart; some still hyperjump beyond the outer system.
## All sprites + exhaust are batched into a single canvas item for mobile.

signal hyperjump_started(role: String, world: Vector2)
signal landing_completed(role: String, destination: String)
signal takeoff_started(role: String, destination: String)

const WorldAddress = preload("res://scripts/WorldPosition.gd")
const LandingMotion = preload("res://scripts/LandingMotion.gd")
const HyperjumpMotion = preload("res://scripts/HyperjumpMotion.gd")
const NpcJumpVisual = preload("res://scripts/NpcJumpVisual.gd")
# Only these inhabited worlds and the independent Earth station are landing ports.
# Mercury, Saturn and Uranus remain visible but aren't active landing destinations.
const LANDING_PORTS = ["Earth", "Venus", "Mars", "Jupiter", "Neptune", "EarthStation"]
const POPULATION: int = 14
const OUTER_JUMP_RADIUS: float = 2500.0
const CHARGE_TIME: float = 0.43
const DASH_TIME: float = 0.36
const RESPAWN_DELAY: float = 2.5
const SPEED_ACCEL: float = 240.0
const MAX_CLOUDS: int = 15
const APPROACH_START_RADIUS: float = 205.0
const APPROACH_TIME: float = 1.10
const HOVER_TIME: float = 0.52
const LANDING_TIME: float = 1.12
const TAKEOFF_TIME: float = 1.12
const DEPART_TIME: float = 0.92
const PLANET_LANDING_OFFSET: float = 19.0
const DEPART_DISTANCE: float = 205.0

# Weighted ship roles, not equal-per-role. Police and military are deliberately scarce.
# 22 + 18 + 15 + 12 + 10 + 7 + 5 + 5 + 4 + 2 = 100.
const ROLES = [
	{"id":"cargo", "weight":22, "texture":preload("res://assets/ships/06_heavy_cargo.png"), "trail":Color(1.0, 0.55, 0.14)},
	{"id":"passenger", "weight":18, "texture":preload("res://assets/ships/04_passenger_liner.png"), "trail":Color(0.18, 0.85, 1.0)},
	{"id":"school", "weight":15, "texture":preload("res://assets/ships/03_school_shuttle.png"), "trail":Color(1.0, 0.85, 0.18)},
	{"id":"miner", "weight":12, "texture":preload("res://assets/ships/10_asteroid_miner.png"), "trail":Color(0.98, 0.65, 0.25)},
	{"id":"science", "weight":10, "texture":preload("res://assets/ships/08_science_explorer.png"), "trail":Color(0.36, 0.98, 0.82)},
	{"id":"police", "weight":7, "texture":preload("res://assets/ships/01_police_patrol.png"), "trail":Color(0.32, 0.55, 1.0)},
	{"id":"racer", "weight":5, "texture":preload("res://assets/ships/05_supercar_racer.png"), "trail":Color(0.42, 1.0, 0.31)},
	{"id":"diplomatic", "weight":5, "texture":preload("res://assets/ships/07_diplomatic.png"), "trail":Color(0.90, 0.82, 1.0)},
	{"id":"military", "weight":4, "texture":preload("res://assets/ships/09_military_guard.png"), "trail":Color(1.0, 0.32, 0.27)},
	{"id":"pirate", "weight":2, "texture":preload("res://assets/ships/02_pirate_raider.png"), "trail":Color(0.97, 0.23, 0.64)}
]

var _solar: Node
var _ships: Array[Dictionary] = []
var _clouds: Array[Dictionary] = []
var _random: RandomNumberGenerator = RandomNumberGenerator.new()
var _view_size: Vector2 = Vector2(1280.0, 720.0)
var _camera_world: Vector2 = Vector2.ZERO
var _clock: float = 0.0
var _jump_counter: int = 0
var _landings_counter: int = 0
var _takeoffs_counter: int = 0


func configure(solar_system: Node) -> void:
	_solar = solar_system


func _ready() -> void:
	_random.seed = 194037  # reproducible initial fleet for test reports
	for index in range(POPULATION):
		# A few ships start inside ports, so departures are visible shortly
		# after starting the game. The remainder are already in flight.
		_ships.append(_make_ship(index < 3, index % 5 == 0))
	queue_redraw()


func active_count() -> int:
	var count: int = 0
	for npc in _ships:
		if str(npc["mode"]) != "waiting" and str(npc["mode"]) != "docked":
			count += 1
	return count


func hyperjump_count() -> int:
	return _jump_counter


func landing_count() -> int:
	return _landings_counter


func takeoff_count() -> int:
	return _takeoffs_counter


func set_camera_address(sector: Vector2i, local_position: Vector2, camera_offset: Vector2) -> void:
	_camera_world = Vector2(sector) * WorldAddress.SECTOR_SIZE + local_position + camera_offset


func resize_view(view_size: Vector2) -> void:
	_view_size = view_size


func _choose_role() -> int:
	var roll: int = _random.randi_range(1, 100)
	var subtotal: int = 0
	for i in range(ROLES.size()):
		subtotal += int(ROLES[i]["weight"])
		if roll <= subtotal:
			return i
	return ROLES.size() - 1


func _make_ship(near_earth: bool, start_docked: bool = false) -> Dictionary:
	var role_index: int = _choose_role()
	var bodies: Array[Dictionary] = _get_bodies()
	var source_name: String = "Earth"
	if near_earth:
		source_name = "Earth" if _random.randf() < 0.7 else "EarthStation"
	else:
		var chosen: Dictionary = bodies[_random.randi_range(0, bodies.size() - 1)]
		source_name = str(chosen["name"])
	var origin: Vector2 = _body_pos(bodies, source_name)
	var outward: Vector2 = Vector2.from_angle(_random.randf_range(0.0, TAU))
	var start: Vector2 = origin + outward * _random.randf_range(115.0, 285.0)
	var target_name: String = _choose_destination(source_name, bodies)
	var target_world: Vector2 = _body_pos(bodies, target_name)
	var heading: float = (target_world - start).angle() + PI * 0.5
	var choose_exit: bool = _random.randf() < 0.27
	var size_factor: float = _random.randf_range(0.14, 0.19)
	var npc: Dictionary = {
		"role": role_index,
		"world": start,
		"velocity": Vector2.ZERO,
		"angle": heading,
		"speed": _random.randf_range(145.0, 225.0),
		"size": size_factor,
		"target": target_name,
		"source": source_name,
		"outbound": choose_exit,
		"exit_world": _jump_point(start),
		"stops_left": _random.randi_range(1, 4),
		"mode": "cruise",
		"timer": 0.0,
		"jitter": _random.randf_range(0.0, TAU),
		"landing_body": "",
		"anchor_dir": outward,
		"approach_offset": Vector2.ZERO
	}
	if start_docked:
		# Spawn invisibly at a moving port and grow into view naturally.
		npc["mode"] = "docked"
		npc["landing_body"] = source_name
		npc["timer"] = _random.randf_range(0.1, 4.0)
		npc["world"] = _anchor_world(npc, bodies)
	return npc


func _get_bodies() -> Array[Dictionary]:
	var results: Array[Dictionary] = []
	if _solar == null:
		return [{"name":"Earth", "world":Vector2(565.0, 0.0)}]
	var all_bodies: Array[Dictionary] = _solar.get_navigation_bodies()
	for body in all_bodies:
		if str(body["name"]) in LANDING_PORTS:
			results.append(body)
	return results


func _body_pos(bodies: Array[Dictionary], name: String) -> Vector2:
	for body in bodies:
		if str(body["name"]) == name:
			return body["world"]
	return Vector2(565.0, 0.0)


func _choose_destination(source: String, bodies: Array[Dictionary]) -> String:
	if bodies.is_empty():
		return "Earth"
	for attempt in range(12):
		var candidate: String = str(bodies[_random.randi_range(0, bodies.size() - 1)]["name"])
		if candidate != source:
			return candidate
	return "EarthStation" if source != "EarthStation" else "Earth"


func _jump_point(start: Vector2) -> Vector2:
	# A persistent edge location relative to the Sun, not a teleport across screen.
	var outward: float = start.angle() + _random.randf_range(-0.55, 0.55)
	return HyperjumpMotion.exit_world(Vector2.from_angle(outward))


func _landing_offset(body_name: String) -> float:
	return 0.0 if body_name == "EarthStation" else PLANET_LANDING_OFFSET


func _anchor_world(npc: Dictionary, bodies: Array[Dictionary]) -> Vector2:
	# The BODY is sampled again every frame. This is what prevents landing
	# ships from drifting away while the planets orbit around the Sun.
	var body_name: String = str(npc["landing_body"])
	var body_world: Vector2 = _body_pos(bodies, body_name)
	return body_world + Vector2(npc["anchor_dir"]) * _landing_offset(body_name)


func _begin_approach(npc: Dictionary, bodies: Array[Dictionary]) -> Dictionary:
	var landing_body: String = str(npc["target"])
	var planet_world: Vector2 = _body_pos(bodies, landing_body)
	var relative: Vector2 = Vector2(npc["world"]) - planet_world
	var outward: Vector2 = relative.normalized() if relative.length_squared() > 0.01 else Vector2.UP
	npc["landing_body"] = landing_body
	npc["anchor_dir"] = outward
	npc["approach_offset"] = relative
	npc["mode"] = "approach"
	npc["timer"] = 0.0
	npc["velocity"] = Vector2.ZERO
	return npc


func _start_takeoff(npc: Dictionary, bodies: Array[Dictionary]) -> Dictionary:
	var current_port: String = str(npc["landing_body"])
	npc["source"] = current_port
	npc["stops_left"] = int(npc["stops_left"]) - 1
	npc["outbound"] = int(npc["stops_left"]) <= 0 or _random.randf() < 0.16
	var here: Vector2 = _body_pos(bodies, current_port)
	if bool(npc["outbound"]):
		npc["exit_world"] = _jump_point(here)
	else:
		npc["target"] = _choose_destination(current_port, bodies)
	# Face the actual outward departure path first. Steering toward the
	# next waypoint starts only after the ship has cleared the surface.
	var launch_direction: Vector2 = Vector2(npc["anchor_dir"])
	if launch_direction.length_squared() > 0.01:
		npc["angle"] = launch_direction.angle() + PI * 0.5
	npc["world"] = _anchor_world(npc, bodies)
	npc["mode"] = "takeoff"
	npc["timer"] = 0.0
	takeoff_started.emit(str(ROLES[int(npc["role"])]["id"]), current_port)
	_takeoffs_counter += 1
	return npc


func _process_port_animation(npc: Dictionary, bodies: Array[Dictionary], delta: float) -> Dictionary:
	var mode: String = str(npc["mode"])
	if mode == "docked":
		# Invisible ship stays attached to the orbiting body until takeoff.
		npc["world"] = _anchor_world(npc, bodies)
		npc["timer"] = float(npc["timer"]) - delta
		if float(npc["timer"]) <= 0.0:
			return _start_takeoff(npc, bodies)
		return npc
	var elapsed: float = float(npc["timer"]) + delta
	var body_name: String = str(npc["landing_body"])
	var body_world: Vector2 = _body_pos(bodies, body_name)
	var anchor_offset: Vector2 = Vector2(npc["anchor_dir"]) * _landing_offset(body_name)
	var anchor_world: Vector2 = body_world + anchor_offset
	npc["timer"] = elapsed
	npc["velocity"] = Vector2.ZERO
	match mode:
		"approach":
			var progress: float = clampf(elapsed / APPROACH_TIME, 0.0, 1.0)
			var next_world: Vector2 = LandingMotion.anchored_approach(body_world, Vector2(npc["approach_offset"]), anchor_offset, progress)
			var approach_direction: Vector2 = next_world - Vector2(npc["world"])
			if approach_direction.length_squared() > 0.02:
				npc["angle"] = lerp_angle(float(npc["angle"]), approach_direction.angle() + PI * 0.5, minf(1.0, delta * 5.0))
			npc["world"] = next_world
			if progress >= 1.0:
				npc["mode"] = "hover"
				npc["timer"] = 0.0
		"hover":
			npc["world"] = anchor_world
			if elapsed >= HOVER_TIME:
				npc["mode"] = "landing"
				npc["timer"] = 0.0
		"landing":
			npc["world"] = anchor_world
			if elapsed >= LANDING_TIME:
				npc["mode"] = "docked"
				npc["timer"] = _random.randf_range(2.0, 5.0)
				_landings_counter += 1
				landing_completed.emit(str(ROLES[int(npc["role"])]["id"]), body_name)
		"takeoff":
			npc["world"] = anchor_world
			if elapsed >= TAKEOFF_TIME:
				npc["mode"] = "depart"
				npc["timer"] = 0.0
		"depart":
			# Local ship nose is -Y; the direction of motion MUST match the nose.
			var depart_dir: Vector2 = Vector2(npc["anchor_dir"])
			if depart_dir.length_squared() > 0.01:
				npc["angle"] = depart_dir.angle() + PI * 0.5
			var outward_progress: float = clampf(elapsed / DEPART_TIME, 0.0, 1.0)
			var outward_distance: float = lerpf(_landing_offset(body_name), DEPART_DISTANCE, LandingMotion.smooth_step(outward_progress))
			npc["world"] = body_world + Vector2(npc["anchor_dir"]) * outward_distance
			if outward_progress >= 1.0:
				npc["mode"] = "cruise"
				npc["timer"] = 0.0
				npc["velocity"] = Vector2(npc["anchor_dir"]) * float(npc["speed"]) * 0.55
				npc["angle"] = Vector2(npc["velocity"]).angle() + PI * 0.5
	return npc


func try_asteroid_impact(world_position: Vector2, asteroid_radius: float) -> bool:
	# World-space proximity against active NPC ships; a hit interrupts their route.
	for i in range(_ships.size()):
		var npc: Dictionary = _ships[i]
		var mode: String = str(npc["mode"])
		if mode in ["waiting", "docked", "landing", "takeoff", "dash"]:
			continue
		var ship_world: Vector2 = Vector2(npc["world"])
		var sprite_radius: float = 120.0 * float(npc["size"])
		if ship_world.distance_squared_to(world_position) > pow(asteroid_radius + sprite_radius, 2.0):
			continue
		npc["mode"] = "waiting"
		npc["timer"] = RESPAWN_DELAY + _random.randf_range(1.0, 3.0)
		_ships[i] = npc
		_spawn_cloud(world_position, ROLES[int(npc["role"])]["trail"])
		return true
	return false


func _physics_process(delta: float) -> void:
	_clock += delta
	var bodies: Array[Dictionary] = _get_bodies()
	for i in range(_ships.size()):
		var npc: Dictionary = _ships[i]
		var mode: String = str(npc["mode"])
		var timer: float = float(npc["timer"])
		if mode == "waiting":
			npc["timer"] = timer - delta
			if float(npc["timer"]) <= 0.0:
				# Re-entry is a visible takeoff from a world, not a pop-in.
				npc = _make_ship(false, true)
			_ships[i] = npc
			continue
		if mode == "charge":
			# Lock the jump vector to the visible nose before the dash begins.
			var exit_direction: Vector2 = Vector2(npc["exit_world"]) - Vector2(npc["world"])
			if exit_direction.length_squared() > 0.01:
				npc["angle"] = lerp_angle(float(npc["angle"]), exit_direction.angle() + PI * 0.5, minf(1.0, delta * 12.0))
			npc["timer"] = timer + delta
			npc["velocity"] = Vector2(npc["velocity"]).move_toward(Vector2.ZERO, 340.0 * delta)
			npc["world"] = Vector2(npc["world"]) + Vector2(npc["velocity"]) * delta
			if float(npc["timer"]) >= CHARGE_TIME:
				npc["mode"] = "dash"
				npc["timer"] = 0.0
				_jump_counter += 1
				hyperjump_started.emit(str(ROLES[int(npc["role"])]["id"]), npc["world"])
			_ships[i] = npc
			continue
		if mode == "dash":
			npc["timer"] = timer + delta
			var jump_dir: Vector2 = Vector2.from_angle(float(npc["angle"]) - PI * 0.5)
			var t: float = clampf(float(npc["timer"]) / DASH_TIME, 0.0, 1.0)
			npc["world"] = Vector2(npc["world"]) + jump_dir * HyperjumpMotion.dash_speed(t) * delta
			if t >= 1.0:
				_spawn_cloud(npc["world"], ROLES[int(npc["role"])]["trail"])
				npc["mode"] = "waiting"
				npc["timer"] = RESPAWN_DELAY + _random.randf_range(0.0, 3.0)
			_ships[i] = npc
			continue

		if mode in ["approach", "hover", "landing", "docked", "takeoff", "depart"]:
			npc = _process_port_animation(npc, bodies, delta)
			_ships[i] = npc
			continue

		var world: Vector2 = npc["world"]
		var destination: Vector2 = Vector2(npc["exit_world"]) if bool(npc["outbound"]) else _body_pos(bodies, str(npc["target"]))
		var toward: Vector2 = destination - world
		var reach_radius: float = 82.0 if bool(npc["outbound"]) else APPROACH_START_RADIUS
		if toward.length() <= reach_radius:
			if bool(npc["outbound"]):
				npc["mode"] = "charge"
				npc["timer"] = 0.0
				npc["velocity"] = Vector2.ZERO
				_spawn_cloud(npc["world"], ROLES[int(npc["role"])]["trail"])
			else:
				npc = _begin_approach(npc, bodies)
			_ships[i] = npc
			continue
		var intent: Vector2 = toward.normalized()
		var desired_velocity: Vector2 = intent * float(npc["speed"])
		var movement: Vector2 = Vector2(npc["velocity"]).move_toward(desired_velocity, SPEED_ACCEL * delta)
		npc["velocity"] = movement
		npc["world"] = world + movement * delta
		if movement.length_squared() > 1.0:
			npc["angle"] = lerp_angle(float(npc["angle"]), movement.angle() + PI * 0.5, minf(1.0, delta * 4.0))
		_ships[i] = npc

	for i in range(_clouds.size() - 1, -1, -1):
		var cloud: Dictionary = _clouds[i]
		cloud["life"] = float(cloud["life"]) - delta
		if float(cloud["life"]) <= 0.0:
			_clouds.remove_at(i)
		else:
			_clouds[i] = cloud
	queue_redraw()


func _spawn_cloud(world_position: Vector2, col: Color) -> void:
	if _clouds.size() >= MAX_CLOUDS:
		_clouds.pop_front()
	_clouds.append({"world":world_position, "life":1.0, "color":col, "phase":_random.randf_range(0.0, TAU)})


func _visible_in_view(screen: Vector2, margin: float = 140.0) -> bool:
	return screen.x > -margin and screen.y > -margin and screen.x < _view_size.x + margin and screen.y < _view_size.y + margin


func _draw() -> void:
	for cloud in _clouds:
		var screen: Vector2 = Vector2(cloud["world"]) - _camera_world + _view_size * 0.5
		if not _visible_in_view(screen, 95.0):
			continue
		_draw_jump_cloud(screen, float(cloud["life"]), cloud["color"], float(cloud["phase"]))
	for npc in _ships:
		var mode: String = str(npc["mode"])
		if mode == "waiting" or mode == "docked":
			continue
		var screen: Vector2 = Vector2(npc["world"]) - _camera_world + _view_size * 0.5
		if not _visible_in_view(screen):
			continue
		var role: Dictionary = ROLES[int(npc["role"])]
		var angle: float = float(npc["angle"])
		var size_factor: float = float(npc["size"])
		var animation_progress: float = 0.0
		if mode == "approach":
			animation_progress = clampf(float(npc["timer"]) / APPROACH_TIME, 0.0, 1.0)
			size_factor *= 1.0 - 0.18 * LandingMotion.smooth_step(animation_progress)
		elif mode == "hover":
			size_factor *= 0.82
		elif mode == "landing":
			animation_progress = clampf(float(npc["timer"]) / LANDING_TIME, 0.0, 1.0)
			size_factor *= 0.82 * (1.0 - LandingMotion.smooth_step(animation_progress))
		elif mode == "takeoff":
			animation_progress = clampf(float(npc["timer"]) / TAKEOFF_TIME, 0.0, 1.0)
			size_factor *= 0.82 * LandingMotion.smooth_step(animation_progress)
		elif mode == "depart":
			animation_progress = clampf(float(npc["timer"]) / DEPART_TIME, 0.0, 1.0)
			size_factor *= 0.82 + 0.18 * LandingMotion.smooth_step(animation_progress)
		var speed_factor: float = clampf(Vector2(npc["velocity"]).length() / maxf(float(npc["speed"]), 0.1), 0.0, 1.0)
		if mode == "dash":
			var t: float = clampf(float(npc["timer"]) / DASH_TIME, 0.0, 1.0)
			speed_factor = 1.0
			# Fast directional trail and lens-like flash, then fades to invisibility.
			NpcJumpVisual.draw_dash(self, screen, angle, t, role["trail"])
			size_factor *= NpcJumpVisual.dash_ship_scale(t)
		elif mode in ["approach", "hover", "landing", "takeoff", "depart"]:
			# Less exhaust near the surface; lift-off has a faint increasing glow.
			speed_factor = 0.0 if mode in ["hover", "landing", "approach"] else animation_progress * 0.72
			if mode in ["hover", "landing", "takeoff"]:
				draw_circle(screen, 14.0, Color(role["trail"], 0.12 * clampf(size_factor / maxf(float(npc["size"]), 0.01), 0.0, 1.0)))
		elif mode == "charge":
			var charge_alpha: float = clampf(float(npc["timer"]) / CHARGE_TIME, 0.0, 1.0)
			NpcJumpVisual.draw_charge(self, screen, charge_alpha, role["trail"])
			speed_factor = 0.1
		draw_set_transform(screen, angle, Vector2.ONE * size_factor)
		if mode == "cruise" and speed_factor > 0.32 and str(role["id"]) in ["cargo", "passenger", "school", "miner"]:
			_draw_motion_wake(role["trail"], speed_factor, float(npc["jitter"]))
		_draw_thruster(role["trail"], speed_factor, float(npc["jitter"]))
		draw_texture_rect(role["texture"], Rect2(Vector2(-256.0, -256.0), Vector2(512.0, 512.0)), false)
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


func _draw_motion_wake(color: Color, strength: float, phase: float) -> void:
	# Subtle slipstream lines follow the ship's local -Y nose.
	var flicker: float = 0.86 + 0.14 * sin(_clock * 9.0 + phase)
	for i in range(3):
		var x: float = (float(i) - 1.0) * 122.0
		var back: float = 180.0 + float(i % 2) * 35.0
		draw_line(Vector2(x, back), Vector2(x * 1.18, back + 68.0 * strength * flicker), Color(color, 0.13 * strength), 2.0, true)


func _draw_thruster(color: Color, strength: float, phase: float) -> void:
	if strength <= 0.04:
		return
	var length_px: float = (65.0 + 73.0 * strength) * (0.93 + 0.07 * sin(_clock * 21.0 + phase))
	for nozzle_x in [-63.0, 63.0]:
		var base: Vector2 = Vector2(nozzle_x, 173.0)
		draw_colored_polygon(PackedVector2Array([
			base + Vector2(-25.0, -3.0),
			base + Vector2(0.0, length_px),
			base + Vector2(25.0, -3.0)
		]), Color(color, 0.37 * strength))
		draw_colored_polygon(PackedVector2Array([
			base + Vector2(-10.0, -1.0),
			base + Vector2(0.0, length_px * 0.68),
			base + Vector2(10.0, -1.0)
		]), Color(0.87, 0.97, 1.0, 0.58 * strength))
		draw_circle(base, 17.0, Color(color, 0.21 * strength))


func _draw_jump_cloud(screen: Vector2, lifetime: float, color: Color, phase: float) -> void:
	NpcJumpVisual.draw_jump_cloud(self, screen, lifetime, color, phase)
