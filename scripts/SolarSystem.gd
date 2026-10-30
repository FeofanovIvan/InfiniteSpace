extends Node2D
## Fixed MIKO Sun and eight MIKO V3 rotating planet scenes.
## Child-readable planet sizes; the four gas giants are larger than terrestrial worlds.
## Orbit gaps prevent visual overlaps between enlarged neighboring planets.
## Gameplay radii/periods are compressed for legibility, NOT physical ephemerides.
## Planet longitude and orbit motion are independent. No camera parenting.

const EarthScene: PackedScene = preload("res://planets/earth.tscn")
const PLANET_SCENES: Dictionary = {
	"Mercury": preload("res://planets/mercury.tscn"),
	"Venus": preload("res://planets/venus.tscn"),
	"Mars": preload("res://planets/mars.tscn"),
	"Jupiter": preload("res://planets/jupiter.tscn"),
	"Saturn": preload("res://planets/saturn.tscn"),
	"Uranus": preload("res://planets/uranus.tscn"),
	"Neptune": preload("res://planets/neptune.tscn")
}
const SUN_BODY_SHADER: Shader = preload("res://solar/sun/sun_body.gdshader")
const SUN_CORONA_SHADER: Shader = preload("res://solar/sun/sun_corona.gdshader")
const SUN_TEXTURE: Texture2D = preload("res://solar/sun/sun_surface_1536x768.png")
const SUN_FLOW: Texture2D = preload("res://solar/sun/sun_plasma_flow_512x256.png")
# Station shells are anchored to planet CENTERS, not to the rotating surface.
# All 8 planets remain visible. Only five worlds have inhabited infrastructure.
const STATION_SHELL_SCENES: Dictionary = {
	"Earth": preload("res://station_overlays/scenes/OrbitalStation_01.tscn"),
	"Venus": preload("res://station_overlays/scenes/OrbitalStation_02.tscn"),
	"Mars": preload("res://station_overlays/scenes/OrbitalStation_03.tscn"),
	"Jupiter": preload("res://station_overlays/scenes/OrbitalStation_04.tscn"),
	"Neptune": preload("res://station_overlays/scenes/OrbitalStation_02.tscn")
}
# Mobile-optimized 512px artwork is half-scale of the 1024px MIKO source.
const STATION_ART_PLANET_DIAMETER: float = 320.0
const WorldAddress = preload("res://scripts/WorldPosition.gd")

const SUN_WORLD: Vector2 = Vector2.ZERO
const ORBIT_RADIUS: float = 565.0
const ORBIT_PERIOD_SECONDS: float = 180.0
const SUN_DIAMETER: float = 186.0
const CORONA_DIAMETER: float = 300.0
const EARTH_DIAMETER: float = 120.0
const MOON_DIAMETER: float = 38.0
const MOON_ORBIT_RADIUS: float = 136.0
const MOON_ORBIT_PERIOD_SECONDS: float = 48.0
const MoonLibrary = preload("res://scripts/MoonLibrary.gd")
const OUTER_ORBIT_RADIUS: float = 1950.0
const INITIAL_SHIP_POSITION: Vector2 = Vector2(650.0, 35.0)
# One standalone repair shipyard, placed beyond the outer planet/moon envelope.
# This is a game-layout coordinate, not an astronomical location claim.
const REMOTE_SHIPYARD_WORLD: Vector2 = Vector2(-2150.0, 1850.0)
const REMOTE_SHIPYARD_ARRIVAL_RADIUS: float = 165.0

# Compressed gameplay orbits remain identical to v0.9; graphics now use MIKO V3.
# The 'spin' values match the signed demo spin periods provided by MIKO V3.
const PLANET_ORBITS = [
	{"name": "Mercury", "orbit": 245.0, "period": 85.0, "phase": 1.45, "size": 108.0, "spin": 100.0, "color": Color(0.60, 0.59, 0.56), "bands": Color(0.82, 0.77, 0.72), "rings": false},
	{"name": "Venus", "orbit": 395.0, "period": 130.0, "phase": 3.10, "size": 118.0, "spin": -135.0, "color": Color(0.91, 0.72, 0.46), "bands": Color(1.0, 0.90, 0.69), "rings": false},
	{"name": "Mars", "orbit": 740.0, "period": 255.0, "phase": 5.05, "size": 112.0, "spin": 46.0, "color": Color(0.78, 0.34, 0.21), "bands": Color(0.99, 0.63, 0.39), "rings": false},
	{"name": "Jupiter", "orbit": 990.0, "period": 440.0, "phase": 1.20, "size": 236.0, "spin": 27.0, "color": Color(0.77, 0.58, 0.40), "bands": Color(0.98, 0.84, 0.65), "rings": false},
	{"name": "Saturn", "orbit": 1270.0, "period": 650.0, "phase": 3.83, "size": 220.0, "spin": 32.0, "color": Color(0.88, 0.76, 0.52), "bands": Color(0.99, 0.91, 0.71), "rings": true},
	{"name": "Uranus", "orbit": 1600.0, "period": 900.0, "phase": 4.85, "size": 188.0, "spin": -54.0, "color": Color(0.42, 0.78, 0.81), "bands": Color(0.78, 0.98, 0.96), "rings": false},
	{"name": "Neptune", "orbit": OUTER_ORBIT_RADIUS, "period": 1160.0, "phase": 0.47, "size": 192.0, "spin": 46.0, "color": Color(0.19, 0.37, 0.81), "bands": Color(0.45, 0.74, 0.99), "rings": false}
]

var _sun: Node2D
var _earth
var _moon: Node2D
var _moon_phase: float = 2.40
var _orbit_phase: float = 0.0
var _camera_world: Vector2 = INITIAL_SHIP_POSITION
var _view_size: Vector2 = Vector2(1280.0, 720.0)
var _planet_nodes: Array[Node2D] = []
var _planet_data: Array[Dictionary] = []
var _station_shells: Dictionary = {}


func _ready() -> void:
	_build_sun()
	_earth = EarthScene.instantiate()
	_earth.name = "Earth_Orbiting_2D"
	add_child(_earth)
	_earth.set_planet_diameter(EARTH_DIAMETER)
	_earth.set_rotation_period(55.0)
	_earth.set_atmosphere(0.8)
	_build_moon()
	for definition in PLANET_ORBITS:
		var data: Dictionary = definition.duplicate()
		var planet_name: String = str(data["name"])
		var scene: PackedScene = PLANET_SCENES[planet_name] as PackedScene
		var planet: Node2D = scene.instantiate() as Node2D
		if planet == null:
			push_error("MIKO planet scene is not Node2D: " + planet_name)
			continue
		planet.name = planet_name + "_MIKO_V3"
		add_child(planet)
		planet.call("set_planet_diameter", float(data["size"]))
		planet.call("set_rotation_period", float(data["spin"]))
		planet.call("set_rotation_phase", rad_to_deg(float(data["phase"])))
		_planet_nodes.append(planet)
		_planet_data.append(data)
	_build_planet_station_shells()
	_update_visual_positions()


func _build_moon() -> void:
	# One lightweight sprite; the orbital POSITION moves while the Moon's
	# appearance itself does not need a heavy extra planet shader.
	_moon = MoonLibrary.make_moon("mw_p01_m01", MOON_DIAMETER + 9.0)
	if _moon == null:
		push_error("Cannot instantiate supplied Earth Moon")
		return
	_moon.name = "MoonOrbitingEarth_mw_p01_m01"
	_moon.z_index = 4
	add_child(_moon)


func moon_world_position() -> Vector2:
	return earth_world_position() + Vector2.from_angle(_moon_phase) * MOON_ORBIT_RADIUS


func _build_planet_station_shells() -> void:
	# Layer order: back shell z=-1, rotating planet globe z=0, front shell z=+1.
	# Shells never spin around their own axes, but translate with the planets.
	for planet_id in STATION_SHELL_SCENES:
		var packed: PackedScene = STATION_SHELL_SCENES[planet_id] as PackedScene
		var shell: Node2D = packed.instantiate() as Node2D
		if shell == null:
			push_error("Invalid MIKO orbital overlay: " + str(planet_id))
			continue
		shell.name = "AnchoredStation_" + str(planet_id)
		var planet_diameter: float = EARTH_DIAMETER if planet_id == "Earth" else _diameter_for_planet(str(planet_id))
		shell.scale = Vector2.ONE * (planet_diameter / STATION_ART_PLANET_DIAMETER)
		shell.rotation = 0.0
		# Ship traffic is rendered above even the foreground ring elements.
		add_child(shell)
		_station_shells[planet_id] = shell


func _diameter_for_planet(planet_id: String) -> float:
	for data in _planet_data:
		if str(data["name"]) == planet_id:
			return float(data["size"])
	return EARTH_DIAMETER


func _build_sun() -> void:
	_sun = Node2D.new()
	_sun.name = "Sun_Rotating_2D"
	add_child(_sun)
	var corona: ColorRect = ColorRect.new()
	corona.name = "Corona"
	corona.size = Vector2.ONE * CORONA_DIAMETER
	corona.position = -corona.size * 0.5
	corona.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var corona_mat: ShaderMaterial = ShaderMaterial.new()
	corona_mat.shader = SUN_CORONA_SHADER
	corona_mat.set_shader_parameter("solar_radius", SUN_DIAMETER / CORONA_DIAMETER)
	corona_mat.set_shader_parameter("corona_strength", 0.85)
	corona.material = corona_mat
	_sun.add_child(corona)
	var surface: ColorRect = ColorRect.new()
	surface.name = "SunSurface"
	surface.size = Vector2.ONE * SUN_DIAMETER
	surface.position = -surface.size * 0.5
	surface.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var mat: ShaderMaterial = ShaderMaterial.new()
	mat.shader = SUN_BODY_SHADER
	mat.set_shader_parameter("surface_tex", SUN_TEXTURE)
	mat.set_shader_parameter("plasma_flow", SUN_FLOW)
	mat.set_shader_parameter("rotation_seconds", 28.0)
	mat.set_shader_parameter("differential", 0.28)
	mat.set_shader_parameter("activity", 0.26)
	surface.material = mat
	_sun.add_child(surface)


func _process(delta: float) -> void:
	_orbit_phase = wrapf(_orbit_phase + TAU * delta / ORBIT_PERIOD_SECONDS, 0.0, TAU)
	_moon_phase = wrapf(_moon_phase + TAU * delta / MOON_ORBIT_PERIOD_SECONDS, 0.0, TAU)
	for i in range(_planet_data.size()):
		var data: Dictionary = _planet_data[i]
		data["phase"] = wrapf(float(data["phase"]) + TAU * delta / float(data["period"]), 0.0, TAU)
	_update_visual_positions()


func earth_world_position() -> Vector2:
	return Vector2(cos(_orbit_phase), sin(_orbit_phase)) * ORBIT_RADIUS


func station_world_position() -> Vector2:
	# The retired EarthOrbitStation sprite is deliberately NOT instantiated.
	# Legacy EarthStation NPC routes and the new st_mw destination refer to
	# exactly the same remote shipyard; no duplicate visual station is created.
	return REMOTE_SHIPYARD_WORLD


func get_target_state(target_id: String) -> Dictionary:
	# Autopilot is limited to inhabited worlds and the separate orbital station.
	if target_id != "EarthStation" and not STATION_SHELL_SCENES.has(target_id):
		return {"valid": false}
	# Position and instantaneous velocity are recalculated every physics frame;
	# autopilot never chases the outdated position selected in the menu.
	if target_id == "Earth":
		var earth_pos: Vector2 = earth_world_position()
		return {"valid": true, "world": earth_pos, "velocity": Vector2(-earth_pos.y, earth_pos.x) * TAU / ORBIT_PERIOD_SECONDS, "arrival_radius": 76.0}
	if target_id == "EarthStation":
		return {"valid": true, "world": REMOTE_SHIPYARD_WORLD,
			"velocity": Vector2.ZERO, "arrival_radius": REMOTE_SHIPYARD_ARRIVAL_RADIUS}
	for data in _planet_data:
		if str(data["name"]) == target_id:
			var orbit_radius: float = float(data["orbit"])
			var phase: float = float(data["phase"])
			var pos: Vector2 = Vector2(cos(phase), sin(phase)) * orbit_radius
			var tangential: Vector2 = Vector2(-pos.y, pos.x) * TAU / float(data["period"])
			return {"valid": true, "world": pos, "velocity": tangential, "arrival_radius": maxf(83.0, float(data["size"]) * 0.68)}
	return {"valid": false}


func set_camera_address(sector: Vector2i, local_position: Vector2, camera_offset: Vector2) -> void:
	_camera_world = Vector2(sector) * WorldAddress.SECTOR_SIZE + local_position + camera_offset
	_update_visual_positions()


func resize_view(view_size: Vector2) -> void:
	_view_size = view_size
	_update_visual_positions()


func get_navigation_bodies() -> Array[Dictionary]:
	# A tiny list for the HUD; no background stars or generated dust.
	var result: Array[Dictionary] = [
		{"name": "Sun", "world": SUN_WORLD, "orbit": 0.0, "color": Color(1.0, 0.68, 0.18)},
		{"name": "Earth", "world": earth_world_position(), "orbit": ORBIT_RADIUS, "color": Color(0.24, 0.69, 1.0)}
	]
	for data in _planet_data:
		var phase: float = float(data["phase"])
		var radius: float = float(data["orbit"])
		result.append({"name": data["name"], "world": Vector2(cos(phase), sin(phase)) * radius, "orbit": radius, "color": data["color"]})
	result.append({"name": "Moon", "kind": "moon", "world": moon_world_position(), "orbit": 0.0, "color": Color(0.77, 0.81, 0.91)})
	result.append({"name": "EarthStation", "kind": "station", "world": station_world_position(), "orbit": 0.0, "color": Color(0.99, 0.82, 0.42)})
	return result


func _update_visual_positions() -> void:
	if not is_instance_valid(_sun) or not is_instance_valid(_earth):
		return
	var viewport_center: Vector2 = _view_size * 0.5
	var sun_screen: Vector2 = SUN_WORLD - _camera_world + viewport_center
	var earth_world: Vector2 = earth_world_position()
	var earth_screen: Vector2 = earth_world - _camera_world + viewport_center
	_sun.position = sun_screen
	_earth.position = earth_screen
	_sun.visible = _is_visible(sun_screen, CORONA_DIAMETER)
	_earth.visible = _is_visible(earth_screen, EARTH_DIAMETER)
	var moon_screen: Vector2 = moon_world_position() - _camera_world + viewport_center
	_moon.position = moon_screen
	_moon.visible = _is_visible(moon_screen, MOON_DIAMETER + 9.0)
	if _moon.visible:
		var moon_sun_dir: Vector2 = (SUN_WORLD - moon_world_position()).normalized()
		_moon.call("set_light_direction", Vector3(moon_sun_dir.x * 0.7, moon_sun_dir.y * 0.7, 0.72))
	if _station_shells.has("Earth"):
		var earth_shell: Node2D = _station_shells["Earth"] as Node2D
		earth_shell.position = earth_screen
		earth_shell.visible = _is_visible(earth_screen, EARTH_DIAMETER * 1.8)
	if _earth.visible:
		var sun_dir: Vector2 = (SUN_WORLD - earth_world).normalized()
		_earth.set_sun_direction(Vector3(sun_dir.x * 0.7, sun_dir.y * 0.7, 0.72))
	for i in range(_planet_nodes.size()):
		var data: Dictionary = _planet_data[i]
		var radius: float = float(data["orbit"])
		var phase: float = float(data["phase"])
		var planet_world: Vector2 = Vector2(cos(phase), sin(phase)) * radius
		var planet_screen: Vector2 = planet_world - _camera_world + viewport_center
		var planet_node: Node2D = _planet_nodes[i]
		planet_node.position = planet_screen
		planet_node.visible = _is_visible(planet_screen, float(data["size"]) * 1.6)
		var planet_id: String = str(data["name"])
		if _station_shells.has(planet_id):
			var anchored_shell: Node2D = _station_shells[planet_id] as Node2D
			anchored_shell.position = planet_screen
			anchored_shell.visible = _is_visible(planet_screen, float(data["size"]) * 1.8)
		if planet_node.visible:
			var light_vector: Vector2 = (SUN_WORLD - planet_world).normalized()
			planet_node.call("set_sun_direction", Vector3(light_vector.x * 0.7, light_vector.y * 0.7, 0.72))
	queue_redraw()


func _draw() -> void:
	# A very subtle guide helps children see that the Moon travels around Earth.
	var earth_screen: Vector2 = earth_world_position() - _camera_world + _view_size * 0.5
	if _is_visible(earth_screen, MOON_ORBIT_RADIUS + MOON_DIAMETER):
		draw_arc(earth_screen, MOON_ORBIT_RADIUS, 0.0, TAU, 96, Color(0.56, 0.74, 0.94, 0.17), 1.0, true)


func _is_visible(screen_position: Vector2, extent: float) -> bool:
	return absf(screen_position.x - _view_size.x * 0.5) < _view_size.x * 0.5 + extent and absf(screen_position.y - _view_size.y * 0.5) < _view_size.y * 0.5 + extent
