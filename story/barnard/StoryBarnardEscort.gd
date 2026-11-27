extends Node2D
## Two true, separately animated native NPC ships for Chapter 4's pirate
## interception and escort. They share the real flight viewport with Mika;
## no duplicate space scene, fake HUD, or cut-up comic artwork is created.

signal interception_completed

const INTERCEPTOR_ART: Texture2D = preload("res://assets/story/ngc6822_interceptor_02.png")
const PIRATE_ART: Texture2D = preload("res://assets/ships/02_pirate_raider.png")

var _interceptor: Sprite2D
var _raider: Sprite2D
var _active_tween: Tween
var _state: String = "idle"
var _screen_size: Vector2 = Vector2(1280.0, 720.0)
const NOSE_OFFSETS: Array[float] = [0.0, PI * 0.5] # bronze: +X; raider: -Y
const APPROACH_SLOTS: Array[Vector2] = [Vector2(-85.0, -105.0), Vector2(85.0, -105.0)]
const DOCK_SLOTS: Array[Vector2] = [Vector2(-62.0, -18.0), Vector2(62.0, -18.0)]
const TURN_RATE: float = 2.9
const ACCEL: float = 480.0
const BRAKE: float = 620.0
const CRUISE: float = 520.0
const INTERCEPT_SECONDS: Array[float] = [3.9, 4.2]
const WINGMAN_CRUISE: float = 960.0
const SCOUT_CRUISE: float = 820.0
const FORMATION_ACCEL: float = 1700.0
const FORMATION_BRAKE: float = 1450.0
var _motions: Array[Dictionary] = []
var _hold_time: float = 0.0
var _previous_ship_world: Vector2 = Vector2.ZERO
var _player_speed: float = 0.0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_INHERIT
	z_index = 12
	_interceptor = _make_ship("BarnardBronzeInterceptor", INTERCEPTOR_ART)
	_raider = _make_ship("DarkPirateRaider", PIRATE_ART)
	_motions = [
		{"sprite": _interceptor, "speed": 0.0, "world": Vector2.ZERO, "phase": "idle", "timer": 0.0},
		{"sprite": _raider, "speed": 0.0, "world": Vector2.ZERO, "phase": "idle", "timer": 0.0}
	]
	visible = false


func _make_ship(label: String, texture: Texture2D) -> Sprite2D:
	var npc: Sprite2D = Sprite2D.new()
	npc.name = label
	npc.texture = texture
	npc.centered = true
	npc.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	npc.modulate = Color.WHITE
	add_child(npc)
	return npc


func _set_npc_scale() -> void:
	var factor: float = clampf(minf(_screen_size.x / 1280.0, _screen_size.y / 720.0), 0.55, 1.0)
	_interceptor.scale = Vector2.ONE * (0.195 * factor)
	_raider.scale = Vector2.ONE * (0.187 * factor)


func intercept(view_size: Vector2) -> void:
	stop()
	_screen_size = view_size
	_set_npc_scale()
	_state = "intercept"
	visible = true
	_hold_time = 0.0
	for i in range(_motions.size()):
		var motion: Dictionary = _motions[i]
		var npc: Sprite2D = motion["sprite"]
		var side: float = -1.0 if i == 0 else 1.0
		var center: Vector2 = _screen_size * 0.5
		var start: Vector2 = center + Vector2(side * _screen_size.x * 0.62, -_screen_size.y * 0.37)
		var control_one: Vector2 = center + Vector2(side * _screen_size.x * 0.44, -_screen_size.y * 0.41)
		var control_two: Vector2 = center + Vector2(side * _screen_size.x * 0.18, -_screen_size.y * 0.37)
		var final: Vector2 = center + Vector2(side * _screen_size.x * 0.11, -_screen_size.y * 0.19)
		motion["curve"] = [start, control_one, control_two, final]
		motion["timer"] = 0.0
		npc.position = start
		npc.rotation = (control_one - start).angle() + NOSE_OFFSETS[i]
		motion["speed"] = 0.0
		motion["phase"] = "approach"
	queue_redraw()


func _curve_point(points: Array, t: float) -> Vector2:
	var inv: float = 1.0 - t
	return Vector2(points[0]) * (inv * inv * inv) + Vector2(points[1]) * (3.0 * inv * inv * t) + Vector2(points[2]) * (3.0 * inv * t * t) + Vector2(points[3]) * (t * t * t)


func _curve_tangent(points: Array, t: float) -> Vector2:
	var inv: float = 1.0 - t
	return (Vector2(points[1]) - Vector2(points[0])) * (3.0 * inv * inv) + (Vector2(points[2]) - Vector2(points[1])) * (6.0 * inv * t) + (Vector2(points[3]) - Vector2(points[2])) * (3.0 * t * t)


func _steer(motion: Dictionary, target: Vector2, delta: float, nose_offset: float, max_speed: float, arrival_radius: float) -> bool:
	var npc: Sprite2D = motion["sprite"]
	var delta_position: Vector2 = target - npc.position
	var distance: float = delta_position.length()
	var speed: float = float(motion["speed"])
	if distance < arrival_radius and speed < 26.0:
		motion["speed"] = 0.0
		npc.position = target
		return true
	var desired: float = delta_position.angle() + nose_offset
	var turn: float = wrapf(desired - npc.rotation, -PI, PI)
	npc.rotation += clampf(turn, -TURN_RATE * delta, TURN_RATE * delta)
	var heading_error: float = absf(wrapf(desired - npc.rotation, -PI, PI))
	var alignment: float = pow(maxf(0.0, cos(heading_error)), 2.0)
	var desired_speed: float = minf(max_speed, sqrt(2.0 * BRAKE * maxf(0.0, distance - arrival_radius))) * alignment
	speed = move_toward(speed, desired_speed, (ACCEL if desired_speed >= speed else BRAKE) * delta)
	motion["speed"] = speed
	# Velocity is constrained to the direction the engine NOSE points.
	npc.position += Vector2.from_angle(npc.rotation - nose_offset) * speed * delta
	return false


func _physics_process(delta: float) -> void:
	if _state != "intercept":
		return
	var reached: int = 0
	for i in range(_motions.size()):
		var motion: Dictionary = _motions[i]
		if str(motion["phase"]) == "holding":
			reached += 1
			continue
		var npc: Sprite2D = motion["sprite"]
		motion["timer"] = float(motion["timer"]) + delta
		var clock: float = clampf(float(motion["timer"]) / INTERCEPT_SECONDS[i], 0.0, 1.0)
		# Quintic ease removes the jerk from the old stop/change-waypoint
		# interception; the Bézier tangent always matches the ship's nose.
		var progress: float = clock * clock * clock * (clock * (clock * 6.0 - 15.0) + 10.0)
		var old_position: Vector2 = npc.position
		var curve: Array = motion["curve"]
		npc.position = _curve_point(curve, progress)
		var tangent: Vector2 = _curve_tangent(curve, progress)
		if tangent.length_squared() > 0.001:
			npc.rotation = tangent.angle() + NOSE_OFFSETS[i]
		motion["speed"] = old_position.distance_to(npc.position) / maxf(delta, 0.00001)
		if clock >= 1.0:
			motion["speed"] = 0.0
			motion["phase"] = "holding"
			reached += 1
	if reached == 2:
		_hold_time += delta
		if _hold_time > 0.75:
			_state = "holding"
			interception_completed.emit()
	queue_redraw()


func escort(view_size: Vector2, _travel_direction: Vector2, ship_world: Vector2, _station_world: Vector2) -> void:
	_screen_size = view_size
	_set_npc_scale()
	_state = "escort"
	visible = true
	_previous_ship_world = ship_world
	_player_speed = 0.0
	for motion in _motions:
		var npc: Sprite2D = motion["sprite"]
		motion["world"] = ship_world + npc.position - view_size * 0.5
		motion["phase"] = "cruise"
		motion["speed"] = 0.0


func _follow_moving_formation(motion: Dictionary, npc_index: int, target_world: Vector2, ship_world: Vector2, forward: Vector2, peel: float, delta: float) -> void:
	var npc: Sprite2D = motion["sprite"]
	var npc_world: Vector2 = Vector2(motion["world"])
	var target_error: Vector2 = target_world - npc_world
	# Looking ahead along Mika's velocity lets the escort hold a moving slot
	# instead of repeatedly stopping to chase a stationary screen coordinate.
	var lead: float = clampf(_player_speed * 0.36, 85.0, 250.0) * (1.0 - peel)
	var aim: Vector2 = target_error + forward * lead
	if aim.length_squared() < 0.01:
		aim = forward
	var desired_rotation: float = aim.angle() + NOSE_OFFSETS[npc_index]
	var turn: float = wrapf(desired_rotation - npc.rotation, -PI, PI)
	npc.rotation += clampf(turn, -TURN_RATE * delta, TURN_RATE * delta)
	var heading_error: float = absf(wrapf(desired_rotation - npc.rotation, -PI, PI))
	var alignment: float = pow(maxf(0.0, cos(heading_error)), 2.0)
	var max_speed: float = WINGMAN_CRUISE if npc_index == 0 else SCOUT_CRUISE
	var along: float = target_error.dot(forward)
	var moving_speed: float = clampf(_player_speed + clampf(along * 1.7, -260.0, 420.0), 0.0, max_speed)
	var docking_speed: float = minf(max_speed, sqrt(2.0 * FORMATION_BRAKE * maxf(target_error.length() - 18.0, 0.0)))
	var desired_speed: float = lerpf(moving_speed, docking_speed, peel) * alignment
	var speed: float = float(motion["speed"])
	var ramp: float = FORMATION_ACCEL if desired_speed >= speed else FORMATION_BRAKE
	speed = move_toward(speed, desired_speed, ramp * delta)
	motion["speed"] = speed
	# Actual displacement is strictly along the nose, never sideways.
	npc.position += Vector2.from_angle(npc.rotation - NOSE_OFFSETS[npc_index]) * speed * delta
	motion["world"] = ship_world + npc.position - _screen_size * 0.5


func update_escort(delta: float, view_size: Vector2, ship_world: Vector2, station_world: Vector2, forward: Vector2) -> void:
	if _state != "escort":
		return
	_screen_size = view_size
	var observed_speed: float = (ship_world - _previous_ship_world).dot(forward) / maxf(delta, 0.00001)
	_player_speed = move_toward(_player_speed, clampf(observed_speed, 0.0, 760.0), 1150.0 * delta)
	_previous_ship_world = ship_world
	var station_distance: float = ship_world.distance_to(station_world)
	var sideways: Vector2 = Vector2(-forward.y, forward.x)
	for i in range(_motions.size()):
		var motion: Dictionary = _motions[i]
		var npc: Sprite2D = motion["sprite"]
		npc.position = view_size * 0.5 + Vector2(motion["world"]) - ship_world
		# Bronze is Mika's wingman all the way to the port approach; the dark
		# raider peels ahead as the visible scout. Never send both away at once.
		var formation_world: Vector2 = ship_world - forward * 70.0 + sideways * 115.0 if i == 0 else ship_world + forward * 155.0 - sideways * 165.0
		var peel_from: float = 410.0 if i == 0 else 950.0
		var peel_to: float = 250.0 if i == 0 else 650.0
		var amount: float = clampf((peel_from - station_distance) / (peel_from - peel_to), 0.0, 1.0)
		var peel: float = amount * amount * (3.0 - 2.0 * amount)
		var target_world: Vector2 = formation_world.lerp(station_world + APPROACH_SLOTS[i], peel)
		_follow_moving_formation(motion, i, target_world, ship_world, forward, peel, delta)
	queue_redraw()


func landing() -> void:
	if _state != "escort":
		return
	_state = "landing"
	for motion in _motions:
		motion["phase"] = "approach"
		motion["timer"] = 0.0


func update_landing(delta: float, view_size: Vector2, ship_world: Vector2, station_world: Vector2) -> bool:
	if _state != "landing" and _state != "docked":
		return false
	var completed: int = 0
	for i in range(_motions.size()):
		var motion: Dictionary = _motions[i]
		var npc: Sprite2D = motion["sprite"]
		npc.position = view_size * 0.5 + Vector2(motion["world"]) - ship_world
		var phase: String = str(motion["phase"])
		if phase == "approach":
			var dock: Vector2 = view_size * 0.5 + station_world + DOCK_SLOTS[i] - ship_world
			if _steer(motion, dock, delta, NOSE_OFFSETS[i], 180.0, 16.0):
				motion["phase"] = "hover"
				motion["timer"] = 0.0
		elif phase == "hover":
			motion["timer"] = float(motion["timer"]) + delta
			if float(motion["timer"]) >= 0.52:
				motion["phase"] = "descent"
				motion["timer"] = 0.0
		elif phase == "descent":
			motion["timer"] = float(motion["timer"]) + delta
			var t: float = clampf(float(motion["timer"]) / 1.10, 0.0, 1.0)
			var eased: float = t * t * (3.0 - 2.0 * t)
			var scale_factor: float = clampf(minf(view_size.x / 1280.0, view_size.y / 720.0), 0.55, 1.0)
			npc.scale = Vector2.ONE * (0.195 if i == 0 else 0.187) * scale_factor * (1.0 - 0.8 * eased)
			npc.modulate.a = 1.0 - eased
			if t >= 1.0:
				motion["phase"] = "docked"
				completed += 1
		elif phase == "docked":
			completed += 1
		motion["world"] = ship_world + npc.position - view_size * 0.5
	if completed == 2:
		_state = "docked"
	queue_redraw()
	return completed == 2


func _draw() -> void:
	if not visible or _state in ["holding", "idle", "docked"]:
		return
	# Native-style thruster flames stay behind the actual direction of travel.
	for i in range(_motions.size()):
		var motion: Dictionary = _motions[i]
		if str(motion["phase"]) in ["hover", "descent", "docked"] or float(motion["speed"]) < 12.0:
			continue
		var npc: Sprite2D = motion["sprite"]
		var forward: Vector2 = Vector2.from_angle(npc.rotation - NOSE_OFFSETS[i])
		var base: Vector2 = npc.position - forward * 31.0
		var color: Color = Color(0.23, 0.81, 1.0, 0.8) if i == 0 else Color(1.0, 0.54, 0.19, 0.8)
		draw_line(base, base - forward * (12.0 + float(motion["speed"]) * 0.03), color, 5.0, true)
		draw_circle(base, 4.5, color)


func stop() -> void:
	if _active_tween and _active_tween.is_running():
		_active_tween.kill()
	_state = "idle"
	visible = false
	for motion in _motions:
		motion["speed"] = 0.0
		motion["phase"] = "idle"
	if is_instance_valid(_interceptor):
		_interceptor.scale = Vector2.ONE
		_interceptor.modulate = Color.WHITE
	if is_instance_valid(_raider):
		_raider.scale = Vector2.ONE
		_raider.modulate = Color.WHITE
	queue_redraw()


func get_ships() -> Array[Sprite2D]:
	return [_interceptor, _raider]
