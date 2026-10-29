extends Node2D
## Runtime façade: preserves the existing SolarSystem interface for MW while
## providing independently populated atlas regions in the other five galaxies.
const SolarClass = preload("res://scripts/SolarSystem.gd")
const OtherClass = preload("res://scripts/OtherSystem.gd")
const INITIAL_SHIP_POSITION: Vector2 = Vector2(650.0, 35.0)
const ORBIT_RADIUS: float = 565.0
const ORBIT_PERIOD_SECONDS: float = 180.0
const OUTER_ORBIT_RADIUS: float = 2250.0
const CATALOG: String = "res://atlas/world_atlas.json"

var current_id: String = "mw"
var _all: Dictionary = {}
var _original
var _other
var _extra_moons: Array[Dictionary] = []
var _callisto_shipyard: Node2D
var _callisto_world: Vector2 = Vector2.ZERO
var _elapsed: float = 0.0
const MOON_TEXTURE: Texture2D = preload("res://assets/solar/moon_surface.png")
const WorldAddress = preload("res://scripts/WorldPosition.gd")
const LandmarkClass = preload("res://scripts/AtlasLandmark.gd")
const StationScene: PackedScene = preload("res://station2d/orbital_station_2d.tscn")
var _camera_sector: Vector2i = Vector2i.ZERO
var _camera_local: Vector2 = INITIAL_SHIP_POSITION
var _camera_offset: Vector2 = Vector2.ZERO
var _viewport_size: Vector2 = Vector2(1024, 576)

func _ready() -> void:
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(CATALOG))
	if parsed is Dictionary:
		for item in parsed.get("systems", []):
			_all[str(item.get("id", ""))] = item
	_original = SolarClass.new()
	_original.name = "ExistingSolarSystem_MIKO"
	add_child(_original)
	_other = OtherClass.new()
	_other.name = "FiveOtherGalaxies_Atlas"
	add_child(_other)
	_other.visible = false
	_other.process_mode = Node.PROCESS_MODE_DISABLED
	_build_home_moons()
	_callisto_shipyard = StationScene.instantiate() as Node2D
	_callisto_shipyard.name = "StoryLocation_CallistoShipyard_MIKA_Atlas"
	_callisto_shipyard.call("set_station_diameter", 76.0)
	_callisto_shipyard.call("set_spin_period", 54.0)
	_callisto_shipyard.call("set_module_count", 8)
	add_child(_callisto_shipyard)

func set_region(id: String) -> bool:
	if not _all.has(id):
		return false
	current_id = id
	var is_home: bool = id == "mw"
	_original.visible = is_home
	_original.process_mode = Node.PROCESS_MODE_INHERIT if is_home else Node.PROCESS_MODE_DISABLED
	_other.visible = not is_home
	_other.process_mode = Node.PROCESS_MODE_DISABLED if is_home else Node.PROCESS_MODE_INHERIT
	if not is_home:
		_other.configure_region(_all[id], _elapsed)
	for moon in _extra_moons:
		(moon["sprite"] as Sprite2D).visible = is_home
	_callisto_shipyard.visible = is_home
	set_camera_address(_camera_sector, _camera_local, _camera_offset)
	resize_view(_viewport_size)
	return true

func get_system(id: String) -> Dictionary:
	return _all.get(id, {})

func get_current_name() -> String:
	return str(get_system(current_id).get("name_en", "Unknown"))

func get_map_destinations() -> Array:
	return get_system(current_id).get("planets", [])

func set_camera_address(sector: Vector2i, local_position: Vector2, camera_offset: Vector2) -> void:
	_camera_sector = sector
	_camera_local = local_position
	_camera_offset = camera_offset
	if current_id == "mw":
		_original.set_camera_address(sector, local_position, camera_offset)
	else:
		_other.set_camera_address(sector, local_position, camera_offset)

func resize_view(view_size: Vector2) -> void:
	_viewport_size = view_size
	if current_id == "mw":
		_original.resize_view(view_size)
	else:
		_other.resize_view(view_size)

func get_navigation_bodies() -> Array[Dictionary]:
	if current_id != "mw":
		return _other.get_navigation_bodies()
	var found: Array[Dictionary] = _original.get_navigation_bodies()
	for moon in _extra_moons:
		found.append({"name": str(moon["name"]), "world": moon["world"], "orbit": 0.0, "color": Color(0.72, 0.79, 0.92)})
	found.append({"name": "CallistoShipyard", "world": _callisto_world, "orbit": 0.0, "color": Color(0.98, 0.79, 0.42)})
	return found

func get_target_state(target_id: String) -> Dictionary:
	if current_id == "mw" and target_id == "st_mw":
		return {"valid": true, "world": _callisto_world, "velocity": Vector2.ZERO, "arrival_radius": 78.0}
	return _original.get_target_state(target_id) if current_id == "mw" else _other.get_target_state(target_id)

func earth_world_position() -> Vector2:
	return _original.earth_world_position()

func get_spawn_position() -> Vector2:
	if current_id == "mw":
		return INITIAL_SHIP_POSITION
	return Vector2(-2280.0, -220.0) if current_id != "crossroads" else Vector2(-320.0, 400.0)


func _build_home_moons() -> void:
	# Earth Moon already exists in the previous MIKO SolarSystem module.
	var planet_names: Dictionary = {"mw_p02":"Mars", "mw_p03":"Jupiter", "mw_p04":"Saturn", "mw_p05":"Uranus", "mw_p06":"Neptune"}
	var index: int = 0
	for planet in get_system("mw").get("planets", []):
		var parent: String = str(planet_names.get(str(planet.get("id", "")), ""))
		if parent == "":
			continue
		var moons: Array = planet.get("moons", [])
		for i in range(moons.size()):
			var sprite: Sprite2D = Sprite2D.new()
			sprite.name = "Moon_" + str(moons[i])
			sprite.texture = MOON_TEXTURE
			sprite.scale = Vector2.ONE * ((18.0 + float(i % 3) * 6.0) / float(MOON_TEXTURE.get_width()))
			sprite.modulate = Color(0.80, 0.82, 0.90) if i % 2 == 0 else Color(0.87, 0.76, 0.63)
			add_child(sprite)
			_extra_moons.append({"sprite": sprite, "name": str(moons[i]), "home": parent, "phase": float(index) * 2.22, "radius": 115.0 + float(i) * 40.0, "world": Vector2.ZERO})
			index += 1

func _process(delta: float) -> void:
	_elapsed += delta
	if current_id != "mw":
		return
	var bodies: Dictionary = {}
	for body in _original.get_navigation_bodies():
		bodies[str(body["name"])] = body["world"]
	var camera: Vector2 = Vector2(_camera_sector) * WorldAddress.SECTOR_SIZE + _camera_local + _camera_offset
	for i in range(_extra_moons.size()):
		var m: Dictionary = _extra_moons[i]
		var home: Vector2 = bodies.get(str(m["home"]), Vector2.ZERO)
		var phase: float = float(m["phase"]) + _elapsed * (0.036 + float(i % 5) * 0.012)
		var position: Vector2 = home + Vector2.from_angle(phase) * float(m["radius"])
		(m["sprite"] as Sprite2D).position = position - camera + _viewport_size * 0.5
		m["world"] = position
		_extra_moons[i] = m
		if str(m["name"]) == "Каллисто":
			_callisto_world = position + Vector2(36.0, -18.0)
	if _callisto_shipyard != null:
		_callisto_shipyard.position = _callisto_world - camera + _viewport_size * 0.5
