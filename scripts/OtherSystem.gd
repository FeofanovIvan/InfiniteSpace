extends Node2D
## Atlas-based star-system gameplay prototype. LMC uses real supplied MIKO
## shader scenes; other worlds use distinct generated preview textures.
## A region is an illustrated playground, not an astronomical assertion that
## all planets in a real galaxy orbit one star.
const WorldAddress = preload("res://scripts/WorldPosition.gd")
const MoonLibrary = preload("res://scripts/MoonLibrary.gd")
const STATION_TEXTURE: Texture2D = preload("res://assets/destinations/earth_station.png")
const TARANTULA_TEXTURE: Texture2D = preload("res://assets/story/tarantula_lab_ship.png")
const ARCHIVE_TEXTURE: Texture2D = preload("res://assets/story/living_archive_lotus.png")
const TITAN_SKULL_TEXTURE: Texture2D = preload("res://assets/story/titan_skull_ngc6822.png")
const PYRAMID_TEXTURE: Texture2D = preload("res://assets/story/inverted_pyramid_m31.png")
const LAST_GATE_TEXTURE: Texture2D = preload("res://assets/story/last_gate_m33.png")
const LivingWorldStormScene: PackedScene = preload("res://living_world_storm_2d/living_world_storm_2d.tscn")
const CROSSROADS_NEBULA_SHADER: Shader = preload("res://shaders/far_plasma.gdshader")
const TITAN_ASTEROID_TEXTURES: Array[Texture2D] = [
	preload("res://asteroid_assets/original/01_gray_cratered.png"),
	preload("res://asteroid_assets/original/03_dark_fissured.png"),
	preload("res://asteroid_assets/original/04_blue_mineral.png")
]
const ARCHIVE_NEBULA_SHADER: Shader = preload("res://shaders/far_plasma.gdshader")
const TarantulaThrusters = preload("res://scripts/TarantulaThrusters.gd")
# Five independent story locations in DISTINCT remote sectors beyond the planetary
# orbits. These are game-map placements (not real astrophysical coordinates).
# No station follows any planet's orbit, and none duplicates the MW shipyard angle.
const STORY_STATION_ANCHORS: Dictionary = {
	"lmc": Vector2(2350.0, -1690.0),    # upper-right: Tarantula laboratory ship
	"smc": Vector2(1490.0, 2410.0),     # lower-right: Living Archive
	"ngc6822": Vector2(-580.0, -2810.0), # upper-center: Titan's Head port
	"m31": Vector2(-2490.0, -1350.0),    # upper-left: inverted pyramid
	"m33": Vector2(2880.0, 460.0)       # right: Last Gates
}
# Slow gravity-inspired epicycles. The same analytic orbit drives both visuals
# and autopilot target velocity; no independent fake navigation position.
const STORY_ORBIT_AMPLITUDE: Dictionary = {"lmc": 38.0, "smc": 23.0, "ngc6822": 46.0, "m31": 31.0, "m33": 19.0}
const STORY_ORBIT_SECONDS: Dictionary = {"lmc": 410.0, "smc": 530.0, "ngc6822": 370.0, "m31": 490.0, "m33": 610.0}
const STORY_ORBIT_PHASE: Dictionary = {"lmc": 0.7, "smc": 2.1, "ngc6822": 4.2, "m31": 5.4, "m33": 3.0}
const StoryStationFX = preload("res://scripts/StoryStationFX.gd")
const LastGateFX = preload("res://scripts/LastGateFX.gd")
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
const M31_SCENES: Array[PackedScene] = [
	preload("res://m31_planets/planets/m31_p01.tscn"),
	preload("res://m31_planets/planets/m31_p02.tscn"),
	preload("res://m31_planets/planets/m31_p03.tscn"),
	preload("res://m31_planets/planets/m31_p04.tscn"),
	preload("res://m31_planets/planets/m31_p05.tscn"),
	preload("res://m31_planets/planets/m31_p06.tscn"),
	preload("res://m31_planets/planets/m31_p07.tscn"),
	preload("res://m31_planets/planets/m31_p08.tscn")
]
const M33_SCENES: Array[PackedScene] = [
	preload("res://m33_planets/planets/m33_p01.tscn"),
	preload("res://m33_planets/planets/m33_p02.tscn"),
	preload("res://m33_planets/planets/m33_p03.tscn"),
	preload("res://m33_planets/planets/m33_p04.tscn"),
	preload("res://m33_planets/planets/m33_p05.tscn"),
	preload("res://m33_planets/planets/m33_p06.tscn"),
	preload("res://m33_planets/planets/m33_p07.tscn"),
	preload("res://m33_planets/planets/m33_p08.tscn")
]
const STATION_SHELL_VARIANTS: Array[PackedScene] = [
	preload("res://station_overlays/scenes/OrbitalStation_01.tscn"),
	preload("res://station_overlays/scenes/OrbitalStation_02.tscn"),
	preload("res://station_overlays/scenes/OrbitalStation_03.tscn"),
	preload("res://station_overlays/scenes/OrbitalStation_04.tscn")
]
const STATION_ART_PLANET_DIAMETER: float = 320.0
const VISUAL_INNER_ORBIT: float = 360.0
const VISUAL_ORBIT_SCALE: float = 1.12
const RING_MOON_CLEARANCE_FACTOR: float = 0.42
const RING_MOON_CLEARANCE_BONUS: float = 28.0
# Number of rings across the WHOLE galaxy-region playground, never per planet.
# The native Milky Way / Earth scene is untouched by this external-system file.
const SYSTEM_RING_COUNTS: Dictionary = {
	"lmc": 2,
	"smc": 3,
	"ngc6822": 2,
	"m31": 4,
	"m33": 3
}
var _region: Dictionary = {}
var _planets: Array[Dictionary] = []
var _moons: Array[Dictionary] = []
var _station_sprite: Sprite2D
var _story_station_root: Node2D
var _archive_nebula: Array[ColorRect] = []
var _system_nebulae: Array[ColorRect] = []
var _system_nebula_data: Array[Dictionary] = []
var _titan_ring_rocks: Array[Dictionary] = []
var _tarantula_thrusters: Node2D
var _story_fx: Node2D
var _crossroads_world: Node2D
var _crossroads_nebulae: Array[ColorRect] = []
var _crossroads_nebula_data: Array[Dictionary] = []
var _crossroads_pulse_index: int = -1
var _crossroads_storm_flash_index: int = -1
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
	for child in get_children():
		remove_child(child)
		child.queue_free()
	var color_text: String = str(region.get("sun_color", "#ffbc82"))
	_sun_color = Color.html(color_text)
	_star_orb = null
	_story_station_root = null
	_station_sprite = null
	_archive_nebula.clear()
	_system_nebulae.clear()
	_system_nebula_data.clear()
	_titan_ring_rocks.clear()
	_tarantula_thrusters = null
	_story_fx = null
	_crossroads_world = null
	_crossroads_nebulae.clear()
	_crossroads_nebula_data.clear()
	_crossroads_pulse_index = -1
	_crossroads_storm_flash_index = -1
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
		_star_orb.z_index = 2
		add_child(_star_orb)
	if str(region.get("id", "")) != "crossroads":
		# Background gas layers belong to this system and stay behind its planets.
		_add_system_background_nebulae(str(region.get("id", "")))
		# Select at most one ring per world; repeat visits keep the same layout.
		var ring_assignments: Dictionary = _choose_system_ring_stations(region)
		for i in range(region.get("planets", []).size()):
			var source: Dictionary = region["planets"][i]
			var root: Node2D = Node2D.new()
			root.name = str(source["id"]) + "_Globe"
			root.z_index = 3
			add_child(root)
			var diameter: float = float(source.get("size", 140.0))
			var region_id: String = str(region.get("id", ""))
			var library: Array[PackedScene] = _library_for_region(region_id)
			if not library.is_empty() and i < library.size():
				var globe: Node2D = library[i].instantiate() as Node2D
				root.add_child(globe)
				globe.call("set_diameter", diameter)
			else:
				var sprite: Sprite2D = Sprite2D.new()
				sprite.texture = load(str(source["visual_asset"])) as Texture2D
				sprite.scale = Vector2.ONE * (diameter / 238.0)
				root.add_child(sprite)
			if ring_assignments.has(i):
				_build_planet_orbital_ring(root, source, diameter, ring_assignments[i])
			_planets.append({"data": source, "node": root, "phase": float(source["phase"]), "world": Vector2.ZERO, "index": i})
			# No AtlasLandmark: every such orbiting symbol was a fake moon/station.
			# Planet story metadata stays in world_atlas.json and navigation UI.
			var moons: Array = source.get("moons", [])
			for m in range(moons.size()):
				var moon_id: String = str(source["id"]) + ("_m%02d" % (m + 1))
				var diameter_m: float = 32.0 + float((i + m) % 4) * 4.5
				var moon_node: Node2D = MoonLibrary.make_moon(moon_id, diameter_m)
				if moon_node == null:
					continue
				add_child(moon_node)
				var orbit_radius: float = diameter * 0.69 + 34.0 + m * 31.0
				if ring_assignments.has(i):
					orbit_radius += diameter * RING_MOON_CLEARANCE_FACTOR + RING_MOON_CLEARANCE_BONUS
					moon_node.z_index = 6
				else:
					moon_node.z_index = 4
				_moons.append({"node": moon_node, "moon_id": moon_id, "planet_index": i, "name": str(moons[m]), "phase": float(m) * 2.4 + float(i), "radius": orbit_radius, "speed": 0.025 + 0.012 * m})
		var station_region_id: String = str(region.get("id", ""))
		_story_station_root = Node2D.new()
		_story_station_root.name = "SingleStoryStation_" + station_region_id
		_story_station_root.z_index = 3
		add_child(_story_station_root)
		# No generic concentric dark halo on Tarantula or the Living Archive.
		# The first has exactly three locally anchored engines; only the
		# second receives genuine irregular nebulae from the game's gas shader.
		if station_region_id == "smc":
			_add_archive_nebula()
		elif station_region_id == "ngc6822":
			_add_titan_nebula()
		elif station_region_id == "m33":
			_add_last_gate_nebula()
		_station_sprite = Sprite2D.new()
		_station_sprite.name = "StoryStation_" + station_region_id
		_station_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
		_station_sprite.z_index = 1
		if station_region_id == "lmc":
			_station_sprite.texture = TARANTULA_TEXTURE
			_station_sprite.scale = Vector2.ONE * 0.294
		elif station_region_id == "smc":
			_station_sprite.texture = ARCHIVE_TEXTURE
			_station_sprite.scale = Vector2.ONE * 0.30
		elif station_region_id == "ngc6822":
			_station_sprite.texture = TITAN_SKULL_TEXTURE
			_station_sprite.scale = Vector2.ONE * 0.255
		elif station_region_id == "m31":
			_station_sprite.texture = PYRAMID_TEXTURE
			_station_sprite.scale = Vector2.ONE * 0.33
		elif station_region_id == "m33":
			_station_sprite.texture = LAST_GATE_TEXTURE
			_station_sprite.scale = Vector2.ONE * 0.34
		else:
			_station_sprite.texture = STATION_TEXTURE
			_station_sprite.scale = Vector2.ONE * 0.58
		_story_station_root.add_child(_station_sprite)
		if station_region_id == "m33":
			_story_fx = LastGateFX.new()
			_story_fx.name = "Triangulum_LastGate_ElectricFilaments"
			_story_fx.z_index = 3
			_story_station_root.add_child(_story_fx)
		if station_region_id == "ngc6822":
			_build_titan_asteroid_ring()
		if station_region_id == "lmc":
			_tarantula_thrusters = TarantulaThrusters.new()
			_tarantula_thrusters.name = "ThreeBlueThrusters_AttachedToTarantula"
			_tarantula_thrusters.z_index = -1
			_station_sprite.add_child(_tarantula_thrusters)
		# Exactly ONE story landmark per region. No fake luminous orb.
	else:
		_story_station_root = null
		_station_sprite = null
		_archive_nebula.clear()
		_tarantula_thrusters = null
		_story_fx = null
		_crossroads_world = LivingWorldStormScene.instantiate() as Node2D
		if _crossroads_world != null:
			_crossroads_world.name = "Crossroads_LivingWorld"
			add_child(_crossroads_world)
			_crossroads_world.call("update_diameter", 312.0)
			_crossroads_world.call("set_mood", "listening")
			_crossroads_world.call("set_storm_state", "communicating")
			_crossroads_world.call("set_quality_low", false)
			_crossroads_world.call("set_storm_enabled", true)
		# Crossroads uses the SAME torn-gas shader as Lotus / Living Archive.
		# Deterministic world-space clumps: many near the core, fewer outward.
		# These are actual gas layers, not drawn dots, spokes or orbit rings.
		var cloud_count: int = 36
		for i in range(cloud_count):
			var band: int = 0 if i < 17 else (1 if i < 29 else 2)
			var band_start: int = 0 if band == 0 else (17 if band == 1 else 29)
			var band_count: int = 17 if band == 0 else (12 if band == 1 else 7)
			var local_index: int = i - band_start
			var rng: RandomNumberGenerator = RandomNumberGenerator.new()
			rng.seed = 485119 + i * 7919
			var radius_min: float = 130.0 if band == 0 else (730.0 if band == 1 else 1560.0)
			var radius_max: float = 760.0 if band == 0 else (1570.0 if band == 1 else 2650.0)
			var radius: float = lerpf(radius_min, radius_max, (float(local_index) + rng.randf_range(0.1, 0.9)) / float(band_count))
			var bearing: float = (float(local_index) + rng.randf_range(-0.28, 0.28)) * TAU / float(band_count) + float(band) * 0.31
			var offset: Vector2 = Vector2.from_angle(bearing) * radius
			var tint_choices: Array[Color] = [Color(0.29, 0.60, 1.0), Color(0.64, 0.34, 1.0), Color(0.96, 0.30, 0.51), Color(0.33, 0.84, 1.0), Color(0.92, 0.43, 0.76)]
			var info: Dictionary = {
				"offset": offset,
				"size": Vector2(rng.randf_range(480.0, 790.0), rng.randf_range(340.0, 650.0)) * (1.0 if band == 0 else (1.10 if band == 1 else 1.22)),
				"angle": rng.randf_range(-1.1, 1.1),
				"color": tint_choices[i % tint_choices.size()],
				"opacity": rng.randf_range(0.37, 0.51) if band == 0 else (rng.randf_range(0.25, 0.36) if band == 1 else rng.randf_range(0.17, 0.26)),
				"seed": rng.randf_range(0.0, 80.0),
				"style": float(1 + (i % 2)),
				"spin": rng.randf_range(-0.0019, 0.0019),
				"drift": rng.randf_range(8.0, 18.0)
			}
			var cloud: ColorRect = ColorRect.new()
			cloud.name = "Crossroads_SystemNebula_%02d" % i
			cloud.size = info["size"]
			cloud.color = Color.WHITE
			cloud.position = offset - cloud.size * 0.5
			cloud.pivot_offset = cloud.size * 0.5
			cloud.rotation = float(info["angle"])
			# Positive z is essential: Starfield draws an opaque black backdrop at 0.
			# Negative z previously placed all clouds BEHIND that backdrop.
			cloud.z_index = 1
			cloud.mouse_filter = Control.MOUSE_FILTER_IGNORE
			var mat: ShaderMaterial = ShaderMaterial.new()
			mat.shader = CROSSROADS_NEBULA_SHADER
			mat.set_shader_parameter("cloud_color", info["color"])
			mat.set_shader_parameter("cloud_opacity", float(info["opacity"]))
			mat.set_shader_parameter("cloud_seed", float(info["seed"]))
			mat.set_shader_parameter("style", float(info["style"]))
			mat.set_shader_parameter("glow_strength", 0.65)
			cloud.material = mat
			add_child(cloud)
			_crossroads_nebulae.append(cloud)
			_crossroads_nebula_data.append(info)
		# The living planet is above the gas, but below ships and HUD.
		if _crossroads_world != null:
			_crossroads_world.z_index = 3
	_update_positions()

func _add_archive_nebula() -> void:
	# Use the existing game plasma shader: irregular, torn, transparent gas
	# filaments, not circles, rigid rings or a black Sprite2D background.
	var clouds: Array[Dictionary] = [
		{"size": Vector2(880.0, 600.0), "angle": -0.40, "color": Color(0.23, 0.62, 0.96), "opacity": 0.40, "seed": 12.8, "style": 1.0},
		{"size": Vector2(720.0, 780.0), "angle": 0.92, "color": Color(0.63, 0.33, 0.90), "opacity": 0.31, "seed": 27.4, "style": 2.0}
	]
	for idx in range(clouds.size()):
		var info: Dictionary = clouds[idx]
		var nebula: ColorRect = ColorRect.new()
		nebula.name = "LivingArchive_NebulaCloud_%d" % idx
		nebula.size = info["size"]
		nebula.position = -nebula.size * 0.5
		nebula.pivot_offset = nebula.size * 0.5
		nebula.rotation = float(info["angle"])
		nebula.z_index = -3 + idx
		nebula.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var shader_mat: ShaderMaterial = ShaderMaterial.new()
		shader_mat.shader = ARCHIVE_NEBULA_SHADER
		shader_mat.set_shader_parameter("cloud_color", info["color"])
		shader_mat.set_shader_parameter("cloud_opacity", float(info["opacity"]))
		shader_mat.set_shader_parameter("cloud_seed", float(info["seed"]))
		shader_mat.set_shader_parameter("style", float(info["style"]))
		shader_mat.set_shader_parameter("glow_strength", 0.64)
		nebula.material = shader_mat
		_story_station_root.add_child(nebula)
		_archive_nebula.append(nebula)

func _add_last_gate_nebula() -> void:
	# Same flowing gas shader as SMC archive, with separate purple/blue sheets.
	# This is translucent plasma, not an opaque circular vignette.
	var layers: Array[Dictionary] = [
		{"size": Vector2(940.0, 680.0), "angle": -0.34, "color": Color(0.20, 0.42, 0.95), "opacity": 0.28, "seed": 63.7, "style": 2.0},
		{"size": Vector2(740.0, 940.0), "angle": 0.66, "color": Color(0.52, 0.26, 0.89), "opacity": 0.23, "seed": 41.3, "style": 1.0}
	]
	for idx in range(layers.size()):
		var info: Dictionary = layers[idx]
		var cloud: ColorRect = ColorRect.new()
		cloud.name = "LastGate_RealNebula_%d" % idx
		cloud.size = info["size"]
		cloud.position = -cloud.size * 0.5
		cloud.pivot_offset = cloud.size * 0.5
		cloud.rotation = float(info["angle"])
		cloud.z_index = -3 + idx
		cloud.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var material: ShaderMaterial = ShaderMaterial.new()
		material.shader = ARCHIVE_NEBULA_SHADER
		material.set_shader_parameter("cloud_color", info["color"])
		material.set_shader_parameter("cloud_opacity", float(info["opacity"]))
		material.set_shader_parameter("cloud_seed", float(info["seed"]))
		material.set_shader_parameter("style", float(info["style"]))
		material.set_shader_parameter("glow_strength", 0.58)
		cloud.material = material
		_story_station_root.add_child(cloud)
		_archive_nebula.append(cloud)

func _add_titan_nebula() -> void:
	# Bone-grey/cold blue gas with restrained violet lighting: two shader
	# layers already used by the Living Archive, NOT a dark circular halo.
	var layers: Array[Dictionary] = [
		{"size": Vector2(860.0, 610.0), "angle": -0.58,
		"color": Color(0.58, 0.69, 0.80), "opacity": 0.33, "seed": 31.4, "style": 1.0},
		{"size": Vector2(720.0, 790.0), "angle": 0.90,
		"color": Color(0.48, 0.44, 0.66), "opacity": 0.23, "seed": 45.2, "style": 2.0}
	]
	for idx in range(layers.size()):
		var info: Dictionary = layers[idx]
		var nebula: ColorRect = ColorRect.new()
		nebula.name = "TitanSkull_RealGas_%d" % idx
		nebula.size = info["size"]
		nebula.position = -nebula.size * 0.5
		nebula.pivot_offset = nebula.size * 0.5
		nebula.rotation = float(info["angle"])
		nebula.z_index = -3 + idx
		nebula.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var shader_mat: ShaderMaterial = ShaderMaterial.new()
		shader_mat.shader = ARCHIVE_NEBULA_SHADER
		shader_mat.set_shader_parameter("cloud_color", info["color"])
		shader_mat.set_shader_parameter("cloud_opacity", float(info["opacity"]))
		shader_mat.set_shader_parameter("cloud_seed", float(info["seed"]))
		shader_mat.set_shader_parameter("style", float(info["style"]))
		shader_mat.set_shader_parameter("glow_strength", 0.46)
		nebula.material = shader_mat
		_story_station_root.add_child(nebula)
		_archive_nebula.append(nebula)

func _system_nebula_palette(region_id: String) -> Array[Color]:
	match region_id:
		"mw":
			return [Color(0.22, 0.42, 0.68), Color(0.46, 0.35, 0.72), Color(0.69, 0.34, 0.55)]
		"lmc":
			return [Color(0.18, 0.72, 0.98), Color(0.59, 0.34, 0.94), Color(0.95, 0.38, 0.67)]
		"smc":
			return [Color(0.23, 0.60, 0.96), Color(0.62, 0.33, 0.90), Color(0.86, 0.52, 0.91)]
		"ngc6822":
			return [Color(0.58, 0.69, 0.80), Color(0.54, 0.47, 0.72), Color(0.78, 0.62, 0.52)]
		"m31":
			return [Color(0.34, 0.84, 1.0), Color(0.76, 0.35, 0.94), Color(1.0, 0.64, 0.39)]
		"m33":
			return [Color(0.20, 0.42, 0.95), Color(0.52, 0.26, 0.89), Color(0.85, 0.55, 0.98)]
		_:
			return [Color(0.24, 0.66, 1.0), Color(0.65, 0.38, 0.95), Color(0.95, 0.48, 0.76)]

func _add_system_background_nebulae(region_id: String) -> void:
	var palette: Array[Color] = _system_nebula_palette(region_id)
	var cloud_count: int = 16
	for i in range(cloud_count):
		var band: int = 0 if i < 6 else (1 if i < 12 else 2)
		var band_start: int = 0 if band == 0 else (6 if band == 1 else 12)
		var band_count: int = 6 if band == 0 else (6 if band == 1 else 4)
		var local_index: int = i - band_start
		var rng: RandomNumberGenerator = RandomNumberGenerator.new()
		rng.seed = ("miko_system_nebula:" + region_id + ":" + str(i)).hash()
		var radius_min: float = 440.0 if band == 0 else (1320.0 if band == 1 else 2380.0)
		var radius_max: float = 1240.0 if band == 0 else (2360.0 if band == 1 else 3360.0)
		var radius: float = lerpf(radius_min, radius_max, (float(local_index) + rng.randf_range(0.12, 0.88)) / float(maxi(1, band_count)))
		var bearing: float = (float(local_index) + rng.randf_range(-0.32, 0.32)) * TAU / float(maxi(1, band_count)) + float(band) * 0.37
		var info: Dictionary = {
			"offset": Vector2.from_angle(bearing) * radius,
			"size": Vector2(rng.randf_range(420.0, 760.0), rng.randf_range(280.0, 620.0)) * (1.0 if band == 0 else (1.12 if band == 1 else 1.20)),
			"angle": rng.randf_range(-1.05, 1.05),
			"color": palette[i % palette.size()],
			"opacity": rng.randf_range(0.22, 0.34) if band == 0 else (rng.randf_range(0.15, 0.25) if band == 1 else rng.randf_range(0.10, 0.18)),
			"seed": rng.randf_range(0.0, 90.0),
			"style": float(1 + (i % 2)),
			"spin": rng.randf_range(-0.0012, 0.0012),
			"drift": rng.randf_range(5.0, 13.0)
		}
		var cloud: ColorRect = ColorRect.new()
		cloud.name = "%s_SystemNebula_%02d" % [region_id.to_upper(), i]
		cloud.size = info["size"]
		cloud.color = Color.WHITE
		cloud.position = Vector2(info["offset"]) - cloud.size * 0.5
		cloud.pivot_offset = cloud.size * 0.5
		cloud.rotation = float(info["angle"])
		cloud.z_index = 1
		cloud.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var mat: ShaderMaterial = ShaderMaterial.new()
		mat.shader = CROSSROADS_NEBULA_SHADER
		mat.set_shader_parameter("cloud_color", info["color"])
		mat.set_shader_parameter("cloud_opacity", float(info["opacity"]))
		mat.set_shader_parameter("cloud_seed", float(info["seed"]))
		mat.set_shader_parameter("style", float(info["style"]))
		mat.set_shader_parameter("glow_strength", 0.56)
		cloud.material = mat
		add_child(cloud)
		_system_nebulae.append(cloud)
		_system_nebula_data.append(info)

func _build_titan_asteroid_ring() -> void:
	# Detached orbital debris, not painted on the skull. Motion follows the
	# story station because these are CHILDREN of its translated root.
	for i in range(28):
		var rock: Sprite2D = Sprite2D.new()
		rock.name = "TitanOrbitRock_%02d" % i
		rock.texture = TITAN_ASTEROID_TEXTURES[i % TITAN_ASTEROID_TEXTURES.size()]
		rock.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
		var diameter: float = 19.0 + float((i * 7) % 17)
		rock.scale = Vector2.ONE * (diameter / float(rock.texture.get_width()))
		rock.modulate = Color(0.72, 0.76, 0.85, 0.87)
		rock.z_index = -1 if i % 3 == 0 else 3
		_story_station_root.add_child(rock)
		_titan_ring_rocks.append({
			"node": rock, "angle": TAU * float(i) / 28.0 + 0.09 * sin(float(i)),
			"radius": 217.0 + float((i * 13) % 55),
			"speed": (0.013 + float(i % 5) * 0.0017) * (1.0 if i % 4 else -1.0),
			"spin": (-0.18 + float(i % 7) * 0.055),
			"tilt": 0.72 + 0.09 * sin(float(i) * 1.9)
		})

func _process(delta: float) -> void:
	_time += delta
	_update_positions()

func set_camera_address(sector: Vector2i, local_position: Vector2, camera_offset: Vector2) -> void:
	_camera_world = Vector2(sector) * WorldAddress.SECTOR_SIZE + local_position + camera_offset
	_update_positions()

func resize_view(view: Vector2) -> void:
	_view = view
	_update_positions()

func _display_orbit_radius(index: int, data: Dictionary) -> float:
	var atlas_radius: float = float(data.get("orbit", 245.0))
	return VISUAL_INNER_ORBIT + maxf(0.0, atlas_radius - 245.0) * VISUAL_ORBIT_SCALE

func _world_for(index: int, data: Dictionary, phase: float) -> Vector2:
	var radius: float = _display_orbit_radius(index, data)
	return Vector2.from_angle(phase) * radius

func _update_positions() -> void:
	var half: Vector2 = _view * 0.5
	if _star_orb != null:
		_star_orb.position = half - _camera_world
	for i in range(_system_nebulae.size()):
		var nebula: ColorRect = _system_nebulae[i]
		var info: Dictionary = _system_nebula_data[i]
		var offset: Vector2 = info["offset"]
		var seed: float = float(info["seed"])
		var drift: float = float(info["drift"])
		var motion: Vector2 = Vector2(sin(_time * 0.043 + seed), cos(_time * 0.036 + seed * 1.7)) * drift
		var screen_center: Vector2 = half - _camera_world + offset + motion
		nebula.position = screen_center - nebula.size * 0.5
		nebula.rotation = float(info["angle"]) + _time * float(info["spin"])
		nebula.visible = absf(screen_center.x - half.x) < half.x + nebula.size.x * 0.72 and absf(screen_center.y - half.y) < half.y + nebula.size.y * 0.72
	for i in range(_planets.size()):
		var body: Dictionary = _planets[i]
		var data: Dictionary = body["data"]
		var phase: float = float(body["phase"]) + _time * TAU / float(data.get("period", 350.0))
		var world: Vector2 = _world_for(int(body.get("index", i)), data, phase)
		(body["node"] as Node2D).position = world - _camera_world + half
		body["world"] = world
		_planets[i] = body
	for i in range(_moons.size()):
		var moon: Dictionary = _moons[i]
		var planet_index: int = int(moon["planet_index"])
		var home: Vector2 = _planets[planet_index]["world"]
		var angle: float = float(moon["phase"]) + _time * float(moon["speed"])
		var position: Vector2 = home + Vector2.from_angle(angle) * float(moon["radius"])
		var moon_node: Node2D = moon["node"] as Node2D
		var screen_position: Vector2 = position - _camera_world + half
		moon_node.position = screen_position
		moon_node.visible = absf(screen_position.x - half.x) < half.x + 100.0 and absf(screen_position.y - half.y) < half.y + 100.0
		if moon_node.visible:
			var sun_vector: Vector2 = (-position).normalized()
			moon_node.call("set_light_direction", Vector3(sun_vector.x * 0.7, sun_vector.y * 0.7, 0.72))
	if _story_station_root != null:
		_story_station_root.position = _station_world() - _camera_world + half
		var station_region: String = str(_region.get("id", ""))
		# Distinct slow spin rates; sprite and gravity-gas flow are independent.
		match station_region:
			"lmc":
				_station_sprite.rotation = _time * 0.022
				if _tarantula_thrusters != null:
					_tarantula_thrusters.call("update_time", _time)
			"smc":
				_station_sprite.rotation = -_time * 0.015
				_station_sprite.scale = Vector2.ONE * (0.30 * (1.0 + 0.012 * sin(_time * 0.65)))
				for i in range(_archive_nebula.size()):
					var nebula: ColorRect = _archive_nebula[i]
					nebula.rotation = (-0.40 + _time * 0.003 if i == 0 else 0.92 - _time * 0.0025)
					nebula.modulate.a = 0.85 + 0.10 * sin(_time * 0.32 + float(i) * 2.1)
			"ngc6822":
				_station_sprite.rotation = _time * 0.009
				for i in range(_archive_nebula.size()):
					var nebula: ColorRect = _archive_nebula[i]
					nebula.rotation = (-0.58 + _time * 0.002 if i == 0 else 0.90 - _time * 0.0028)
				for rock_data in _titan_ring_rocks:
					var rock: Sprite2D = rock_data["node"]
					var angle: float = float(rock_data["angle"]) + _time * float(rock_data["speed"])
					var radius: float = float(rock_data["radius"])
					rock.position = Vector2(cos(angle) * radius, sin(angle) * radius * float(rock_data["tilt"]))
					rock.rotation = _time * float(rock_data["spin"])
			"m31":
				_station_sprite.rotation = -_time * 0.013
			"m33":
				_station_sprite.rotation = _time * 0.014
				for i in range(_archive_nebula.size()):
					var nebula: ColorRect = _archive_nebula[i]
					nebula.rotation = (-0.34 + _time * 0.0038 if i == 0 else 0.66 - _time * 0.0026)
					nebula.modulate.a = 0.82 + 0.14 * sin(_time * 0.35 + float(i) * 1.5)
		if _story_fx != null:
			_story_fx.call("update_time", _time)
	if _crossroads_world != null:
		var half_cross: Vector2 = _view * 0.5
		_crossroads_world.position = half_cross - _camera_world
		_crossroads_world.rotation = _time * 0.024
		_crossroads_world.call("set_storm_state", "surge" if sin(_time * 0.34) > 0.18 else "communicating")
		_crossroads_world.call("set_mood", "curious" if sin(_time * 0.19) > 0.0 else "listening")
		_crossroads_world.call("react_to_voice", 0.46 + 0.34 * (0.5 + 0.5 * sin(_time * 1.24)))
		var pulse_index: int = int(floor(_time / 2.1))
		if pulse_index != _crossroads_pulse_index:
			_crossroads_pulse_index = pulse_index
			_crossroads_world.call("trigger_storm", Vector2.from_angle(_time * 0.82), 0.94)
		var flash_index: int = int(floor(_time / 1.35))
		if flash_index != _crossroads_storm_flash_index:
			_crossroads_storm_flash_index = flash_index
			_crossroads_world.call("trigger_storm", Vector2.from_angle(_time * 1.41 + PI * 0.33), 1.0)
		for i in range(_crossroads_nebulae.size()):
			var nebula: ColorRect = _crossroads_nebulae[i]
			var info: Dictionary = _crossroads_nebula_data[i]
			var offset: Vector2 = info["offset"]
			var seed: float = float(info["seed"])
			var drift: float = float(info["drift"])
			var motion: Vector2 = Vector2(sin(_time * 0.057 + seed), cos(_time * 0.046 + seed * 1.8)) * drift
			var screen_center: Vector2 = half_cross - _camera_world + offset + motion
			nebula.position = screen_center - nebula.size * 0.5
			nebula.rotation = float(info["angle"]) + _time * float(info["spin"])
			# Culling controls GPU load on mobile, without moving clouds with the HUD.
			nebula.visible = absf(screen_center.x - half_cross.x) < half_cross.x + nebula.size.x * 0.70 and absf(screen_center.y - half_cross.y) < half_cross.y + nebula.size.y * 0.70
	queue_redraw()

func _station_world() -> Vector2:
	var region_id: String = str(_region.get("id", ""))
	if not STORY_STATION_ANCHORS.has(region_id):
		return Vector2.ZERO
	var anchor: Vector2 = STORY_STATION_ANCHORS[region_id]
	var amplitude: float = float(STORY_ORBIT_AMPLITUDE[region_id])
	var seconds: float = float(STORY_ORBIT_SECONDS[region_id])
	var phase: float = float(STORY_ORBIT_PHASE[region_id]) + _time * TAU / seconds
	return anchor + Vector2(cos(phase), sin(phase) * 0.73) * amplitude

func _station_velocity() -> Vector2:
	var region_id: String = str(_region.get("id", ""))
	if not STORY_STATION_ANCHORS.has(region_id):
		return Vector2.ZERO
	var amplitude: float = float(STORY_ORBIT_AMPLITUDE[region_id])
	var seconds: float = float(STORY_ORBIT_SECONDS[region_id])
	var omega: float = TAU / seconds
	var phase: float = float(STORY_ORBIT_PHASE[region_id]) + _time * omega
	return Vector2(-sin(phase), cos(phase) * 0.73) * amplitude * omega

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
		var radius: float = 195.0 if ["lmc", "smc"].has(str(_region.get("id", ""))) else 145.0
		return {"valid": true, "world": _station_world(), "velocity": _station_velocity(), "arrival_radius": radius}
	return {"valid": false}

func get_navigation_bodies() -> Array[Dictionary]:
	var bodies: Array[Dictionary] = []
	if str(_region.get("id", "")) == "crossroads":
		bodies.append({"name": "LivingWorld", "world": Vector2.ZERO, "color": Color(0.76, 0.90, 1.0), "orbit": 0.0, "kind": "planet", "planet_id": "crossroads_core", "inhabited": false})
		return bodies
	bodies.append({"name": "Sun", "world": Vector2.ZERO, "color": _sun_color, "orbit": 0.0})
	for body in _planets:
		var data: Dictionary = body["data"]
		var p_color: Color = Color.html(str(data.get("palette", ["#82aadd"])[0]))
		bodies.append({"name": str(data["name_en"]), "world": body["world"], "color": p_color, "orbit": _display_orbit_radius(int(body.get("index", 0)), data), "kind": "planet", "planet_id": str(data.get("id", "")), "inhabited": bool(data.get("inhabited", false))})
	if _station_sprite != null:
		var story_station: Dictionary = _region.get("station", {})
		bodies.append({"name": str(story_station.get("name_en", "Station")),
			"station_id": str(story_station.get("id", "")), "kind": "station",
			"world": _station_world(), "color": Color(0.59, 0.89, 1.0), "orbit": 0.0})
	return bodies

func _planet_index_by_id(target_id: String) -> int:
	for i in range(_planets.size()):
		var body: Dictionary = _planets[i]
		var data: Dictionary = body["data"]
		if str(data.get("id", "")) == target_id:
			return int(body.get("index", i))
	return 0

func _library_for_region(region_id: String) -> Array[PackedScene]:
	match region_id:
		"lmc":
			return LMC_SCENES
		"smc":
			return SMC_SCENES
		"ngc6822":
			return NGC6822_SCENES
		"m31":
			return M31_SCENES
		"m33":
			return M33_SCENES
		_:
			return []

func _planet_supports_civil_station(data: Dictionary) -> bool:
	if bool(data.get("story", false)):
		return true
	var unique_text: String = str(data.get("unique", "")).to_lower()
	return unique_text.contains("город") or unique_text.contains("city") or unique_text.contains("лаборатор")

func _choose_system_ring_stations(region: Dictionary) -> Dictionary:
	# Pseudorandom but reproducible: one deterministic seed for each system,
	# so selecting a system again NEVER reshuffles or multiplies its stations.
	var region_id: String = str(region.get("id", ""))
	var candidates: Array[int] = []
	var planets: Array = region.get("planets", [])
	for i in range(planets.size()):
		var data: Dictionary = planets[i]
		if _planet_supports_civil_station(data):
			candidates.append(i)
	if candidates.is_empty():
		return {}
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = ("MIKO_system_ring_layout_v32_1:" + region_id).hash()
	# Fisher-Yates using only this RNG; no global randomness or visit-time dependency.
	for i in range(candidates.size() - 1, 0, -1):
		var j: int = rng.randi_range(0, i)
		var swap: int = candidates[i]
		candidates[i] = candidates[j]
		candidates[j] = swap
	var available_styles: Array[int] = [0, 1, 2, 3]
	for i in range(available_styles.size() - 1, 0, -1):
		var j: int = rng.randi_range(0, i)
		var swap: int = available_styles[i]
		available_styles[i] = available_styles[j]
		available_styles[j] = swap
	var desired: int = mini(int(SYSTEM_RING_COUNTS.get(region_id, 2)), candidates.size())
	var assigned: Dictionary = {}
	for n in range(desired):
		# Styles are unique inside each system, and the chosen planets differ.
		assigned[candidates[n]] = {
			"variant": available_styles[n],
			"tilt_deg": rng.randf_range(-25.0, 25.0),
			"size_factor": rng.randf_range(0.98, 1.08)
		}
	return assigned


func _build_planet_orbital_ring(planet_root: Node2D, data: Dictionary, diameter: float, assignment: Dictionary) -> void:
	# The reusable station scene already contains BACK and FRONT graphics.
	# Parent alongside the rotating globe so the planet continues to rotate
	# beneath the ring; no extra rings are stacked on this same planet.
	var style_id: int = int(assignment.get("variant", 0))
	var ring: Node2D = STATION_SHELL_VARIANTS[style_id].instantiate() as Node2D
	if ring == null:
		push_warning("Unable to instantiate ring around " + str(data.get("id", "?")))
		return
	ring.name = "OrbitalRing_" + str(data.get("id", "")) + "_Type" + str(style_id + 1)
	ring.scale = Vector2.ONE * (diameter / STATION_ART_PLANET_DIAMETER) * float(assignment.get("size_factor", 1.0))
	ring.rotation = deg_to_rad(float(assignment.get("tilt_deg", 0.0)))
	planet_root.add_child(ring)

func _draw() -> void:
	var center: Vector2 = _view * 0.5 - _camera_world
	if str(_region.get("id", "")) == "crossroads":
		return
	if center.distance_to(_view * 0.5) < 3500.0:
		draw_circle(center, 84.0, Color(_sun_color.r, _sun_color.g, _sun_color.b, 0.06))
		# The real star sprite uses a transparent, soft corona. No solid disc here.
	for body in _planets:
		var data: Dictionary = body["data"]
		var radius: float = _display_orbit_radius(int(body.get("index", 0)), data)
		if center.distance_to(_view * 0.5) < radius + maxf(_view.x, _view.y) + 150.0:
			draw_arc(center, radius, 0.0, TAU, 120, Color(0.26, 0.45, 0.62, 0.14), 1.0, true)
