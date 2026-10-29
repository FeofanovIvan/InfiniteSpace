extends Node2D
## Atlas-based star-system gameplay prototype. LMC uses real supplied MIKO
## shader scenes; other worlds use distinct generated preview textures.
## A region is an illustrated playground, not an astronomical assertion that
## all planets in a real galaxy orbit one star.
const WorldAddress = preload("res://scripts/WorldPosition.gd")
const MOON_TEXTURE: Texture2D = preload("res://assets/solar/moon_surface.png")
const STATION_TEXTURE: Texture2D = preload("res://assets/destinations/earth_station.png")
const LandmarkClass = preload("res://scripts/AtlasLandmark.gd")
const RotatingSunScene = preload("res://scripts/RotatingSun.gd")
const LMC_SCENES: Array[PackedScene] = [
	preload("res://lmc_planets/planets/lmc_p01.tscn"),
	preload("res://lmc_planets/planets/lmc_p02.tscn"),
	preload("res://lmc_planets/planets/lmc_p03.tscn"),
	preload("res://lmc_planets/planets/lmc_p04.tscn"),
	preload("res://lmc_planets/planets/lmc_p05.tscn"),
	preload("res://lmc_planets/planets/lmc_p06.tscn"),
	preload("res://lmc_planets/planets/lmc_p07.tscn"),
	preload("res://lmc_planets/planets/lmc_p08.tscn")
]
const SMC_SCENES: Array[PackedScene] = [
	preload("res://smc_planets/planets/smc_p01.tscn"),
	preload("res://smc_planets/planets/smc_p02.tscn"),
	preload("res://smc_planets/planets/smc_p03.tscn"),
	preload("res://smc_planets/planets/smc_p04.tscn"),
	preload("res://smc_planets/planets/smc_p05.tscn"),
	preload("res://smc_planets/planets/smc_p06.tscn"),
	preload("res://smc_planets/planets/smc_p07.tscn"),
	preload("res://smc_planets/planets/smc_p08.tscn")
]
const NGC6822_SCENES: Array[PackedScene] = [
	preload("res://ngc6822_planets/planets/ngc6822_p01.tscn"),
	preload("res://ngc6822_planets/planets/ngc6822_p02.tscn"),
	preload("res://ngc6822_planets/planets/ngc6822_p03.tscn"),
	preload("res://ngc6822_planets/planets/ngc6822_p04.tscn"),
	preload("res://ngc6822_planets/planets/ngc6822_p05.tscn"),
	preload("res://ngc6822_planets/planets/ngc6822_p06.tscn"),
	preload("res://ngc6822_planets/planets/ngc6822_p07.tscn"),
	preload("res://ngc6822_planets/planets/ngc6822_p08.tscn")
]
var _region: Dictionary = {}
var _planets: Array[Dictionary] = []
var _moons: Array[Dictionary] = []
var _landmarks: Array[Dictionary] = []
var _station_sprite: Sprite2D
var _station_symbol: Node2D
var _view: Vector2 = Vector2(1024, 576)
var _camera_world: Vector2 = Vector2.ZERO
var _time: float = 0.0
var _sun_color: Color = Color.WHITE
var _star_orb: Node2D

func _ready() -> void:
	set_process(true)

func configure_region(region: Dictionary, simulation_time: float = 0.0) -> void:
	_region = region
	_time = simulation_time
	_planets.clear()
	_moons.clear()
	_landmarks.clear()
	for child in get_children():
		remove_child(child)
		child.queue_free()
	var color_text: String = str(region.get("sun_color", "#ffbc82"))
	_sun_color = Color.html(color_text)
	_star_orb = null
	var star_index: int = ["lmc", "smc", "ngc6822", "m31", "m33"].find(str(region.get("id", "")))
	if star_index >= 0:
		var sun: RotatingSun2D = RotatingSunScene.new()
		sun.name = "RepresentativeStar_" + str(region.get("id", ""))
		var sun_size_map: Dictionary = {"lmc": 172.0, "smc": 152.0, "ngc6822": 196.0, "m31": 164.0, "m33": 182.0}
		var corona_scale_map: Dictionary = {"lmc": 1.60, "smc": 1.72, "ngc6822": 1.68, "m31": 1.58, "m33": 1.65}
		var region_id_for_sun: String = str(region.get("id", ""))
		var body_size: float = float(sun_size_map.get(region_id_for_sun, 170.0))
		var corona_size: float = body_size * float(corona_scale_map.get(region_id_for_sun, 1.62))
		sun.set_surface_diameter(body_size)
		sun.set_corona_diameter(corona_size)
		sun.set_rotation_period(22.0 + float(star_index) * 2.0)
		sun.set_activity(0.22 + float(star_index) * 0.06)
		sun.set_tint(_sun_color)
		_star_orb = sun
		add_child(_star_orb)
	if str(region.get("id", "")) != "crossroads":
		for i in range(region.get("planets", []).size()):
			var source: Dictionary = region["planets"][i]
			var root: Node2D = Node2D.new()
			root.name = str(source["id"]) + "_Globe"
			add_child(root)
			var diameter: float = float(source.get("size", 140.0))
			var region_id: String = str(region.get("id", ""))
			if region_id == "lmc" or region_id == "smc" or region_id == "ngc6822":
				var library: Array[PackedScene] = LMC_SCENES
				if region_id == "smc":
					library = SMC_SCENES
				elif region_id == "ngc6822":
					library = NGC6822_SCENES
				var globe: Node2D = library[i].instantiate() as Node2D
				root.add_child(globe)
				globe.call("set_diameter", diameter)
			else:
				var sprite: Sprite2D = Sprite2D.new()
				sprite.texture = load(str(source["visual_asset"])) as Texture2D
				sprite.scale = Vector2.ONE * (diameter / 238.0)
				root.add_child(sprite)
			_planets.append({"data": source, "node": root, "phase": float(source["phase"]), "world": Vector2.ZERO})
			var landmark: Node2D = LandmarkClass.new()
			landmark.name = "Landmark_" + str(source["id"])
			add_child(landmark)
			landmark.call("configure", i, Color.html(str(source.get("palette", ["#83d5ff"])[0])))
			_landmarks.append({"node": landmark, "planet_index": i, "angle": float(i) * 1.83})
			var moons: Array = source.get("moons", [])
			for m in range(moons.size()):
				var moon_node: Sprite2D = Sprite2D.new()
				moon_node.texture = MOON_TEXTURE
				moon_node.name = "Moon_" + str(moons[m])
				var diameter_m: float = 19.0 + float((i + m) % 3) * 7.0
				moon_node.scale = Vector2.ONE * (diameter_m / float(MOON_TEXTURE.get_width()))
				moon_node.modulate = Color(0.83, 0.90, 1.0) if (m % 2) == 0 else Color(0.84, 0.79, 0.74)
				add_child(moon_node)
				_moons.append({"node": moon_node, "planet_index": i, "name": str(moons[m]), "phase": float(m) * 2.4 + float(i), "radius": diameter * 0.69 + 34.0 + m * 31.0, "speed": 0.025 + 0.012 * m})
		_station_sprite = Sprite2D.new()
		_station_sprite.name = "StoryStation_" + str(region.get("id", ""))
		_station_sprite.texture = STATION_TEXTURE
		_station_sprite.scale = Vector2.ONE * 0.58
		add_child(_station_sprite)
		_station_symbol = LandmarkClass.new()
		_station_symbol.name = "UniqueStationSilhouette_" + str(region.get("id", ""))
		var themes: Dictionary = {"lmc": 0, "smc": 1, "ngc6822": 3, "m31": 2, "m33": 4}
		_station_symbol.call("configure", int(themes.get(str(region.get("id", "")), 0)), _sun_color)
		add_child(_station_symbol)
	else:
		_station_sprite = null
		_station_symbol = null
	_update_positions()

func _process(delta: float) -> void:
	_time += delta
	_update_positions()

func set_camera_address(sector: Vector2i, local_position: Vector2, camera_offset: Vector2) -> void:
	_camera_world = Vector2(sector) * WorldAddress.SECTOR_SIZE + local_position + camera_offset
	_update_positions()

func resize_view(view: Vector2) -> void:
	_view = view
	_update_positions()

func _world_for(data: Dictionary, phase: float) -> Vector2:
	var radius: float = float(data.get("orbit", 500.0))
	return Vector2.from_angle(phase) * radius

func _update_positions() -> void:
	var half: Vector2 = _view * 0.5
	if _star_orb != null:
		_star_orb.position = half - _camera_world
	for i in range(_planets.size()):
		var body: Dictionary = _planets[i]
		var data: Dictionary = body["data"]
		var phase: float = float(body["phase"]) + _time * TAU / float(data.get("period", 350.0))
		var world: Vector2 = _world_for(data, phase)
		(body["node"] as Node2D).position = world - _camera_world + half
		body["world"] = world
		_planets[i] = body
	for i in range(_moons.size()):
		var moon: Dictionary = _moons[i]
		var planet_index: int = int(moon["planet_index"])
		var home: Vector2 = _planets[planet_index]["world"]
		var angle: float = float(moon["phase"]) + _time * float(moon["speed"])
		var position: Vector2 = home + Vector2.from_angle(angle) * float(moon["radius"])
		(moon["node"] as Sprite2D).position = position - _camera_world + half
	for mark in _landmarks:
		var home: Vector2 = _planets[int(mark["planet_index"])]["world"]
		var planet_data: Dictionary = _planets[int(mark["planet_index"])]["data"]
		var radius: float = float(planet_data.get("size", 140.0)) * 0.74 + 44.0
		(mark["node"] as Node2D).position = home + Vector2.from_angle(float(mark["angle"])) * radius - _camera_world + half
	if _station_sprite != null:
		_station_sprite.position = _station_world() - _camera_world + half
	if _station_symbol != null:
		_station_symbol.position = _station_world() - _camera_world + half
	queue_redraw()

func _station_world() -> Vector2:
	if _planets.is_empty():
		return Vector2(300.0, -260.0)
	var anchor: Vector2 = _planets[2]["world"]
	return anchor + Vector2.from_angle(_time / 120.0 + 1.2) * 240.0

func get_target_state(target_id: String) -> Dictionary:
	for body in _planets:
		var data: Dictionary = body["data"]
		if str(data["id"]) != target_id:
			continue
		var world: Vector2 = body["world"]
		var vel: Vector2 = Vector2(-world.y, world.x) * (TAU / float(data["period"]))
		return {"valid": true, "world": world, "velocity": vel, "arrival_radius": maxf(85.0, float(data["size"]) * 0.68)}
	var station: Variant = _region.get("station", null)
	if station is Dictionary and target_id == str(station.get("id", "")):
		return {"valid": true, "world": _station_world(), "velocity": Vector2.ZERO, "arrival_radius": 82.0}
	return {"valid": false}

func get_navigation_bodies() -> Array[Dictionary]:
	var bodies: Array[Dictionary] = []
	if str(_region.get("id", "")) == "crossroads":
		bodies.append({"name": "Crossroads", "world": Vector2.ZERO, "color": Color(0.61, 0.82, 1.0), "orbit": 0.0})
		return bodies
	bodies.append({"name": "Sun", "world": Vector2.ZERO, "color": _sun_color, "orbit": 0.0})
	for body in _planets:
		var data: Dictionary = body["data"]
		var p_color: Color = Color.html(str(data.get("palette", ["#82aadd"])[0]))
		bodies.append({"name": str(data["name_en"]), "world": body["world"], "color": p_color, "orbit": float(data["orbit"])})
	if _station_sprite != null:
		bodies.append({"name": "EarthStation", "world": _station_world(), "color": Color(0.99, 0.79, 0.39), "orbit": 0.0})
	return bodies

func _draw() -> void:
	var center: Vector2 = _view * 0.5 - _camera_world
	if str(_region.get("id", "")) == "crossroads":
		for k in range(3):
			draw_arc(center, 125.0 + k * 39.0, _time * 0.10 * (k + 1), _time * 0.10 * (k + 1) + TAU * 0.80, 100, Color(0.35 + k * 0.11, 0.70, 1.0, 0.6), 4.0, true)
		draw_circle(center, 60.0, Color(0.12, 0.36, 0.66, 0.20))
		return
	if center.distance_to(_view * 0.5) < 3500.0:
		draw_circle(center, 84.0, Color(_sun_color.r, _sun_color.g, _sun_color.b, 0.06))
		# The real star sprite uses a transparent, soft corona. No solid disc here.
	for body in _planets:
		var data: Dictionary = body["data"]
		var radius: float = float(data["orbit"])
		if center.distance_to(_view * 0.5) < radius + maxf(_view.x, _view.y) + 150.0:
			draw_arc(center, radius, 0.0, TAU, 120, Color(0.26, 0.45, 0.62, 0.14), 1.0, true)
