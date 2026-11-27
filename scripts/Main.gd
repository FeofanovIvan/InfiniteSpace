extends Node2D
# MIKA_FUEL_EMPTY_SIMULATOR_V122
const EmptyFuelSimulatorCardScript: Script = preload("res://addons/mika_fuel_empty_simulator/EmptyFuelSimulatorCard.gd")
# MIKA_BUBBLE_CARE_MAIN_HUD_V8_5_0
# MIKA_BUBBLE_BALL_PLANET_V8_5_1
# MIKA_BUBBLE_BOTH_CLICKS_V8_5_1_3
## Ship navigation address and camera inspection are independent.
## Touch-drag empty space to detach camera; return smoothly when flight resumes.
## Distant starfield, subtle events and mini-map track the correct view.

const StarfieldScene = preload("res://scripts/Starfield.gd")
const ShipScene = preload("res://scripts/Ship.gd")
const NpcTrafficScene = preload("res://scripts/NpcTraffic.gd")
const ForeignTrafficScene = preload("res://scripts/ForeignTraffic.gd")
const JoystickScene = preload("res://scripts/Joystick.gd")
const ActionScene = preload("res://scripts/ActionButton.gd")
const LandingPreviewScene = preload("res://scripts/LandingPreview.gd")
const MiniMapScene = preload("res://scripts/MiniMap.gd")
const WorldAddress = preload("res://scripts/WorldPosition.gd")
const DiagnosticsClass = preload("res://scripts/Diagnostics.gd")
const DistantEventsScene = preload("res://scripts/DistantEvents.gd")
const FarPlasmaScene = preload("res://scripts/FarPlasma.gd")
const CosmicRegionScene = preload("res://scripts/CosmicRegion.gd")
const BlackHoleScene: PackedScene = preload("res://blackhole2d/black_hole_2d.tscn")
const SolarSystemScene = preload("res://scripts/AtlasSystem.gd")
const NavigationMenuScene = preload("res://scripts/NavigationMenu.gd")
const AutoStopScene = preload("res://scripts/AutoStopButton.gd")
const ResourceHudScene = preload("res://scripts/RightStatusHUD.gd")
const AsteroidFieldScene = preload("res://scripts/AsteroidField.gd")
const GalacticMapScene = preload("res://scripts/GalacticMap.gd")
const PlayerJumpFXScene = preload("res://scripts/PlayerJumpFX.gd")
const NpcJumpVisual = preload("res://scripts/NpcJumpVisual.gd")
const MikoMainMenuScene = preload("res://simulator_ui/menu/mika_free_world_more_games_v1.gd")
const ComicPrologueScene = preload("res://scripts/ComicPrologue.gd")
const StoryProgress: Script = preload("res://scripts/StoryProgress.gd")
const StorySubscriptionGate: Script = preload("res://scripts/StorySubscriptionGate.gd")
const StoryArcadeFlight: Script = preload("res://scripts/StoryArcadeFlight.gd")
const StoryLandingMotion: Script = preload("res://scripts/LandingMotion.gd")
const HyperjumpMotion = preload("res://scripts/HyperjumpMotion.gd")
const StoryBarnardEscortScene: Script = preload("res://story/barnard/StoryBarnardEscort.gd")
const AdaptiveMusicScene = preload("res://scripts/AdaptiveMusic.gd")

const V104_CROSSROADS_UI: Script = preload("res://planet_hub/scripts/crossroads_dialog_v104.gd")
var _v104_crossroads_dialog: Control
# InfiniteSpace develop: persisted Story/Free World boot and Living World conversation
const MAX_SPEED: float = 890.0
const THRUST: float = 580.0
const RELEASE_DECELERATION: float = 3200.0
const AUTO_CRUISE_SPEED: float = 720.0
const AUTO_STEERING_ACCEL: float = 1100.0
const AUTO_BRAKE_ACCEL: float = 1060.0
# Distance tolerance is only used to snap the LAST few pixels to the
# exact 2500-unit rim. Never brake 82 units inside the boundary: a tiny
# floating-point remainder previously stalled the ship forever.
const WARP_EDGE_SNAP_DISTANCE: float = 12.0
const STOP_EPSILON: float = 0.25
# Development only. Turn off before publishing: the black hole remains in
# the world, but disappears from the mini-map and the B test shortcut.
const DEBUG_SHOW_BLACK_HOLE_ON_MAP: bool = true
const REPORT_INTERVAL: float = 25.0
# Cinematic return: smooth acceleration/deceleration; duration adjusts to distance.
const CAMERA_RETURN_MIN_DURATION: float = 0.72
const CAMERA_RETURN_MAX_DURATION: float = 1.40
const CAMERA_RETURN_DISTANCE_SCALE: float = 1400.0
const SYSTEM_ROAM_EXTRA_RADIUS: float = 260.0
const SYSTEM_ROAM_SOFT_MARGIN: float = 90.0
# v38: ONLY the two existing circular controls are 10% larger than v36.
const CONTROL_SCALE_MULTIPLIER: float = 1.10
# v43: uniformly grow the EXISTING upper-right destination/fuel/buttons rail
# by another 20% from v42. The gaps stay 12 screen pixels, not 20% larger.
const UPPER_RIGHT_UI_GROWTH: float = 1.20
# Landing is offered only in approach range, not when a distant planet happens to be on screen.
const LANDING_APPROACH_MARGIN: float = 140.0
# StoryArcadeFlight owns the ejection curve. Main owns only world rendering.


var velocity: Vector2 = Vector2.ZERO
var current_input: Vector2 = Vector2.ZERO
var starfield
var ship
var npc_traffic
var foreign_traffic
var asteroid_field
var joystick
var action_button
var landing_preview
var _planet_hub: Control
var _representative_dialog: Control
var _planet_landing_active: bool = false
var _landing_target_id: String = ""
var _landing_target_name: String = ""
var mini_map
var distant_events
var far_plasma
var cosmic_region
var black_hole: Node2D
var solar_system
var goal_picker
var auto_stop_button
var status_hud
var galactic_map
var _warp_overlay
var _warp_active: bool = false
var _warp_phase: String = "idle"
var _warp_time: float = 0.0
var _warp_destination: String = ""
var _warp_direction: Vector2 = Vector2.RIGHT
var _warp_exit_world: Vector2 = Vector2.ZERO
var _warp_velocity: Vector2 = Vector2.ZERO
var _warp_switched: bool = false
var main_menu
var _bubble_popup: Button
var _bubble_attention_pending: bool = false
var _bubble_access_available: bool = false
var _gameplay_hud: Control
var _story_navigation_blocker: ColorRect
var _story_navigation_picker_restore_index: int = -1
var _comic_prologue
var _intro_comic_playing: bool = false
var _intro_space_flying: bool = false
var _intro_time: float = 0.0
var _story_phase: String = "inactive"
var _story_simulator_required: bool = false
var _story_black_hole_emphasized: bool = false
var _story_mars_asteroid_elapsed: float = 0.0
var _story_mars_hand_pulse: Tween
var _barnard_pirate_escort: Node2D
var _barnard_escort_time: float = 0.0
var _barnard_escort_duration: float = 9.0
var _barnard_escort_start: Vector2 = Vector2.ZERO
var _barnard_escort_end: Vector2 = Vector2.ZERO
var _barnard_escort_speed: float = 0.0
var _barnard_landing_stage: String = "idle"
var _barnard_landing_time: float = 0.0
var _barnard_landing_npcs_docked: bool = false
# Chapter 5: cinematic, player-disabled movement through the real M31 system.
const M31_STORY_PLANET_ID: String = "m31_p03" # Phasis: inhabited dark lava world.
# MIKA_CH06_NATIVE_ROUTE_V1
const CH06_LENTIS: String = "m33_p04"
const CH06_GATE: String = "st_m33"
# MIKA_CH06_CROSSROADS_GATE_V1
const CH06_GATE_BEFORE_REBUS: Array[String] = ["p64_cockpit", "p64_talk", "p64_worlds"]
const CH06_GATE_AFTER_REBUS: Array[String] = ["p64_portal"]
# MIKA_CH07_ENDING_CHOICE_V1
const CH07_PLANET: String = "crossroads_core"
const CH07_PANELS: Array[String] = ["p71_ship", "p71_cabin", "p71_flight", "p71_mika_points", "p71_planet", "p71_thought", "p72_conversation", "p72_history", "p72_magnetic", "p72_worlds", "p72_neurons", "p72_mika", "p73_guide", "p73_flower", "p73_evolution", "p73_storm", "p73_mika_form", "p73_tunnel", "p74_planet_change", "p74_mika_future", "p74_routes", "p74_gate", "p74_living_world", "p74_doors"]
var _ch07_choice_layer: CanvasLayer
var _ch08_draw_layer: CanvasLayer
var _ch08_completion_layer: CanvasLayer
const CH08_ENDING_TWO_PANELS: Array[String] = ["p82_approach", "p82_portal", "p82_entry", "p82_change", "p82_transformation", "p82_beyond", "p82_new_space"]
const CH08_ENDING_ONE_PANELS: Array[String] = ["p81_palace", "p81_mika", "p81_bubble", "p81_friends", "p81_lizard", "p81_reply"]
var _ch06_rebus_layer: CanvasLayer
const CH06_INTRO: Array[String] = ["p61_cabin", "p61_tunnel"]
const CH06_BEFORE_MATH: Array[String] = ["p61_planet", "p61_city", "p61_meeting", "p61_chair", "p62_ancient", "p62_blueprint", "p62_station", "p62_burst", "p62_hole", "p62_mika", "p62_clocks"]
const CH06_AFTER_MATH: Array[String] = ["p62_galaxy", "p62_eclipse", "p62_planets", "p62_meteor", "p63_network", "p63_civilizations", "p63_storm", "p63_gate", "p63_hole", "p64_council", "p64_mika", "p64_route", "p64_wake"]
# Show the red-planet insert ONLY after a real physical approach. The last
# hundreds of world units are flown in the native scene, before native landing.
const M31_NEAR_PLANET_REVEAL_DISTANCE: float = 840.0
# v5.0.2: capture the native landing boundary with a few pixels of
# tolerance. Otherwise the moving planet + a clamped final step can keep the
# ship hovering infinitesimally outside the exact radius forever.
const M31_LANDING_CAPTURE_MARGIN: float = 12.0
var _m31_flight_time: float = 0.0
var _m31_flight_velocity: Vector2 = Vector2.ZERO
var _m31_drift_heading: float = 0.0
# v57: tuneable normal-flight fuel. Hyperjumps and story flights remain free.
const FUEL_CAPACITY: float = 50.0
const FUEL_MAX_DRAIN_PER_SECOND: float = 1.8
const STORY_MARS_LAUNCH_FUEL: float = 12.0
const STORY_MARS_COLLISION_FUEL: float = 10.0
const STORY_MARS_AUTOPILOT_PHASES: Array[String] = ["mars_navigation_selected", "mars_asteroid_approach", "mars_navigation_resume"]
const INITIAL_CRYSTALS: int = 50
const INITIAL_FUEL_SEGMENTS: int = 7
var _fuel_units: float = FUEL_CAPACITY
var _autopilot_target: String = ""
var _autopilot_active: bool = false
var _camera_offset: Vector2 = Vector2.ZERO
var _camera_following: bool = true
var _camera_returning: bool = false
var _map_camera_flying: bool = false
var _map_camera_target_world: Vector2 = Vector2.ZERO
var _map_camera_start_world: Vector2 = Vector2.ZERO
var _map_camera_elapsed: float = 0.0
var _map_camera_duration: float = 0.9
var _return_start_offset: Vector2 = Vector2.ZERO
var _return_ship_travel: Vector2 = Vector2.ZERO
var _return_elapsed: float = 0.0
var _return_duration: float = CAMERA_RETURN_MIN_DURATION
var _return_reason: String = ""
var _look_touch: int = -1
var _look_mouse_down: bool = false
var _look_dragged: bool = false
var navigator = WorldAddress.new()
var diagnostics = DiagnosticsClass.new()
var _ship_heading: float = 0.0
var _report_timer: float = 0.0
var _adaptive_music: AdaptiveMusic


func _ready() -> void:
	_adaptive_music = AdaptiveMusicScene.new() as AdaptiveMusic
	_adaptive_music.name = "AdaptiveExplorationMusic"
	add_child(_adaptive_music)
	# Launch next to Earth, not at the origin inside the Sun.
	navigator.advance(SolarSystemScene.INITIAL_SHIP_POSITION)
	diagnostics.start()
	far_plasma = FarPlasmaScene.new()
	far_plasma.name = "DistantProceduralPlasma"
	add_child(far_plasma)
	# Far Milky Way region draws below the point-star layer.
	cosmic_region = CosmicRegionScene.new()
	cosmic_region.name = "MilkyWay_OneAnchoredRegion"
	add_child(cosmic_region)
	starfield = StarfieldScene.new()
	starfield.name = "ProceduralInfiniteStarfield"
	add_child(starfield)
	starfield.advance(SolarSystemScene.INITIAL_SHIP_POSITION)

	solar_system = SolarSystemScene.new()
	solar_system.name = "SunAndOrbitingEarth"
	add_child(solar_system)

	distant_events = DistantEventsScene.new()
	distant_events.name = "SmallDistantPhenomena"
	add_child(distant_events)

	# The supplied MIKO black-hole module samples the already drawn sky.
	# It must render after stars and gas, but before the spaceship/UI.
	black_hole = BlackHoleScene.instantiate() as Node2D
	black_hole.name = "BlackHole_SecretLocation_MIKO"
	black_hole.set("diameter_px", 335.0)
	black_hole.set("rotation_speed", 0.14)
	black_hole.set("lensing_strength", 0.18)
	add_child(black_hole)

	# NPC traffic has its own world coordinates; not parented to the player or camera.
	npc_traffic = NpcTrafficScene.new()
	npc_traffic.name = "SolarNPCFleet_TenRoles"
	# The ring overlays include z=+1 foreground textures; NPCs must fly OVER them.
	npc_traffic.z_index = 10
	npc_traffic.configure(solar_system)
	add_child(npc_traffic)
	npc_traffic.hyperjump_started.connect(_on_npc_hyperjump_started)
	npc_traffic.landing_completed.connect(_on_npc_landing_completed)
	npc_traffic.takeoff_started.connect(_on_npc_takeoff_started)
	foreign_traffic = ForeignTrafficScene.new()
	foreign_traffic.name = "SMC_NativeFleet_FiveShipClasses"
	foreign_traffic.z_index = 10
	foreign_traffic.configure(solar_system)
	add_child(foreign_traffic)
	foreign_traffic.set_region("mw")

	asteroid_field = AsteroidFieldScene.new()
	asteroid_field.name = "MikoAsteroidsAndCrystals"
	asteroid_field.z_index = 11
	asteroid_field.configure(solar_system, npc_traffic)
	add_child(asteroid_field)
	asteroid_field.asteroid_impact.connect(_on_asteroid_impact)
	asteroid_field.fuel_collected.connect(_on_fuel_collected)
	ship = ShipScene.new()
	ship.name = "FixedScreenShip"
	ship.z_index = 15
	add_child(ship)

	_build_controls()
	mini_map.set_ship_location(navigator.sector, navigator.local, _ship_heading)
	mini_map.set_camera_offset(_camera_offset)
	# Temporary development beacon: later set this bool to false.
	mini_map.set_debug_landmark(CosmicRegionScene.BLACK_HOLE_WORLD, DEBUG_SHOW_BLACK_HOLE_ON_MAP)
	cosmic_region.set_camera_address(navigator.sector, navigator.local, _camera_offset)
	far_plasma.set_camera_address(navigator.sector, navigator.local, _camera_offset)
	solar_system.set_camera_address(navigator.sector, navigator.local, _camera_offset)
	npc_traffic.set_camera_address(navigator.sector, navigator.local, _camera_offset)
	foreign_traffic.set_camera_address(navigator.sector, navigator.local, _camera_offset)
	asteroid_field.set_camera_address(navigator.sector, navigator.local, _camera_offset)
	asteroid_field.set_ship_world(Vector2(navigator.sector) * WorldAddress.SECTOR_SIZE + navigator.local)
	_update_black_hole_position()
	mini_map.set_solar_bodies(solar_system.get_navigation_bodies(), solar_system.OUTER_ORBIT_RADIUS)
	goal_picker.set_region_destinations(solar_system.current_id, solar_system.get_map_destinations(), solar_system.get_system(solar_system.current_id).get("station", null))
	get_viewport().size_changed.connect(_layout)
	_layout()
	diagnostics.write("map_ready", {"mode": "north_up", "follow_ship": true})
	diagnostics.write("solar_system_ready", {"earth_orbit_radius": solar_system.ORBIT_RADIUS, "earth_period_s": solar_system.ORBIT_PERIOD_SECONDS, "planet_count": 8, "ship_spawn": navigator.as_dictionary()})
	diagnostics.write("cosmic_region_ready", {"black_hole_world": {"x": CosmicRegionScene.BLACK_HOLE_WORLD.x, "y": CosmicRegionScene.BLACK_HOLE_WORLD.y}, "galaxy_center": {"x": CosmicRegionScene.GALAXY_CENTER.x, "y": CosmicRegionScene.GALAXY_CENTER.y}, "debug_map_marker": DEBUG_SHOW_BLACK_HOLE_ON_MAP})
	diagnostics.write("far_plasma_ready", {"max_active": 5, "initial_visible": far_plasma.active_count(), "method": "bounded_fragment_shader"})
	_v104_free_world_boot()


func _physics_process(delta: float) -> void:
	# The reminder counts only in ordinary flight; other screens pause it.
	if status_hud != null:
		status_hud.call("set_bubble_timer_active", _bubble_access_available and _bubble_flight_available() and _story_phase != "station_map_lmc")
	_refresh_bubble_popup()

	if _planet_landing_active:
		return
	if _warp_active:
		_advance_warp(delta)
		return
	if _intro_comic_playing:
		return
	if _intro_space_flying:
		_advance_story_flight(delta)
		return
	if _story_phase in ["m31_lost_drift", "m31_gravity_pull", "m31_final_approach"]:
		_story_advance_andromeda_cinematic(delta)
		return
	if _story_phase == "m31_gravity_landing":
		velocity = Vector2.ZERO
		current_input = Vector2.ZERO
		return
	if _story_phase == "barnard_pirate_escort":
		_story_advance_barnard_escort(delta)
		return
	if _story_phase == "barnard_pirate_landing":
		_story_advance_barnard_landing(delta)
		return
	if _story_phase == "barnard_pirate_intercept":
		# This is the REAL game space, but all piloting is temporarily scripted.
		velocity = Vector2.ZERO
		current_input = Vector2.ZERO
		return
	if _story_phase == "station_map_lmc":
		# This is a guided map lesson in the real ship world: no acceleration,
		# asteroid hand, navigation, or camera drag until LMC is selected.
		velocity = Vector2.ZERO
		current_input = Vector2.ZERO
		ship.throttle = 0.0
		if is_instance_valid(_bubble_popup):
			_bubble_popup.hide()
		return
	if _story_phase == "await_simulator_card":
		velocity = Vector2.ZERO
		_story_move_to(StoryArcadeFlight.earth_hold_position(solar_system.earth_world_position()))
		return
	if ["mars_navigation_selected", "mars_asteroid_approach"].has(_story_phase):
		_story_update_mars_asteroid(delta)
	if _story_navigation_guide_active() and (not STORY_MARS_AUTOPILOT_PHASES.has(_story_phase) or not _autopilot_active):
		# Keep the entire real-world scene alive; only manual ship movement stops.
		velocity = Vector2.ZERO
		current_input = Vector2.ZERO
		ship.throttle = 0.0
		return
	var keyboard := Vector2.ZERO
	if Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT):
		keyboard.x -= 1.0
	if Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT):
		keyboard.x += 1.0
	if Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP):
		keyboard.y -= 1.0
	if Input.is_key_pressed(KEY_S) or Input.is_key_pressed(KEY_DOWN):
		keyboard.y += 1.0

	var steer: Vector2 = current_input
	if keyboard.length_squared() > 0.0:
		steer = keyboard.normalized()

	if _autopilot_active:
		# The physical joystick is hidden for the ENTIRE autopilot flight.
		# Stop square cancels the route; desktop Space provides the same action.
		if not STORY_MARS_AUTOPILOT_PHASES.has(_story_phase) and Input.is_key_pressed(KEY_SPACE):
			_stop_autopilot("keyboard_stop")
		else:
			_update_autopilot(delta)
	else:
		if steer.length_squared() > 0.005:
			if not _camera_following and not _camera_returning:
				_start_camera_return("flight_input")
			velocity += steer.limit_length(1.0) * THRUST * delta
			velocity = velocity.limit_length(MAX_SPEED)
		else:
			velocity = velocity.move_toward(Vector2.ZERO, RELEASE_DECELERATION * delta)
			if velocity.length_squared() < STOP_EPSILON * STOP_EPSILON:
				velocity = Vector2.ZERO
		# Hidden desktop shortcut retained from v0.2.
		if Input.is_key_pressed(KEY_SPACE):
			velocity = Vector2.ZERO

	# Only normal flight consumes fuel; storyline flights and hyperjumps
	# return earlier from this process, so they remain free.
	if velocity.length_squared() > 1.0 and _fuel_units > 0.0 and not STORY_MARS_AUTOPILOT_PHASES.has(_story_phase):
		_fuel_units = maxf(0.0, _fuel_units - FUEL_MAX_DRAIN_PER_SECOND * clampf(velocity.length() / MAX_SPEED, 0.0, 1.0) * delta)
		_refresh_fuel_hud()
	# The scripted Earth→Mars navigation lesson must not fail for lack of fuel.
	if _fuel_units <= 0.0 and not STORY_MARS_AUTOPILOT_PHASES.has(_story_phase):
		if _autopilot_active:
			_stop_autopilot("fuel_empty")
		velocity = Vector2.ZERO
		# The empty tank stops translation, not the joystick's orientation.
		if steer.length_squared() > 0.005:
			_ship_heading = lerp_angle(_ship_heading, steer.angle() + PI * 0.5, minf(1.0, delta * 3.5))
			ship.rotation = _ship_heading
	# Ship world position, camera world position and visual parallax are distinct.
	# Even mid-return, the ship continues its usual physics without interruption.
	var previous_offset: Vector2 = _camera_offset
	var requested_displacement: Vector2 = velocity * delta
	var displacement: Vector2 = requested_displacement
	var visual_star_displacement: Vector2 = requested_displacement
	if requested_displacement.length_squared() > 0.000001:
		var movement: Dictionary = _constrain_free_flight_displacement(requested_displacement)
		displacement = movement.get("world", requested_displacement)
		visual_star_displacement = movement.get("visual", requested_displacement)
		if displacement.length_squared() > 0.000001:
			navigator.advance(displacement)
		if visual_star_displacement.length_squared() > 0.000001:
			starfield.advance(visual_star_displacement)
		var desired: float = velocity.angle() + PI * 0.5
		_ship_heading = lerp_angle(_ship_heading, desired, minf(1.0, delta * 3.5))
		ship.rotation = _ship_heading

	if _camera_returning:
		_update_camera_return(delta, displacement)
	elif _map_camera_flying:
		_update_map_camera_flight(delta)
	elif not _camera_following:
		# When inspecting without a return, the camera stays in world space.
		_camera_offset -= displacement

	if _camera_offset != previous_offset:
		starfield.set_camera_look(_camera_offset)
	# Camera motion = ship motion + change in its relative offset.
	# This keeps the comets and twinkling stars in sync during the fly-back.
	var camera_motion: Vector2 = displacement + _camera_offset - previous_offset
	if camera_motion.length_squared() > 0.000001:
		distant_events.advance_camera(camera_motion)

	far_plasma.set_camera_address(navigator.sector, navigator.local, _camera_offset)
	cosmic_region.set_camera_address(navigator.sector, navigator.local, _camera_offset)
	solar_system.set_camera_address(navigator.sector, navigator.local, _camera_offset)
	npc_traffic.set_camera_address(navigator.sector, navigator.local, _camera_offset)
	foreign_traffic.set_camera_address(navigator.sector, navigator.local, _camera_offset)
	asteroid_field.set_camera_address(navigator.sector, navigator.local, _camera_offset)
	asteroid_field.set_ship_world(Vector2(navigator.sector) * WorldAddress.SECTOR_SIZE + navigator.local)
	_update_black_hole_position()
	mini_map.set_solar_bodies(solar_system.get_navigation_bodies(), solar_system.OUTER_ORBIT_RADIUS)
	ship.throttle = clampf(velocity.length() / MAX_SPEED, 0.0, 1.0)
	ship.position = get_viewport_rect().size * 0.5 - _camera_offset
	mini_map.set_ship_location(navigator.sector, navigator.local, _ship_heading)
	mini_map.set_camera_offset(_camera_offset)
	_update_landing_offer()

	_report_timer += delta
	if _report_timer >= REPORT_INTERVAL:
		_report_timer = 0.0
		diagnostics.write("flight_heartbeat", {
			"position": navigator.as_dictionary(),
			"speed": snappedf(velocity.length(), 0.01),
			"autopilot_active": _autopilot_active,
			"autopilot_target": _autopilot_target,
			"fps": Engine.get_frames_per_second(),
			"plasma_visible": far_plasma.active_count(),
			"npc_visible_population": npc_traffic.active_count(),
			"asteroid_active": asteroid_field.active_count(),
			"asteroid_fragments": asteroid_field.fragment_count(),
			"npc_hyperjumps": npc_traffic.hyperjump_count(),
			"npc_landings": npc_traffic.landing_count(),
			"npc_takeoffs": npc_traffic.takeoff_count(),
			"camera_following": _camera_following,
			"camera_returning": _camera_returning,
			"camera_offset": {"x": snappedf(_camera_offset.x, 0.1), "y": snappedf(_camera_offset.y, 0.1)}
		})


func _current_system_roam_radius() -> float:
	if solar_system == null:
		return HyperjumpMotion.OUTER_JUMP_RADIUS - SYSTEM_ROAM_SOFT_MARGIN
	var region_id: String = str(solar_system.current_id)
	if region_id == "crossroads":
		return 980.0
	if region_id == "mw":
		# The lone repair shipyard sits outside Neptune, at radius ~2836.
		# Manual exploration must reach it, yet remain finite and starfield-only past the rim.
		return 3220.0
	if ["lmc", "smc", "ngc6822", "m31", "m33"].has(region_id):
		# SAME distance from system center as in the original Solar System.
		# At radius 3220 the world position stops, while visual starfield
		# continues moving: no artificial teleport or change to the warp rim.
		return 3220.0
	var orbit_limit: float = float(solar_system.OUTER_ORBIT_RADIUS) + SYSTEM_ROAM_EXTRA_RADIUS
	return minf(orbit_limit, HyperjumpMotion.OUTER_JUMP_RADIUS - SYSTEM_ROAM_SOFT_MARGIN)

func _clip_displacement_to_circle(start: Vector2, delta: Vector2, radius: float) -> Vector2:
	var a: float = delta.dot(delta)
	if a <= 0.000001:
		return Vector2.ZERO
	var b: float = 2.0 * start.dot(delta)
	var c: float = start.dot(start) - radius * radius
	var discriminant: float = b * b - 4.0 * a * c
	if discriminant <= 0.0:
		return Vector2.ZERO
	var root: float = sqrt(discriminant)
	var t1: float = (-b - root) / (2.0 * a)
	var t2: float = (-b + root) / (2.0 * a)
	var t: float = 0.0
	if t1 >= 0.0 and t1 <= 1.0:
		t = maxf(t, t1)
	if t2 >= 0.0 and t2 <= 1.0:
		t = maxf(t, t2)
	if t <= 0.0:
		return Vector2.ZERO
	return delta * maxf(0.0, t - 0.002)

func _constrain_free_flight_displacement(requested: Vector2) -> Dictionary:
	if requested.length_squared() <= 0.000001:
		return {"world": requested, "visual": requested}
	if _autopilot_active:
		return {"world": requested, "visual": requested}
	var start: Vector2 = Vector2(navigator.sector) * WorldAddress.SECTOR_SIZE + navigator.local
	var limit: float = _current_system_roam_radius()
	var finish: Vector2 = start + requested
	if finish.length() <= limit:
		return {"world": requested, "visual": requested}
	if start.length() >= limit and finish.length() < start.length():
		return {"world": requested, "visual": requested}
	if start.length() >= limit and finish.length() >= start.length():
		return {"world": Vector2.ZERO, "visual": requested}
	var clipped: Vector2 = _clip_displacement_to_circle(start, requested, limit)
	return {"world": clipped, "visual": requested}


func _build_controls() -> void:
	var ui := CanvasLayer.new()
	ui.name = "OnScreenControls"
	add_child(ui)

	var root := Control.new()
	root.name = "HUD"
	_gameplay_hud = root
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ui.add_child(root)

	mini_map = MiniMapScene.new()
	mini_map.name = "NavigationMap_TopLeft"
	root.add_child(mini_map)
	mini_map.map_navigate_requested.connect(_on_map_navigate_requested)
	mini_map.tracking_mode_changed.connect(_on_map_tracking_mode_changed)

	joystick = JoystickScene.new()
	joystick.name = "RightJoystick"
	root.add_child(joystick)
	joystick.direction_changed.connect(_on_joystick_changed)

	auto_stop_button = AutoStopScene.new()
	auto_stop_button.name = "RightStopDuringAutopilot"
	root.add_child(auto_stop_button)
	auto_stop_button.stop_requested.connect(_on_auto_stop_pressed)

	action_button = ActionScene.new()
	action_button.name = "LeftContextAction"
	root.add_child(action_button)
	action_button.set_action_mode("use")
	# Do not show a hand or send actions until a real interaction is supported.
	action_button.set_action_available(false)
	action_button.action_requested.connect(_on_action_requested)

	goal_picker = NavigationMenuScene.new()
	goal_picker.name = "TopRightDestinationPicker"
	root.add_child(goal_picker)
	goal_picker.target_selected.connect(_on_target_selected)
	goal_picker.story_catalog_opened.connect(_story_navigation_catalog_opened)

	status_hud = ResourceHudScene.new()
	status_hud.name = "Fuel_Crystals_Galaxy_MikoMenu"
	root.add_child(status_hud)
	status_hud.set_fuel_segments(INITIAL_FUEL_SEGMENTS)
	status_hud.set_crystals(INITIAL_CRYSTALS)
	status_hud.galaxy_requested.connect(_on_galaxy_requested)
	status_hud.main_menu_requested.connect(_on_main_menu_requested)
	status_hud.bubble_care_requested.connect(_on_bubble_care_requested)
	status_hud.bubble_reminder_ready.connect(_on_bubble_reminder_ready)
	status_hud.game_mode_selected.connect(_on_story_mode_selected)
	status_hud.story_arc_selected.connect(_on_story_arc_selected)

	# Full-screen overlays are above the flight HUD and consume touch events.
	galactic_map = GalacticMapScene.new()
	galactic_map.name = "GalaxySelectionScreen"
	root.add_child(galactic_map)
	galactic_map.closed.connect(_on_modal_closed)
	galactic_map.travel_requested.connect(_on_galaxy_travel_requested)

	main_menu = MikoMainMenuScene.new()
	main_menu.name = "MikoMainMenuPlaceholder"
	root.add_child(main_menu)
	main_menu.closed.connect(_on_modal_closed)
	main_menu.crystals_earned.connect(_on_educational_crystals_earned)

	_build_bubble_popup(root)
	_v122_build_empty_fuel_card(root)

	# v38: empty, localized landing-preview screen (no surface gameplay yet).
	landing_preview = LandingPreviewScene.new()
	landing_preview.name = "LandingPreview_EmptyScreen"
	root.add_child(landing_preview)
	landing_preview.closed.connect(_on_landing_preview_closed)
	# Fully transparent input shield. It does not hide any flight UI or scenery;
	# the existing destination picker is temporarily drawn above it.
	_story_navigation_blocker = ColorRect.new()
	_story_navigation_blocker.name = "StoryNavigationInputShield"
	_story_navigation_blocker.color = Color.TRANSPARENT
	_story_navigation_blocker.mouse_filter = Control.MOUSE_FILTER_STOP
	_story_navigation_blocker.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_story_navigation_blocker.z_index = 1000
	_story_navigation_blocker.visible = false
	root.add_child(_story_navigation_blocker)

	_warp_overlay = PlayerJumpFXScene.new()
	_warp_overlay.name = "SharedNPCStylePlayerJumpFX"
	_warp_overlay.z_index = 14
	add_child(_warp_overlay)


func _layout() -> void:
	var view: Vector2 = get_viewport_rect().size
	var safe: Rect2 = MobileLocale.safe_rect(view)
	ship.position = view * 0.5 - _camera_offset
	starfield.resize_field(view)
	far_plasma.resize_sky(view)
	cosmic_region.resize_sky(view)
	solar_system.resize_view(view)
	npc_traffic.resize_view(view)
	foreign_traffic.resize_view(view)
	asteroid_field.resize_view(view)
	_update_black_hole_position()
	distant_events.resize_sky(view)
	var base_control_scale: float = clampf(minf(view.x / 520.0, view.y / 340.0), 0.55, 1.0)
	# Keep touch and visible circles in sync: enlarge the ENTIRE controls, not merely their artwork.
	var control_scale: float = base_control_scale * CONTROL_SCALE_MULTIPLIER
	joystick.scale = Vector2.ONE * control_scale
	auto_stop_button.scale = Vector2.ONE * control_scale
	action_button.scale = Vector2.ONE * control_scale
	var visual_size: float = 184.0 * control_scale
	var margin: float = 18.0 * base_control_scale
	var bottom: float = maxf(safe.position.y + margin, safe.end.y - visual_size - margin)
	action_button.position = Vector2(safe.position.x + margin, bottom)
	joystick.position = Vector2(safe.end.x - visual_size - margin, bottom)
	auto_stop_button.position = joystick.position

	# No fixed-pixel assumptions: preserve the panel on compact mobile displays.
	var map_scale: float = clampf(minf(view.x / 700.0, view.y / 490.0), 0.55, 1.0)
	mini_map.scale = Vector2.ONE * map_scale
	mini_map.set_camera_view_size(view)
	mini_map.position = safe.position + Vector2(12.0 * map_scale, 12.0 * map_scale)
	# v43: each existing upper-right element becomes 20% larger than v42:
	# destination trigger + its six tiles, fuel with real blue fragment,
	# and the two lower buttons. Their centre axis and 12px gaps do not change.
	# The joystick and capture control retain their existing v38 size.
	var goals_scale: float = clampf(minf(view.x / 720.0, view.y / 440.0), 0.58, 1.0) * 1.10 * UPPER_RIGHT_UI_GROWTH
	var hud_scale: float = clampf(minf(view.x / 700.0, view.y / 490.0), 0.52, 1.0) * 1.10 * UPPER_RIGHT_UI_GROWTH
	var lower_button_extra: float = 1.20 / 1.10
	var lower_button_local_size: float = 42.0 * lower_button_extra
	var rail_gap: float = 12.0
	var right_button_center: float = joystick.position.x + visual_size * 0.5
		# On a very short landscape screen, fit the UPPER rail together rather
	# than overlap the joystick. Standard screens preserve the exact +20% growth
	# relative to v42, with fixed 12-screen-pixel gaps in every aspect ratio.
	var desired_content_height: float = NavigationMenuScene.TRIGGER_SIZE * goals_scale + 34.0 * hud_scale + 4.0 * lower_button_local_size * hud_scale
	# v84: third upper-right control below simulator fits above joystick.
	var usable_content_height: float = joystick.position.y - safe.position.y - 12.0 - 8.0 - rail_gap * 5.0
	var compact_fit: float = clampf(usable_content_height / maxf(1.0, desired_content_height), 0.10, 1.0)
	goals_scale *= compact_fit
	hud_scale *= compact_fit
	goal_picker.scale = Vector2.ONE * goals_scale
	# Preserve the scrollable single row of six destinations on narrow phones.
	var map_right: float = mini_map.position.x + 260.0 * map_scale + 12.0
	var available_px: float = right_button_center + NavigationMenuScene.TRIGGER_SIZE * goals_scale * 0.5 - map_right - 12.0
	var available_units: float = maxf(190.0, available_px / goals_scale)
	var menu_width: float = minf(available_units, NavigationMenuScene.PREFERRED_WIDTH)
	goal_picker.set_available_width(menu_width)
	# Anchor the actual round preview to the physical joystick centre.
	# The menu width changes between regions: use its measured size, never
	# the old requested width or the right edge of the screen.
	goal_picker.position = Vector2(
		right_button_center - (goal_picker.size.x - NavigationMenuScene.TRIGGER_SIZE * 0.5) * goals_scale,
		safe.position.y + 12.0
	)
	status_hud.scale = Vector2.ONE * hud_scale
	# Scale the two EXISTING children, including their clickable Control areas.
	# Position them by the CENTER (x=103), not by the HUD container's right edge.
	var lower_button_center_local: float = ResourceHudScene.HUD_WIDTH - 44.0 + 21.0
	var galaxy_button: Button = status_hud.get_node("GlobalFlight") as Button
	var ship_menu_button: TextureButton = status_hud.get_node("MikoMainMenu") as TextureButton
	var settings_button: Button = status_hud.get_node("SettingsBelowSimulator") as Button
	var bubble_button: Button = status_hud.get_node("BubbleCareClock") as Button
	var button_local_x: float = lower_button_center_local - lower_button_local_size * 0.5
	var local_gap: float = rail_gap / hud_scale
	var first_button_y: float = 34.0 + local_gap
	var second_button_y: float = first_button_y + lower_button_local_size + local_gap
	var third_button_y: float = second_button_y + lower_button_local_size + local_gap
	var fourth_button_y: float = third_button_y + lower_button_local_size + local_gap
	galaxy_button.scale = Vector2.ONE * lower_button_extra
	# Bigger real tap target during the ONLY permitted galaxy-map lesson.
	# Keep its centre at the original rail centre on every screen size.
	var lmc_tutorial_button: bool = _story_phase in ["station_map_lmc", "lmc_station_map_smc", "lotus_map_barnard"]
	galaxy_button.size = Vector2.ONE * (58.0 if lmc_tutorial_button else 42.0)
	galaxy_button.position = Vector2(button_local_x - (8.0 if lmc_tutorial_button else 0.0), first_button_y - (8.0 if lmc_tutorial_button else 0.0))
	ship_menu_button.scale = Vector2.ONE * lower_button_extra
	ship_menu_button.position = Vector2(button_local_x, second_button_y)
	bubble_button.scale = Vector2.ONE * lower_button_extra
	bubble_button.position = Vector2(button_local_x, third_button_y)
	settings_button.scale = Vector2.ONE * lower_button_extra
	settings_button.position = Vector2(button_local_x, fourth_button_y)
	status_hud.size = Vector2(ResourceHudScene.HUD_WIDTH, fourth_button_y + lower_button_local_size)
	# The seven fuel sticks and the original blue asteroid fragment stay inside
	# their existing bar. Its size grows with the entire upper-right HUD.
	status_hud.position = Vector2(
		right_button_center - lower_button_center_local * hud_scale,
		goal_picker.position.y + NavigationMenuScene.TRIGGER_SIZE * goals_scale + rail_gap
	)
	galactic_map.size = view
	main_menu.size = view
	if is_instance_valid(_planet_hub):
		_planet_hub.size = view
	if is_instance_valid(_representative_dialog):
		_representative_dialog.size = view
	landing_preview.resize_preview(view)
	if is_instance_valid(_story_navigation_blocker):
		_story_navigation_blocker.size = view
	_layout_bubble_popup(view)


func _refresh_fuel_hud() -> void:
	status_hud.set_fuel_segments(ceili((_fuel_units / FUEL_CAPACITY) * 7.0))
	status_hud.set_crystals(floori(_fuel_units + 0.001))


func _on_fuel_collected(units: int) -> void:
	if units <= 0:
		return
	var previous: float = _fuel_units
	_fuel_units = minf(FUEL_CAPACITY, _fuel_units + float(units))
	_refresh_fuel_hud()
	if _story_phase == "mars_fuel_absorbing" and _fuel_units >= FUEL_CAPACITY:
		status_hud.set_story_fuel_attention(false)
	diagnostics.write("fuel_collected", {"received": units, "added": snappedf(_fuel_units - previous, 0.01), "fuel": snappedf(_fuel_units, 0.01)})


func _on_asteroid_impact(asteroid_type: int, target_name: String, world_position: Vector2) -> void:
	if _story_phase == "mars_asteroid_approach" and asteroid_type == 6 and target_name == "Player":
		_story_begin_mars_asteroid_stun()
		diagnostics.write("story_mars_asteroid_impact", {"native_rock": true, "fuel_before": _fuel_units})
		return
	# Contact is visual for now; no fuel penalty or automatic crystal pickup.
	if target_name == "Player":
		var ship_world: Vector2 = Vector2(navigator.sector) * WorldAddress.SECTOR_SIZE + navigator.local
		var knock: Vector2 = ship_world - world_position
		if knock.length_squared() > 1.0:
			velocity += knock.normalized() * 135.0
	diagnostics.write("asteroid_impact", {"type": asteroid_type, "target": target_name, "x": snappedf(world_position.x, 1.0), "y": snappedf(world_position.y, 1.0)})


func _on_joystick_changed(direction: Vector2) -> void:
	if _story_navigation_guide_active() or _story_phase == "station_map_lmc":
		return
	if not _autopilot_active and not _warp_active:
		current_input = direction


func _on_galaxy_requested() -> void:
	if _story_phase in ["crossroads_finale_panels", "crossroads_finale_choice", "crossroads_ending1_panels", "crossroads_ending2_panels", "crossroads_ending2_note", "crossroads_ending2_draw"] and StoryProgress.read_mode() == "story":
		return
	if _story_phase in ["m33_gate_rebus", "m33_gate_transfer"] and StoryProgress.read_mode() == "story":
		return
	if _story_navigation_guide_active():
		return
	if is_instance_valid(_bubble_popup):
		_bubble_popup.hide()
	if _story_phase == "await_simulator_card":
		return

	if _warp_active or _intro_comic_playing or _intro_space_flying:
		return
	if main_menu.visible:
		return
	if _story_phase == "m31_station_departed" and StoryProgress.read_mode() == "story" and solar_system.current_id == "m31":
		_story_begin_triangulum_map_hint()
	_story_refresh_galaxy_route()
	galactic_map.open_map(get_viewport_rect().size, solar_system.current_id)
	_story_refresh_galaxy_route()
	_set_music_context("silent", true)
	get_tree().paused = true
	diagnostics.write("galactic_map_opened", {"current": solar_system.current_id, "destinations": 7})



# The popup is a clickable care card, not a new simulator catalogue entry.

const _BUBBLE_POPUP_CAPTIONS: Dictionary = {
	"ru":"Баббл ждёт тебя", "en":"Bubble is waiting", "fr":"Bubble t'attend",
	"de":"Bubble wartet", "es":"Bubble te espera", "pt_BR":"Bubble está esperando"
}
const _BUBBLE_CARE_HINTS: Dictionary = {
	"ru":"Уход за Бабблом", "en":"Care for Bubble", "fr":"Prendre soin de Bubble",
	"de":"Bubble pflegen", "es":"Cuidar a Bubble", "pt_BR":"Cuidar do Bubble"
}

func _bubble_card_caption() -> String:
	return str(_BUBBLE_POPUP_CAPTIONS.get(str(MobileLocale.language),_BUBBLE_POPUP_CAPTIONS["en"]))

func _bubble_card_update_language(_locale: String) -> void:
	if not is_instance_valid(_bubble_popup):
		return
	var card: Control = _bubble_popup.get_node_or_null("SameSimulatorPortraitCard") as Control
	if card != null:
		card.set("card_title",_bubble_card_caption())
	if is_instance_valid(status_hud):
		var care_button: Button = status_hud.get_node_or_null("BubbleCareClock") as Button
		if care_button != null:
			care_button.tooltip_text = str(_BUBBLE_CARE_HINTS.get(str(MobileLocale.language), _BUBBLE_CARE_HINTS["en"]))

func _build_bubble_popup(root: Control) -> void:
	# Actual card system from the simulator, with its same silhouette and glow.
	# Unlike v8.5.0 this is NOT a plain rectangular picture button.
	_bubble_popup = Button.new()
	_bubble_popup.name = "BubbleCareCenterReminder"
	_bubble_popup.text = ""
	_bubble_popup.tooltip_text = "Bubble"
	_bubble_popup.focus_mode = Control.FOCUS_NONE
	_bubble_popup.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	for style_name in ["normal","hover","pressed","disabled","focus"]:
		_bubble_popup.add_theme_stylebox_override(style_name,StyleBoxEmpty.new())
	_bubble_popup.pressed.connect(_on_bubble_care_requested)
	var card_script: Script = load("res://simulator_ui/scripts/approved_simulator_card.gd") as Script
	var card: Control = card_script.new() as Control
	card.name = "SameSimulatorPortraitCard"
	card.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.set("card_title",_bubble_card_caption())
	card.set("card_subtitle","")
	card.set("card_description","")
	card.set("image_fit_mode","contain")
	card.set("image_path","res://simulator_ui/assets/approved_icons/sim_11_bubble_care.png")
	_bubble_popup.add_child(card)
	card.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	# v8.5.1.3: simulator card descendants may consume mouse/touch events.
	# Put ONE invisible hit surface above them; reuse the direct-care callback.
	var card_hit: Button = Button.new()
	card_hit.name = "BubbleCareReminderFullCardHit"
	card_hit.text = ""
	card_hit.focus_mode = Control.FOCUS_NONE
	card_hit.mouse_filter = Control.MOUSE_FILTER_STOP
	card_hit.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	for hit_state in ["normal", "hover", "pressed", "disabled", "focus"]:
		card_hit.add_theme_stylebox_override(hit_state, StyleBoxEmpty.new())
	_bubble_popup.add_child(card_hit)
	card_hit.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	card_hit.pressed.connect(_on_bubble_care_requested)
	_bubble_popup.visible = false
	root.add_child(_bubble_popup)
	MobileLocale.language_changed.connect(_bubble_card_update_language)

func _layout_bubble_popup(view: Vector2) -> void:
	if not is_instance_valid(_bubble_popup):
		return
	var sc: float = clampf(minf(view.x/1280.0,view.y/720.0),0.44,0.92)
	var portrait: Vector2 = Vector2(430.0,540.0)*sc
	_bubble_popup.size = portrait
	_bubble_popup.position = (view-portrait)*0.5

func _bubble_flight_available() -> bool:
	# Shared flight-UI readiness: the empty-fuel SIMULATOR card also calls this.
	# Bubble story unlock must never gate this method, or the simulator card
	# disappears from the Prologue before Mika meets Bubble on Mars.
	return (_gameplay_hud != null and _gameplay_hud.visible and not get_tree().paused
		and not _warp_active and not _intro_comic_playing and not _intro_space_flying
		and not _planet_landing_active and not main_menu.visible and not galactic_map.visible
		and not status_hud.call("bubble_settings_open"))

func _sync_bubble_story_access() -> void:
	# Bubble is a permanent unlock, independent of the active replay.
	_bubble_access_available = (StoryProgress.read_mode() == "free_world"
		or StoryProgress.story_bubble_joined())
	if is_instance_valid(status_hud):
		status_hud.call("set_bubble_care_available", _bubble_access_available)
	_bubble_card_update_language(str(MobileLocale.language))
	if not _bubble_access_available:
		_bubble_attention_pending = false
		if is_instance_valid(_bubble_popup):
			_bubble_popup.hide()

func story_bubble_joins_on_mars() -> void:
	# Never reset an already-running care clock when restoring a saved game.
	# Bubble joins only after the native Mars launch, not during the comic.
	if StoryProgress.read_mode() != "story":
		return
	if StoryProgress.story_bubble_joined():
		_sync_bubble_story_access()
		return
	if StoryProgress.mark_story_bubble_joined():
		_bubble_attention_pending = false
		status_hud.call("reset_bubble_clock")
		_sync_bubble_story_access()

func _on_bubble_reminder_ready() -> void:
	if not _bubble_access_available:
		return
	_bubble_attention_pending = true
	_refresh_bubble_popup()

func _refresh_bubble_popup() -> void:
	if not is_instance_valid(_bubble_popup):
		return
	_bubble_popup.visible = _bubble_access_available and _bubble_attention_pending and _bubble_flight_available() and _fuel_units > 0.0 and not _story_simulator_required

func _on_bubble_care_requested() -> void:
	if _story_navigation_guide_active():
		return
	if not _bubble_access_available:
		return
	if _story_phase == "await_simulator_card":
		return
	if not _bubble_flight_available():
		return
	_bubble_attention_pending = false
	_bubble_popup.visible = false
	main_menu.set_stats(status_hud.crystal_count, 0, 0.0)
	main_menu.call("open_bubble_care_direct", get_viewport_rect().size)
	if main_menu.visible:
		if StoryProgress.read_mode() == "story" and StoryProgress.story_bubble_joined():
			StoryProgress.mark_story_bubble_intro_done()
		_set_music_context("silent", true)
		status_hud.call("reset_bubble_clock")
		get_tree().paused = true

func _on_main_menu_requested() -> void:
	if _story_phase in ["crossroads_finale_panels", "crossroads_finale_choice", "crossroads_ending1_panels", "crossroads_ending2_panels", "crossroads_ending2_note", "crossroads_ending2_draw"] and StoryProgress.read_mode() == "story":
		return
	if _story_phase in ["m33_gate_rebus", "m33_gate_transfer"] and StoryProgress.read_mode() == "story":
		return
	if _story_navigation_guide_active():
		return
	if is_instance_valid(_bubble_popup):
		_bubble_popup.hide()
	# Story enters the simulator only through the existing central card.
	if _story_phase == "await_simulator_card":
		return

	if _warp_active or _intro_comic_playing or _intro_space_flying:
		return
	if galactic_map.visible:
		return
	main_menu.set_stats(status_hud.crystal_count, 0, 0.0)
	main_menu.open_menu(get_viewport_rect().size)
	_set_music_context("silent", true)
	get_tree().paused = true
	diagnostics.write("miko_main_menu_opened", {"screen": "bridge", "flight_crystals": status_hud.crystal_count, "crystal_capacity": 0, "ship_speed": 0})


func _on_educational_crystals_earned(units: int) -> void:
	# Correct answers in locally copied Play Town games refill the fuel tank.
	_on_fuel_collected(units)


func _on_modal_closed() -> void:
	if _story_phase == "inside_simulator":
		_story_after_simulator()
		return
	if _planet_landing_active and is_instance_valid(_planet_hub):
		_planet_hub.visible = true
		_set_music_context("calm")
		get_tree().paused = true
		return
	_set_music_context("flight")
	get_tree().paused = false
	diagnostics.write("flight_overlay_closed", {})


# M33 uses the same saved region unlock and the NATIVE map destination hint
# that worked for the earlier LMC / SMC / Barnard / Andromeda handoffs.
# Never synthesize a separate ring or unlock an unfinished chapter early.
func _story_m33_map_guidance_active() -> bool:
	return StoryProgress.read_mode() == "story" and solar_system.current_id == "m31" and _story_phase == "m31_map_triangulum"


func _on_galaxy_travel_requested(region_id: String, direction: Vector2) -> void:
	if _intro_comic_playing or _intro_space_flying or _warp_active:
		return
	if _story_phase == "station_map_lmc" and region_id != "lmc":
		return
	if not StorySubscriptionGate.can_open_region(region_id):
		get_tree().paused = false
		_set_music_context("flight")
		StorySubscriptionGate.show_notice(self, "galaxy")
		return
	if solar_system.get_system(region_id).is_empty():
		return
	if _story_phase == "station_map_lmc":
		_story_set_phase("station_warp_out")
		status_hud.set_story_galaxy_attention(false)
		galactic_map.set_story_lmc_lesson(false)
	elif _story_phase == "lmc_station_map_smc" and region_id == "smc":
		_story_set_phase("lmc_station_warp_smc")
		status_hud.set_story_galaxy_attention(false)
		galactic_map.set_story_destination_hint("")
	elif _story_phase == "lotus_map_barnard" and region_id == "ngc6822":
		_story_set_phase("lotus_warp_barnard")
		status_hud.set_story_galaxy_attention(false)
		galactic_map.set_story_destination_hint("")
	elif _story_phase == "runa_map_andromeda" and region_id == "m31":
		_story_set_phase("runa_warp_andromeda")
		status_hud.set_story_galaxy_attention(false)
		galactic_map.set_story_destination_hint("")
	elif _story_phase == "m31_map_triangulum" and region_id == "m33":
		_story_set_phase("m31_warp_triangulum")
		status_hud.set_story_galaxy_attention(false)
		galactic_map.set_story_destination_hint("")
	get_tree().paused = false
	_set_music_context("flight")
	if _autopilot_active:
		_stop_autopilot("hyperspace_jump")
	velocity = Vector2.ZERO
	current_input = Vector2.ZERO
	joystick.clear_input()
	_camera_following = true
	_camera_returning = false
	_map_camera_flying = false
	_camera_offset = Vector2.ZERO
	_warp_active = true
	_warp_phase = "cruise"
	_warp_time = 0.0
	_warp_destination = region_id
	_warp_direction = direction.normalized()
	if _warp_direction.length_squared() < 0.001:
		_warp_direction = Vector2.RIGHT
	_warp_exit_world = HyperjumpMotion.exit_world(_warp_direction)
	_warp_velocity = Vector2.ZERO
	_warp_switched = false
	# Keep all UI nodes alive: the HUD is hidden only during the 0.36 s dash.
	_gameplay_hud.visible = true
	ship.visible = true
	ship.scale = Vector2.ONE
	ship.modulate = Color.WHITE
	_ship_heading = _warp_direction.angle() + PI * 0.5
	ship.rotation = _ship_heading
	ship.throttle = 0.0
	_warp_overlay.clear_effect()
	diagnostics.write("hyperspace_route_started", {"from": solar_system.current_id, "to": region_id,
		"ship_x": _ship_world().x, "ship_y": _ship_world().y,
		"edge_x": _warp_exit_world.x, "edge_y": _warp_exit_world.y,
		"boundary_radius": HyperjumpMotion.OUTER_JUMP_RADIUS})


func _ship_world() -> Vector2:
	return Vector2(navigator.sector) * WorldAddress.SECTOR_SIZE + navigator.local


func _advance_warp(delta: float) -> void:
	var here: Vector2 = _ship_world()
	match _warp_phase:
		"cruise":
			# Fly across the actual system to the SAME 2500-unit rim as NPCs.
			# No 82-unit braking shell: previously it could converge to 82.00001
			# and never satisfy the jump condition. Snap only the last 12 units.
			var remaining: Vector2 = _warp_exit_world - here
			var distance: float = remaining.length()
			if distance <= WARP_EDGE_SNAP_DISTANCE:
				# Complete the short final distance explicitly: jump must begin
				# AT the outer border, never from within the solar system.
				_story_move_to(_warp_exit_world)
				_warp_velocity = Vector2.ZERO
				ship.throttle = 0.0
				_warp_phase = "charge"
				_warp_time = 0.0
				_warp_overlay.spawn_cloud(ship.position)
				diagnostics.write("hyperspace_edge_reached", {"system": solar_system.current_id,
					"distance_to_sun": _ship_world().length(),
					"boundary_radius": HyperjumpMotion.OUTER_JUMP_RADIUS,
					"remaining_before_snap": distance})
				return
			var aim: Vector2 = remaining / distance
			var desired_speed: float = minf(AUTO_CRUISE_SPEED, sqrt(2.0 * AUTO_BRAKE_ACCEL * distance))
			_warp_velocity = _warp_velocity.move_toward(aim * desired_speed, AUTO_STEERING_ACCEL * delta)
			var displacement: Vector2 = _warp_velocity * delta
			if displacement.length_squared() >= remaining.length_squared():
				displacement = remaining
			_story_move_to(here + displacement)
			if displacement.length_squared() > 0.001:
				_ship_heading = lerp_angle(_ship_heading, displacement.angle() + PI * 0.5, minf(1.0, delta * 4.0))
				ship.rotation = _ship_heading
			ship.throttle = clampf(_warp_velocity.length() / MAX_SPEED, 0.0, 1.0)
		"charge":
			# Same preparation/engine braking as NpcTraffic.gd.
			_warp_time += delta
			_warp_velocity = _warp_velocity.move_toward(Vector2.ZERO, 340.0 * delta)
			_story_move_to(here + _warp_velocity * delta)
			ship.throttle = 0.1
			# v47: finish aligning the visible nose (-Y) to the real jump vector.
			var intended_heading: float = _warp_direction.angle() + PI * 0.5
			_ship_heading = lerp_angle(_ship_heading, intended_heading, minf(1.0, delta * 9.0))
			ship.rotation = _ship_heading
			var heading_error: float = absf(wrapf(intended_heading - _ship_heading, -PI, PI))
			_warp_overlay.show_charge(clampf(_warp_time / HyperjumpMotion.CHARGE_TIME, 0.0, 1.0), ship.position)
			if _warp_time >= HyperjumpMotion.CHARGE_TIME and heading_error < 0.015:
				_ship_heading = intended_heading
				ship.rotation = intended_heading
				_warp_phase = "dash_out"
				_warp_time = 0.0
				_gameplay_hud.visible = false
				diagnostics.write("hyperspace_jump_started", {"system": solar_system.current_id,
					"distance_to_sun": _ship_world().length(), "duration": HyperjumpMotion.DASH_TIME})
		"dash_out":
			# NPC-style dash: same shared speed, exact trail/flash geometry,
			# and scale-increase. No translucent tunnel or fade/shrink.
			_warp_time += delta
			var departure_progress: float = clampf(_warp_time / HyperjumpMotion.DASH_TIME, 0.0, 1.0)
			ship.rotation = _ship_heading
			var nose_forward: Vector2 = Vector2.from_angle(_ship_heading - PI * 0.5)
			_story_move_to(here + nose_forward * HyperjumpMotion.dash_speed(departure_progress) * delta)
			ship.scale = Vector2.ONE * NpcJumpVisual.dash_ship_scale(departure_progress)
			ship.modulate = Color.WHITE
			ship.throttle = 1.0
			_warp_overlay.show_dash(departure_progress, ship.position, _ship_heading)
			if departure_progress >= 1.0:
				_warp_overlay.spawn_cloud(ship.position)
				_warp_overlay.end_jump()
				ship.visible = false
				_warp_time = 0.0
				if _story_phase == "station_warp_out" and _warp_destination == "lmc":
					_warp_phase = "story_interlude"
					_story_show_panels("station_final_panel", ["p07_lmc_window"])
				elif _story_phase == "lotus_warp_barnard" and _warp_destination == "ngc6822":
					# In the actual intergalactic transfer: professor takes his bath,
					# discovers the phase guest, then two pirate ships attack.
					_warp_phase = "story_interlude"
					_story_show_panels("barnard_prearrival_panels", [
						"p41_professor_bath_walk", "p41_professor_bath_rest",
						"p41_phase_bath_surprise", "p41_pirate_ships"
					])
				elif _story_phase == "m31_warp_triangulum" and _warp_destination == "m33":
					_warp_phase = "story_interlude"
					_story_show_panels("m33_intro_panels", CH06_INTRO)
				else:
					_warp_phase = "transit"
		"story_interlude":
			# The PDF animation owns this pause, with the world still in MW.
			pass
		"transit":
			# NPCs disappear after the dash. The same brief absence
			# masks the galaxy swap without adding a different visual.
			_warp_time += delta
			if _warp_time >= 0.42:
				_arrive_new_region(_warp_destination, HyperjumpMotion.arrival_world(_warp_direction))
				_warp_switched = true
				_warp_overlay.clear_effect()
				_warp_overlay.spawn_cloud(ship.position)
				ship.visible = true
				ship.scale = Vector2.ONE
				ship.modulate = Color.WHITE
				ship.rotation = _ship_heading
				_warp_phase = "dash_in"
				_warp_time = 0.0
		"dash_in":
			_warp_time += delta
			var arrival_progress: float = clampf(_warp_time / HyperjumpMotion.DASH_TIME, 0.0, 1.0)
			ship.rotation = _ship_heading
			var arrival_nose: Vector2 = Vector2.from_angle(_ship_heading - PI * 0.5)
			_story_move_to(here + arrival_nose * HyperjumpMotion.dash_speed(arrival_progress) * delta)
			ship.scale = Vector2.ONE * NpcJumpVisual.dash_ship_scale(arrival_progress)
			ship.modulate = Color.WHITE
			ship.throttle = 1.0
			_warp_overlay.show_dash(arrival_progress, ship.position, _ship_heading)
			if arrival_progress >= 1.0:
				_warp_active = false
				_warp_phase = "idle"
				_warp_overlay.end_jump()
				_gameplay_hud.visible = not (_story_phase == "runa_warp_andromeda" and StoryProgress.read_mode() == "story")
				ship.position = get_viewport_rect().size * 0.5
				ship.scale = Vector2.ONE
				ship.modulate = Color.WHITE
				ship.throttle = 0.0
				_warp_velocity = Vector2.ZERO
				velocity = Vector2.ZERO
				current_input = Vector2.ZERO
				joystick.clear_input()
				joystick.visible = true
				auto_stop_button.visible = false
				diagnostics.write("hyperspace_arrived", {"system": solar_system.current_id,
					"ship": navigator.as_dictionary(), "radius": _ship_world().length()})
				if _story_phase == "station_final_panel" and solar_system.current_id == "lmc":
					_story_restore_after_lmc_jump()
				elif _story_phase == "lmc_station_warp_smc" and solar_system.current_id == "smc":
					_story_arrive_smc()
				elif _story_phase == "barnard_warp_resume" and solar_system.current_id == "ngc6822":
					_story_arrive_barnard()
				elif _story_phase == "runa_warp_andromeda" and solar_system.current_id == "m31":
					_story_arrive_andromeda()
				elif _story_phase in ["m31_warp_triangulum", "m33_intro_panels"] and solar_system.current_id == "m33":
					_story_arrive_triangulum_preview()

func _arrive_new_region(region_id: String, new_spawn: Vector2) -> void:
	var previous_world: Vector2 = Vector2(navigator.sector) * WorldAddress.SECTOR_SIZE + navigator.local
	if not solar_system.set_region(region_id):
		return
	navigator = WorldAddress.new()
	navigator.advance(new_spawn)
	starfield.advance(new_spawn - previous_world)
	starfield.set_camera_look(Vector2.ZERO)
	far_plasma.visible = region_id != "crossroads"
	cosmic_region.visible = region_id == "mw"
	black_hole.visible = region_id == "mw"
	mini_map.set_debug_landmark(CosmicRegionScene.BLACK_HOLE_WORLD, DEBUG_SHOW_BLACK_HOLE_ON_MAP and region_id == "mw")
	var home: bool = region_id == "mw"
	npc_traffic.visible = home
	npc_traffic.process_mode = Node.PROCESS_MODE_INHERIT if home else Node.PROCESS_MODE_DISABLED
	foreign_traffic.set_region(region_id)
	# Dynamic asteroids exist in all real systems; Crossroads is not a star system.
	asteroid_field.reset_for_region(region_id)
	asteroid_field.visible = region_id != "crossroads"
	asteroid_field.process_mode = Node.PROCESS_MODE_INHERIT if region_id != "crossroads" else Node.PROCESS_MODE_DISABLED
	var system_data: Dictionary = solar_system.get_system(region_id)
	_landing_target_id = ""
	_landing_target_name = ""
	action_button.set_action_available(false)
	goal_picker.set_region_destinations(region_id, system_data.get("planets", []), system_data.get("station", null))
	if not StoryProgress.local_story_route(_story_phase).is_empty():
		_story_refresh_local_route()
	# Never carry a previous galaxy's destination pulse into a different system.
	_story_refresh_galaxy_route()
	# Destination counts change the menu's actual width. Re-anchor the preview
	# immediately after every inter-system arrival, not only on window resize.
	_layout()
	goal_picker.visible = true
	# InfiniteSpace v104.2: restore Crossroads destination picker
	mini_map.reset_for_region()
	solar_system.set_camera_address(navigator.sector, navigator.local, Vector2.ZERO)
	mini_map.set_solar_bodies(solar_system.get_navigation_bodies(), solar_system.OUTER_ORBIT_RADIUS)
	mini_map.set_ship_location(navigator.sector, navigator.local, _ship_heading)
	mini_map.set_camera_offset(Vector2.ZERO)
	ship.position = get_viewport_rect().size * 0.5
	npc_traffic.set_camera_address(navigator.sector, navigator.local, Vector2.ZERO)
	foreign_traffic.set_camera_address(navigator.sector, navigator.local, Vector2.ZERO)
	asteroid_field.set_camera_address(navigator.sector, navigator.local, Vector2.ZERO)
	asteroid_field.set_ship_world(new_spawn)
	cosmic_region.set_camera_address(navigator.sector, navigator.local, Vector2.ZERO)
	far_plasma.set_camera_address(navigator.sector, navigator.local, Vector2.ZERO)
	_update_black_hole_position()
	diagnostics.write("atlas_region_loaded", {"id": region_id, "planets": system_data.get("planets", []).size(), "fictional": region_id != "mw"})


func _on_target_selected(target_id: String) -> void:
	if _story_phase == "station_map_lmc":
		return
	if ["navigation_open", "earth_departed", "mars_navigation_open", "mars_navigation_selected", "mars_asteroid_approach", "mars_asteroid_stun", "mars_fuel_collect", "mars_fuel_absorbing"].has(_story_phase):
		return
	if _story_phase == "navigation_earth" and target_id != "Earth":
		return
	if _story_phase == "mars_navigation_target" and target_id != "Mars":
		return
	if _story_phase == "mars_navigation_resume" and (target_id != "Mars" or _autopilot_active):
		return
	if _warp_active or _story_phase == "await_simulator_card":
		return
	var state: Dictionary = solar_system.get_target_state(target_id)
	if not bool(state.get("valid", false)):
		diagnostics.write("autopilot_invalid_target", {"target": target_id})
		return
	if _story_phase == "navigation_earth":
		_story_set_phase("navigation_selected")
		_story_stop_navigation_guide()
	elif _story_phase == "mars_navigation_target":
		_story_mars_asteroid_elapsed = 0.0
		_story_set_phase("mars_navigation_selected")
		_story_stop_navigation_guide()
	else:
		_story_refresh_local_route(false, target_id)
	_autopilot_target = target_id
	_autopilot_active = true
	current_input = Vector2.ZERO
	joystick.clear_input()
	joystick.visible = false
	# Child cannot cancel the guided Mars landing; normal autopilot is unchanged.
	auto_stop_button.visible = not STORY_MARS_AUTOPILOT_PHASES.has(_story_phase)
	goal_picker.set_autopilot_status(true, target_id)
	_start_camera_return("autopilot_selected")
	diagnostics.write("autopilot_started", {"target": target_id, "ship": navigator.as_dictionary()})


func _update_autopilot(delta: float) -> void:
	var state: Dictionary = solar_system.get_target_state(_autopilot_target)
	if not bool(state.get("valid", false)):
		_stop_autopilot("target_unavailable")
		return
	var ship_world: Vector2 = Vector2(navigator.sector) * WorldAddress.SECTOR_SIZE + navigator.local
	var destination: Vector2 = state["world"]
	var target_velocity: Vector2 = state["velocity"]
	var approach: Vector2 = destination - ship_world
	var distance: float = approach.length()
	var arrival_radius: float = float(state["arrival_radius"])
	if distance <= arrival_radius:
		if ["mars_navigation_selected", "mars_asteroid_approach"].has(_story_phase):
			# This one-time teaching collision must happen before the Mars Hub.
			velocity = Vector2.ZERO
			return
		var arrived_target: String = _autopilot_target
		_stop_autopilot("arrived")
		if arrived_target == CH07_PLANET and _ch07_can_begin():
			_ch07_start_finale()
			return
		var landing_planet: Dictionary = _resolve_autopilot_destination(arrived_target)
		if not landing_planet.is_empty():
			_begin_planet_landing(str(landing_planet.get("id", "")), str(landing_planet.get("name_ru", landing_planet.get("name_en", ""))))
		return
	# Predict the moving body's future location. Lead time diminishes near it.
	var lead_seconds: float = clampf((distance - arrival_radius) / AUTO_CRUISE_SPEED, 0.0, 1.25)
	var intercept: Vector2 = destination + target_velocity * lead_seconds
	var aim: Vector2 = (intercept - ship_world).normalized()
	var remaining: float = maxf(0.0, distance - arrival_radius)
	var desired_speed: float = minf(AUTO_CRUISE_SPEED, sqrt(2.0 * AUTO_BRAKE_ACCEL * remaining))
	var desired_velocity: Vector2 = aim * desired_speed + target_velocity
	velocity = velocity.move_toward(desired_velocity.limit_length(MAX_SPEED), AUTO_STEERING_ACCEL * delta)


# v65: auto-landing resolves stations and any planet target.
# Navigation still lists inhabited bodies only, but every planet may be landed on,
# and accessible stations should open the same hub automatically after arrival.
func _begin_autoland_payload(entry: Variant, fallback_id: String = "") -> Dictionary:
	if not (entry is Dictionary):
		return {}
	var payload: Dictionary = entry.duplicate(true)
	if String(payload.get("id", "")).is_empty():
		payload["id"] = fallback_id
	return payload

func _resolve_autopilot_destination(target_id: String) -> Dictionary:
	var system_data: Dictionary = solar_system.get_system(solar_system.current_id)
	for item in system_data.get("planets", []):
		if not (item is Dictionary):
			continue
		if target_id != str(item.get("id", "")) and target_id != str(item.get("name_en", "")):
			continue
		return _begin_autoland_payload(item, target_id)
	var station: Variant = system_data.get("station", {})
	if station is Dictionary:
		if target_id == str(station.get("id", "")) or target_id == str(station.get("name_en", "")):
			if bool(station.get("accessible", true)):
				return _begin_autoland_payload(system_data.get("station", {}), target_id)
	return {}


func _on_auto_stop_pressed() -> void:
	if _story_navigation_guide_active():
		return
	_stop_autopilot("stop_button")


func _stop_autopilot(reason: String) -> void:
	if not _autopilot_active:
		return
	var previous_target: String = _autopilot_target
	_autopilot_active = false
	_autopilot_target = ""
	velocity = Vector2.ZERO
	current_input = Vector2.ZERO
	auto_stop_button.visible = false
	joystick.clear_input()
	joystick.visible = true
	goal_picker.set_autopilot_status(false)
	if not _planet_landing_active and reason != "story_chapter_checkpoint":
		_story_refresh_local_route()
	diagnostics.write("autopilot_stopped", {"reason": reason, "target": previous_target, "ship": navigator.as_dictionary()})


func _update_landing_offer() -> void:
	# Planetary landings only on explicitly inhabited worlds; stations are ports.
	if _warp_active or _intro_comic_playing or _intro_space_flying or get_tree().paused:
		return
	var ship_world: Vector2 = _ship_world()
	if solar_system.current_id == "crossroads":
		# The Living World is centered at world coordinates (0,0) in OtherSystem.gd.
		var near_living_world: bool = ship_world.length() <= 620.0
		_landing_target_id = "crossroads_core" if near_living_world else ""
		_landing_target_name = "Living World" if near_living_world else ""
		action_button.set_action_mode("talk" if near_living_world else "use")
		action_button.set_action_available(near_living_world)
		return
	var system_data: Dictionary = solar_system.get_system(solar_system.current_id)
	var positions: Dictionary = {}
	for body in solar_system.get_navigation_bodies():
		positions[str(body.get("name", ""))] = body.get("world", Vector2.ZERO)
	var closest_id: String = ""
	var closest_name: String = ""
	var nearest_ratio: float = INF
	for planet in system_data.get("planets", []):
		if str(planet.get("landing", "orbit")) != "landing":
			continue
		var name_en: String = str(planet.get("name_en", ""))
		if not positions.has(name_en):
			continue
		var planet_world: Vector2 = positions[name_en]
		var distance: float = ship_world.distance_to(planet_world)
		var radius: float = LANDING_APPROACH_MARGIN + float(planet.get("size", 120.0)) * 0.5
		var id: String = str(planet.get("id", ""))
		if id == _landing_target_id:
			radius += 12.0
		if distance <= radius and distance / radius < nearest_ratio:
			nearest_ratio = distance / radius
			closest_id = id
			closest_name = name_en
	var station: Variant = system_data.get("station", null)
	if station is Dictionary and bool(station.get("accessible", true)):
		var station_id: String = str(station.get("id", ""))
		var station_name: String = "EarthStation" if solar_system.current_id == "mw" else str(station.get("name_en", ""))
		if positions.has(station_name):
			var station_world: Vector2 = positions[station_name]
			var station_distance: float = ship_world.distance_to(station_world)
			var station_radius: float = LANDING_APPROACH_MARGIN + 65.0
			if station_id == _landing_target_id:
				station_radius += 12.0
			if station_distance <= station_radius and station_distance / station_radius < nearest_ratio:
				closest_id = station_id
				closest_name = str(station.get("name_en", "Station"))
	# The existing left button becomes a magnet near loose fuel crystals.
	# The landing prompt returns when no eligible crystals remain.
	var can_collect: bool = _fuel_units < FUEL_CAPACITY and asteroid_field.has_collectible_in_range(ship_world)
	var required_mode: String = "take" if can_collect else ("land" if closest_id != "" else "use")
	var available: bool = can_collect or closest_id != ""
	if closest_id == _landing_target_id and action_button.action_mode == required_mode and action_button.interaction_available == available:
		return
	_landing_target_id = closest_id
	_landing_target_name = closest_name
	action_button.set_action_mode(required_mode)
	action_button.set_action_available(available)
	diagnostics.write("landing_offer_updated", {"planet": closest_id, "available": closest_id != ""})


func _on_action_requested(mode: String) -> void:
	if _story_phase in ["m31_lost_drift", "m31_gravity_pull", "m31_near_planet_panels", "m31_final_approach", "m31_gravity_landing", "m31_pinball_preview"]:
		return
	if _story_phase == "mars_fuel_collect":
		if mode == "take" and asteroid_field.start_magnet_capture(_ship_world()):
			_story_set_phase("mars_fuel_absorbing")
			_story_stop_mars_hand_pulse()
			action_button.set_action_available(false)
			_story_finish_mars_fuel_capture()
		return
	if _story_navigation_guide_active():
		return
	if _story_phase == "await_simulator_card":
		return
	if mode == "talk" and solar_system.current_id == "crossroads":
		if _ship_world().length() <= 620.0 and not _warp_active and not get_tree().paused:
			if _ch07_can_begin():
				_ch07_start_finale()
			else:
				_v104_open_crossroads_dialog()
		return
	if mode == "take":
		if not _warp_active and not _intro_comic_playing and not _intro_space_flying and not get_tree().paused and _fuel_units < FUEL_CAPACITY:
			asteroid_field.start_magnet_capture(_ship_world())
		return
	if mode != "land" or _landing_target_id == "":
		return
	if _warp_active or _intro_comic_playing or _intro_space_flying or get_tree().paused:
		return
	if _landing_target_id.contains("_p"):
		_begin_planet_landing(_landing_target_id, _landing_target_name)
		return
	# v62: accessible stations use the existing planet hub + translator.
	if _landing_target_id.begins_with("st_"):
		_begin_planet_landing(_landing_target_id, _landing_target_name)
		return
	if _autopilot_active:
		_stop_autopilot("landing_preview")
	velocity = Vector2.ZERO
	current_input = Vector2.ZERO
	joystick.clear_input()
	landing_preview.open_preview(_landing_target_name)
	get_tree().paused = true
	diagnostics.write("landing_preview_opened", {"planet": _landing_target_id, "scene": "placeholder_only"})


func _on_landing_preview_closed() -> void:
	get_tree().paused = false
	joystick.clear_input()
	current_input = Vector2.ZERO
	diagnostics.write("landing_preview_closed", {"planet": _landing_target_id})
	_update_landing_offer()


func _on_map_tracking_mode_changed(mode: String) -> void:
	diagnostics.write("navigation_map_mode", {"mode": mode, "ship_position": navigator.as_dictionary()})


func _on_map_navigate_requested(world_position: Vector2) -> void:
	if _story_navigation_guide_active() or _story_phase == "station_map_lmc":
		return
	if _warp_active:
		return
	# Visit a point shown on the mini-map, without moving or teleporting ship.
	var ship_world: Vector2 = Vector2(navigator.sector) * WorldAddress.SECTOR_SIZE + navigator.local
	_map_camera_start_world = ship_world + _camera_offset
	_map_camera_target_world = world_position
	_map_camera_elapsed = 0.0
	var travel_distance: float = _map_camera_start_world.distance_to(world_position)
	_map_camera_duration = clampf(0.64 + sqrt(travel_distance / 900.0) * 0.22, 0.64, 1.45)
	_camera_following = false
	_camera_returning = false
	_map_camera_flying = true
	diagnostics.write("mini_map_camera_target", {"x": snappedf(world_position.x, 0.1), "y": snappedf(world_position.y, 0.1), "distance": snappedf(travel_distance, 0.1)})


func _update_map_camera_flight(delta: float) -> void:
	_map_camera_elapsed += delta
	var t: float = clampf(_map_camera_elapsed / _map_camera_duration, 0.0, 1.0)
	var eased: float = t * t * (3.0 - 2.0 * t)
	var camera_world: Vector2 = _map_camera_start_world.lerp(_map_camera_target_world, eased)
	var ship_world: Vector2 = Vector2(navigator.sector) * WorldAddress.SECTOR_SIZE + navigator.local
	_camera_offset = camera_world - ship_world
	if t >= 1.0:
		_map_camera_flying = false
		diagnostics.write("mini_map_camera_arrived", {"x": snappedf(camera_world.x, 0.1), "y": snappedf(camera_world.y, 0.1)})


func _unhandled_input(event: InputEvent) -> void:
	if _story_navigation_guide_active() or _story_phase == "station_map_lmc":
		return
	if _story_phase in ["m31_lost_drift", "m31_gravity_pull", "m31_near_planet_panels", "m31_final_approach", "m31_gravity_landing", "m31_pinball_preview"]:
		return
	if _warp_active:
		return
	# The UI consumes its own events. Only touches beginning in the open
	# starfield can drag the MAIN camera (not the small navigation map).
	if event is InputEventScreenTouch:
		if event.pressed and _look_touch == -1:
			_look_touch = event.index
			_look_dragged = false
		elif not event.pressed and event.index == _look_touch:
			_finish_camera_drag()
			_look_touch = -1
	elif event is InputEventScreenDrag and event.index == _look_touch:
		_pan_camera(-event.relative)
		_look_dragged = true
		get_viewport().set_input_as_handled()
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			_look_mouse_down = true
			_look_dragged = false
		elif _look_mouse_down:
			_finish_camera_drag()
			_look_mouse_down = false
	elif event is InputEventMouseMotion and _look_mouse_down:
		_pan_camera(-event.relative)
		_look_dragged = true
		get_viewport().set_input_as_handled()
	elif event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_F8 and OS.has_feature("debug"):
			_start_story_comic()
		elif event.keycode == KEY_HOME or event.keycode == KEY_R:
			_start_camera_return("keyboard")
		elif event.keycode == KEY_B and DEBUG_SHOW_BLACK_HOLE_ON_MAP:
			# Test shortcut only: inspect the secret region; ship stays put.
			_on_map_navigate_requested(CosmicRegionScene.BLACK_HOLE_WORLD)
		elif event.keycode == KEY_F and OS.has_feature("debug"):
			# Debug: F uses 5 fuel units; Shift+F adds 5.
			_fuel_units = clampf(_fuel_units + (5.0 if event.shift_pressed else -5.0), 0.0, FUEL_CAPACITY)
			_refresh_fuel_hud()
		elif event.keycode == KEY_C and OS.has_feature("debug"):
			_on_fuel_collected(3)


func _pan_camera(world_delta: Vector2) -> void:
	if _warp_active:
		return
	if world_delta.length_squared() < 0.001:
		return
	if _camera_returning or _map_camera_flying:
		# Screen dragging always overrides camera animations.
		_camera_returning = false
		_map_camera_flying = false
		diagnostics.write("camera_return_interrupted", {"reason": "screen_drag"})
	if _camera_following:
		_camera_following = false
		diagnostics.write("camera_unfollowed", {"ship_position": navigator.as_dictionary()})
	_camera_offset += world_delta
	starfield.set_camera_look(_camera_offset)
	far_plasma.set_camera_address(navigator.sector, navigator.local, _camera_offset)
	cosmic_region.set_camera_address(navigator.sector, navigator.local, _camera_offset)
	solar_system.set_camera_address(navigator.sector, navigator.local, _camera_offset)
	npc_traffic.set_camera_address(navigator.sector, navigator.local, _camera_offset)
	foreign_traffic.set_camera_address(navigator.sector, navigator.local, _camera_offset)
	asteroid_field.set_camera_address(navigator.sector, navigator.local, _camera_offset)
	asteroid_field.set_ship_world(Vector2(navigator.sector) * WorldAddress.SECTOR_SIZE + navigator.local)
	_update_black_hole_position()
	distant_events.advance_camera(world_delta)
	ship.position = get_viewport_rect().size * 0.5 - _camera_offset
	mini_map.set_camera_offset(_camera_offset)


func _finish_camera_drag() -> void:
	if _look_dragged:
		diagnostics.write("camera_drag_end", {
			"offset_x": snappedf(_camera_offset.x, 0.1),
			"offset_y": snappedf(_camera_offset.y, 0.1)
		})
	_look_dragged = false


func _start_camera_return(reason: String) -> void:
	if _camera_following or _camera_returning:
		return
	_map_camera_flying = false
	_return_reason = reason
	_return_start_offset = _camera_offset
	_return_ship_travel = Vector2.ZERO
	_return_elapsed = 0.0
	# Close objects return rapidly; larger pans have a little more travel time.
	# Both button and joystick use the same visible camera animation.
	var normalized_distance: float = sqrt(_camera_offset.length() / CAMERA_RETURN_DISTANCE_SCALE)
	_return_duration = clampf(
		CAMERA_RETURN_MIN_DURATION + normalized_distance * 0.24,
		CAMERA_RETURN_MIN_DURATION,
		CAMERA_RETURN_MAX_DURATION
	)
	_camera_returning = true
	diagnostics.write("camera_return_started", {
		"reason": reason,
		"distance_px": snappedf(_camera_offset.length(), 0.1),
		"duration_s": snappedf(_return_duration, 0.01)
	})


func _update_camera_return(delta: float, ship_displacement: Vector2) -> void:
	_return_elapsed += delta
	_return_ship_travel += ship_displacement
	var t: float = clampf(_return_elapsed / _return_duration, 0.0, 1.0)
	# Smoothstep: starts gently and arrives without an abrupt stop.
	var easing: float = t * t * (3.0 - 2.0 * t)
	# Interpolate from the camera's original WORLD position to the ship's
	# CURRENT world position. The destination keeps moving during the return.
	_camera_offset = (_return_start_offset - _return_ship_travel) * (1.0 - easing)
	if t >= 1.0:
		_camera_offset = Vector2.ZERO
		_camera_following = true
		_camera_returning = false
		diagnostics.write("camera_return_completed", {
			"reason": _return_reason,
			"position": navigator.as_dictionary()
		})


func _story_ensure_comic() -> void:
	if _comic_prologue == null:
		_comic_prologue = ComicPrologueScene.new()
		_comic_prologue.name = "MikoComicPage1CameraStory"
		add_child(_comic_prologue)
		_comic_prologue.comic_completed.connect(_story_on_first_page_finished)
		_comic_prologue.panels_completed.connect(_story_on_panels_finished)
		_comic_prologue.forward_requested.connect(_story_forward_flight)
		_comic_prologue.skipped.connect(_story_skip_to_free_world)


func _story_set_phase(beat: String) -> void:
	if beat not in ["m33_to_lentis", "m33_departed"]:
		_ch06_clear_nav_hint()
	_story_phase = beat
	if not StoryProgress.save_beat(beat):
		push_warning("Story beat is active but was not saved: " + beat)


func _start_story_comic() -> void:
	_story_stop_navigation_guide()
	_story_ensure_comic()
	_story_set_phase("first_page")
	_story_simulator_required = false
	_intro_comic_playing = true
	_intro_space_flying = false
	_intro_time = 0.0
	velocity = Vector2.ZERO
	current_input = Vector2.ZERO
	joystick.clear_input()
	if _autopilot_active:
		_stop_autopilot("intro_replayed")
	_gameplay_hud.visible = false
	ship.visible = true
	ship.scale = Vector2.ONE
	ship.modulate = Color.WHITE
	_set_music_context("silent", true)
	_comic_prologue.begin()
	get_tree().paused = true
	diagnostics.write("prologue_comic_started", {"scene": "existing_71_second_page_one", "checkpoint": "first_page"})


func _story_on_first_page_finished() -> void:
	if _story_phase != "first_page":
		return
	_story_show_panels("wormhole_panel", ["wormhole"])


func _story_show_panels(beat: String, panel_ids: Array) -> void:
	_story_ensure_comic()
	_story_set_phase(beat)
	_story_simulator_required = false
	_intro_space_flying = false
	_intro_comic_playing = true
	_gameplay_hud.visible = false
	_comic_prologue.show_panels(panel_ids)
	get_tree().paused = true
	_set_music_context("silent", true)


func _story_on_panels_finished() -> void:
	match _story_phase:
		"crossroads_ending2_panels":
			_ch08_open_draw(true)
		"crossroads_ending1_panels":
			_ch08_open_completion(null, false)
		"crossroads_finale_panels":
			_ch07_open_choice()
		"m33_station_arrived":
			_ch06_open_gate_rebus()
		"m33_gate_exit_panels":
			_ch06_gate_transfer()
		"m33_intro_panels":
			_ch06_finish_intro()
		"m33_lentis_panels":
			_ch06_show_hub("math")
		"m33_after_math_panels":
			_ch06_show_hub("launch")
		"wormhole_panel":
			_begin_story_space_flight()
		"earth_view_panels":
			_story_offer_simulator()
		"earth_landing_panels":
			_story_show_earth_hub("puzzle")
		"earth_after_puzzle_panels":
			_story_show_earth_hub("launch")
		"earth_departure_panels":
			# The last two shots play BEFORE the real Godot takeoff animation.
			_comic_prologue.finish()
			_intro_comic_playing = false
			_gameplay_hud.show()
			_on_planet_hub_flight_requested()
		"mars_arrival_panels":
			_story_show_mars_hub("trace")
		"mars_story_after_word_panels":
			_story_show_mars_hub("launch")
		"mars_departure_panels":
			# The final two panels of page six play after the real Hub Launch tap.
			_comic_prologue.finish()
			_intro_comic_playing = false
			_gameplay_hud.show()
			_on_planet_hub_flight_requested()
		"station_arrival_panels":
			_story_show_station_hub("list")
		"talos_arrival_panels":
			_story_show_talos_hub("maze")
		"talos_departure_panel":
			# The final PDF 2-2 frame plays only AFTER real Hub Launch.
			_comic_prologue.finish()
			_intro_comic_playing = false
			_gameplay_hud.show()
			_on_planet_hub_flight_requested()
		"molly_arrival_panels":
			_story_show_molly_hub("tree")
		"molly_final_panel":
			# Cargo collection is the FINAL original panel of PDF 2-3.
			# After it ends, return to the real Hub with only Launch available.
			_story_show_molly_hub("launch")
		"lmc_station_arrival_panels":
			# All nine original PDF 2-4 shots play before the refuelling game.
			_story_show_lmc_station_hub("sunbeam")
		"smc_intro_panels":
			_story_finish_smc_arrival_intro()
		"okea_arrival_panels":
			_story_show_okea_hub("lab")
		"okea_after_lab_panels":
			_story_show_okea_hub("launch")
		"okea_departure_panel":
			# Original last PDF 3-1 image plays after the real Hub Launch
			# and before the existing native ship takeoff animation.
			_comic_prologue.finish()
			_intro_comic_playing = false
			_gameplay_hud.show()
			_on_planet_hub_flight_requested()
		"cela_arrival_panels":
			_story_show_cela_hub("crystals")
		"cela_after_crystals_panels":
			_story_show_panels("cela_bubble_panels", ["p33_cela_bubble", "p33_mika_encounter", "p33_lotus_flower"])
		"cela_bubble_panels":
			_story_show_cela_hub("launch")
		"lotus_arrival_panels":
			_story_show_lotus_hub("molecule")
		"lotus_after_molecule_panels":
			# The ship image now follows the prince BEFORE returning to the Hub.
			_story_show_lotus_hub("launch")
		"lotus_departure_panel":
			# Legacy checkpoint from v4.8: already-playing last panel may finish.
			_story_begin_barnard_map_hint()
		"barnard_prearrival_panels":
			_story_barnard_resume_warp_after_comic()
		"barnard_threat_panels":
			_story_barnard_begin_pirate_escort()
		"barnard_station_panels":
			_story_show_barnard_station_hub("pizza")
		"barnard_escape_panel":
			_story_show_barnard_station_hub("launch")
		"archeon_arrival_panels":
			_story_show_archeon_hub("fossils")
		"archeon_after_fossils_panels":
			_story_show_archeon_hub("launch")
		"archeon_departure_panels":
			# The target and native ship image play AFTER Hub Launch, before
			# the existing world-space takeoff tween and navigation guidance.
			_comic_prologue.finish()
			_intro_comic_playing = false
			_gameplay_hud.show()
			_on_planet_hub_flight_requested()
		"runa_arrival_panels":
			_story_show_runa_hub("evolution")
		"runa_after_evolution_panels":
			_story_show_runa_hub("launch")
		"m31_opening_panels":
			_story_begin_andromeda_drift()
		"m31_gravity_reveal":
			_story_begin_andromeda_pull()
		"m31_near_planet_panels":
			# The red world is already close. Return to REAL flight and let
			# the native ship complete its final approach and descent.
			_story_resume_andromeda_final_approach()
		"m31_landing_reactions":
			_story_show_panels("m31_before_pinball", [
				"p52_mika_earpiece", "p52_magnetic_hall",
				"p52_mika_meets_magnetic", "p52_portal_discovery"
			])
		"m31_before_pinball":
			# The fourth PDF 5-2 frame now leads to the NATIVE Hub / Pinball.
			_story_show_m31_hub("pinball")
		"m31_after_pinball_panels":
			# The two reserved PDF 5-2 frames conclude before native Launch.
			_story_show_m31_hub("launch")
		"m31_station_intro_panels":
			_story_show_m31_station_hub("ball")
		"m31_station_after_ball_panels":
			_story_show_m31_station_hub("pulses")
		"m31_station_after_pulses_panels":
			_story_show_m31_station_hub("station_launch")
		"station_final_panel":
			# Resume the REAL shared NPC-style warp only after PDF 7's final
			# window shot. The LMC world is not loaded before this moment.
			_comic_prologue.finish()
			_intro_comic_playing = false
			_gameplay_hud.hide()
			get_tree().paused = false
			_warp_phase = "transit"
			_warp_time = 0.0


func _story_show_earth_view_panels() -> void:
	ship.throttle = 0.0
	_story_show_panels("earth_view_panels", ["earth_view", "simulator"])


func _story_forward_flight() -> void:
	if _story_phase != "flight_to_earth":
		return
	_story_move_to(StoryArcadeFlight.earth_hold_position(solar_system.earth_world_position()))
	_intro_time = StoryArcadeFlight.TOTAL_SECONDS
	_story_restore_black_hole()
	_story_show_earth_view_panels()


func _story_offer_simulator() -> void:
	_story_set_phase("await_simulator_card")
	_story_simulator_required = true
	_intro_comic_playing = false
	_intro_space_flying = false
	_story_ensure_comic()
	_comic_prologue.finish()
	_gameplay_hud.visible = true
	# This is the REAL flight HUD, with all the original controls and the exact
	# same simulator portrait card as the empty-fuel flow.
	_story_set_flight_controls_visible(true)
	ship.visible = true
	ship.scale = Vector2.ONE
	ship.modulate = Color.WHITE
	ship.throttle = 0.0
	velocity = Vector2.ZERO
	current_input = Vector2.ZERO
	joystick.clear_input()
	_story_move_to(StoryArcadeFlight.earth_hold_position(solar_system.earth_world_position()))
	get_tree().paused = false
	# Real flight HUD, but it is a backdrop for the required simulator card.
	# Start flight music only after the simulator returns to playable space.
	_set_music_context("silent", true)
	diagnostics.write("story_simulator_card_required", {"same_as_empty_fuel": true})


func _on_story_simulator_card_requested() -> void:
	if _story_phase != "await_simulator_card":
		_on_main_menu_requested()
		return
	_story_set_phase("inside_simulator")
	_story_simulator_required = false
	_story_set_flight_controls_visible(true)
	StoryProgress.complete_arc("prologue")
	diagnostics.write("story_simulator_entered", {})
	_on_main_menu_requested()


func _story_after_simulator() -> void:
	_story_begin_navigation_guide("navigation_open")


func _story_navigation_guide_active() -> bool:
	return ["navigation_open", "navigation_earth", "earth_departed", "mars_navigation_open", "mars_navigation_target", "mars_navigation_selected", "mars_asteroid_approach", "mars_asteroid_stun", "mars_fuel_collect", "mars_fuel_absorbing", "mars_navigation_resume"].has(_story_phase)


func _story_stop_navigation_guide() -> void:
	_ch06_clear_nav_hint()
	if is_instance_valid(_story_navigation_blocker):
		_story_navigation_blocker.hide()
	if is_instance_valid(goal_picker):
		goal_picker.set_story_navigation_guide("")
		goal_picker.z_index = 0
		if _story_navigation_picker_restore_index >= 0:
			# Restore the original HUD stacking order after the lesson.
			goal_picker.get_parent().move_child(goal_picker, _story_navigation_picker_restore_index)
	_story_navigation_picker_restore_index = -1


func _story_begin_navigation_guide(beat: String) -> void:
	# Same native space, ship, mini-map, fuel bar and existing catalogue.
	# Only user input is locked, and the existing navigation picker glows.
	_story_simulator_required = false
	_intro_comic_playing = false
	_intro_space_flying = false
	_story_set_phase(beat)
	_gameplay_hud.show()
	_story_set_flight_controls_visible(true)
	velocity = Vector2.ZERO
	current_input = Vector2.ZERO
	joystick.clear_input()
	ship.throttle = 0.0
	if _story_navigation_picker_restore_index < 0:
		_story_navigation_picker_restore_index = goal_picker.get_index()
	# GUI hit testing follows sibling order, not only CanvasItem.z_index.
	# Keep the existing picker AFTER the full-screen shield while teaching.
	goal_picker.get_parent().move_child(goal_picker, goal_picker.get_parent().get_child_count() - 1)
	goal_picker.z_index = 1001
	if is_instance_valid(_story_navigation_blocker):
		_story_navigation_blocker.show()
	var guide_step: String = "open"
	if beat == "navigation_earth":
		guide_step = "earth"
	elif beat == "mars_navigation_open":
		guide_step = "mars_open"
	elif beat == "mars_navigation_target":
		guide_step = "mars"
	goal_picker.set_story_navigation_guide(guide_step)
	get_tree().paused = false
	_set_music_context("flight")
	diagnostics.write("story_navigation_lesson", {"step": beat, "preserved_world": true})


func _story_refresh_local_route(catalog_open: bool = false, selected_target: String = "") -> bool:
	if not is_instance_valid(goal_picker) or not is_instance_valid(solar_system):
		return false
	var route: Dictionary = StoryProgress.local_story_route(_story_phase)
	if route.is_empty():
		_ch06_clear_nav_hint()
		return false
	if StoryProgress.read_mode() != "story" or str(route.get("region", "")) != solar_system.current_id:
		goal_picker.set_story_navigation_guide("")
		return false
	var guide: String = str(route.get("guide", ""))
	var destination: String = str(route.get("target", ""))
	# Preserve late-chapter behavior: do not prompt again while the autopilot
	# is already taking the child to the correct destination.
	if guide.begins_with("ch06_") or guide.begins_with("ch07_"):
		if selected_target.is_empty() and _autopilot_active and _autopilot_target == destination:
			goal_picker.set_story_navigation_guide("")
			return true
	if selected_target == destination and not selected_target.is_empty():
		goal_picker.set_story_navigation_guide(guide if bool(route.get("keep_selected", false)) else "")
	else:
		goal_picker.set_story_navigation_guide(guide if catalog_open else guide + "_open")
	return true


func _story_refresh_galaxy_route() -> void:
	if not is_instance_valid(galactic_map) or not is_instance_valid(solar_system):
		return
	var route: Dictionary = StoryProgress.galaxy_story_route(_story_phase)
	var target: String = ""
	if StoryProgress.read_mode() == "story" and str(route.get("region", "")) == solar_system.current_id:
		target = str(route.get("target", ""))
	var first_lesson: bool = target == "lmc"
	galactic_map.set_story_lmc_lesson(first_lesson)
	galactic_map.set_story_destination_hint("" if first_lesson else target)


func _story_navigation_catalog_opened() -> void:
	if _story_phase == "navigation_open":
		_story_set_phase("navigation_earth")
		goal_picker.set_story_navigation_guide("earth")
		diagnostics.write("story_navigation_catalog_opened", {"earth_only_enabled": true})
	elif _story_phase == "mars_navigation_open":
		_story_set_phase("mars_navigation_target")
		goal_picker.set_story_navigation_guide("mars")
		diagnostics.write("story_navigation_catalog_opened", {"mars_only_enabled": true})
	elif _story_refresh_local_route(true):
		diagnostics.write("story_navigation_catalog_opened", {"phase": _story_phase, "controls_locked": false})


func _story_update_mars_asteroid(delta: float) -> void:
	_story_mars_asteroid_elapsed += delta
	if _story_phase == "mars_navigation_selected" and _story_mars_asteroid_elapsed >= 0.65:
		_story_set_phase("mars_asteroid_approach")
		asteroid_field.spawn_story_mars_asteroid(_ship_world())
	elif _story_phase == "mars_asteroid_approach" and _story_mars_asteroid_elapsed >= 4.4:
		# Guarantee the lesson, even if a very short route moves the ship away.
		asteroid_field.force_story_mars_impact(_ship_world())


func _story_begin_mars_asteroid_stun() -> void:
	if _story_phase != "mars_asteroid_approach":
		return
	_story_set_phase("mars_asteroid_stun")
	_stop_autopilot("story_mars_asteroid")
	velocity = Vector2.ZERO
	current_input = Vector2.ZERO
	joystick.clear_input()
	if is_instance_valid(_story_navigation_blocker):
		_story_navigation_blocker.show()
	action_button.set_action_available(false)
	var initial_position: Vector2 = ship.position
	var initial_rotation: float = ship.rotation
	var shake: Tween = create_tween()
	shake.tween_property(ship, "rotation", initial_rotation + 0.27, 0.17).set_trans(Tween.TRANS_SINE)
	shake.parallel().tween_property(ship, "position", initial_position + Vector2(26.0, -14.0), 0.17)
	shake.tween_property(ship, "rotation", initial_rotation - 0.23, 0.18).set_trans(Tween.TRANS_SINE)
	shake.parallel().tween_property(ship, "position", initial_position + Vector2(-21.0, 16.0), 0.18)
	shake.tween_property(ship, "rotation", initial_rotation + 0.10, 0.18).set_trans(Tween.TRANS_SINE)
	shake.parallel().tween_property(ship, "position", initial_position + Vector2(10.0, -6.0), 0.18)
	shake.tween_property(ship, "rotation", initial_rotation, 0.24).set_trans(Tween.TRANS_SINE)
	shake.parallel().tween_property(ship, "position", initial_position, 0.24)
	shake.tween_callback(Callable(self, "_story_show_mars_fuel_hand"))


func _story_stop_mars_hand_pulse() -> void:
	if _story_mars_hand_pulse != null and _story_mars_hand_pulse.is_running():
		_story_mars_hand_pulse.kill()
	if is_instance_valid(action_button):
		action_button.modulate = Color.WHITE


func _story_show_mars_fuel_hand() -> void:
	if not ["mars_asteroid_stun", "mars_fuel_collect", "mars_fuel_absorbing"].has(_story_phase):
		return
	_story_set_phase("mars_fuel_collect")
	_fuel_units = STORY_MARS_COLLISION_FUEL
	_refresh_fuel_hud()
	status_hud.set_story_fuel_attention(true, true)
	velocity = Vector2.ZERO
	if is_instance_valid(_story_navigation_blocker):
		_story_navigation_blocker.show()
	action_button.set_action_mode("take")
	action_button.set_action_available(true)
	_story_stop_mars_hand_pulse()
	_story_mars_hand_pulse = create_tween().set_loops()
	_story_mars_hand_pulse.tween_property(action_button, "modulate", Color(0.42, 0.88, 1.0, 0.48), 0.48).set_trans(Tween.TRANS_SINE)
	_story_mars_hand_pulse.tween_property(action_button, "modulate", Color.WHITE, 0.48).set_trans(Tween.TRANS_SINE)
	diagnostics.write("story_mars_collect_tutorial", {"native_hand": true, "fuel": _fuel_units})


func _story_finish_mars_fuel_capture() -> void:
	# Native magnet and fragments keep animating during the entire capture.
	await get_tree().create_timer(1.15).timeout
	if _story_phase != "mars_fuel_absorbing" or StoryProgress.read_mode() != "story":
		return
	_fuel_units = FUEL_CAPACITY
	_refresh_fuel_hud()
	status_hud.set_story_fuel_attention(false)
	asteroid_field.clear_story_mars_objects()
	_story_stop_mars_hand_pulse()
	action_button.set_action_mode("use")
	action_button.set_action_available(false)
	_story_stop_navigation_guide()
	_story_set_phase("mars_navigation_resume")
	_on_target_selected("Mars")
	diagnostics.write("story_mars_fuel_refilled", {"fuel": _fuel_units, "autopilot_resumed": _autopilot_active})


func _story_set_flight_controls_visible(should_show: bool) -> void:
	for control in [joystick, action_button, goal_picker, status_hud]:
		if is_instance_valid(control):
			control.visible = should_show


func _story_resume() -> void:
	# Every Story entry, including a cold boot and a return from Free World,
	# must rebuild the REAL galaxy before showing the saved chapter's comic,
	# Hub or destination picker. Without this, Godot always starts the MW
	# scene while the story counter may already be on Archeon or Runa.
	var checkpoint_beat: String = StoryProgress.read_beat()
	_story_prepare_checkpoint_world(checkpoint_beat)
	_story_stop_mars_hand_pulse()
	_story_stop_navigation_guide()
	galactic_map.set_story_lmc_lesson(false)
	galactic_map.set_story_destination_hint("")
	if is_instance_valid(action_button):
		action_button.set_action_mode("use")
		action_button.set_action_available(false)
	if is_instance_valid(status_hud):
		status_hud.set_story_fuel_attention(false)
	if is_instance_valid(asteroid_field):
		asteroid_field.clear_story_mars_objects()
	match checkpoint_beat:
		"crossroads_ending2_panels":
			_ch08_play_ending_two()
		"crossroads_ending2_note":
			_ch08_open_draw(true)
		"crossroads_ending2_draw":
			_ch08_open_draw(false)
		"crossroads_ending2_returned":
			_ch08_return_to_lentis(true)
		"crossroads_ending1_panels":
			_ch08_play_ending_one()
		"crossroads_ending1_returned":
			_ch08_return_to_lentis()
		"crossroads_finale_panels":
			_ch07_play_panels()
		"crossroads_finale_choice":
			_ch07_open_choice()
		"first_page":
			_start_story_comic()
		"wormhole_panel":
			_story_show_panels("wormhole_panel", ["wormhole"])
		"flight_to_earth":
			_story_ensure_comic()
			_begin_story_space_flight()
		"earth_view_panels":
			_story_move_to(StoryArcadeFlight.earth_hold_position(solar_system.earth_world_position()))
			_story_show_earth_view_panels()
		"await_simulator_card", "inside_simulator":
			_story_offer_simulator()
		"after_simulator", "navigation_open":
			_story_begin_navigation_guide("navigation_open")
		"navigation_earth":
			_story_begin_navigation_guide("navigation_earth")
		"navigation_selected":
			# Selected Earth is a durable checkpoint, not a replacement scene.
			_story_set_phase("navigation_selected")
			_story_stop_navigation_guide()
			_gameplay_hud.show()
			get_tree().paused = false
			_set_music_context("flight")
			if solar_system.current_id == "mw":
				_on_target_selected("Earth")
		"earth_landing_panels":
			_planet_landing_active = true
			ship.visible = false
			_story_show_panels("earth_landing_panels", ["earth_approach", "earth_spaceport"])
		"earth_puzzle":
			_story_show_earth_hub("puzzle")
		"earth_after_puzzle_panels":
			_planet_landing_active = true
			ship.visible = false
			_story_show_panels("earth_after_puzzle_panels", ["p03_puzzle_reveal", "p03_mika_upset", "p03_ship_refuel"])
		"earth_launch":
			_story_show_earth_hub("launch")
		"earth_departure_panels":
			_fuel_units = STORY_MARS_LAUNCH_FUEL
			_refresh_fuel_hud()
			status_hud.set_story_fuel_attention(true)
			_planet_landing_active = true
			ship.visible = false
			_story_show_panels("earth_departure_panels", ["p03_earth_departure", "p03_mars_destination"])
		"earth_departed", "mars_navigation_open", "mars_navigation_target", "mars_navigation_selected", "mars_asteroid_approach":
			var navigation_beat: String = StoryProgress.read_beat()
			_fuel_units = STORY_MARS_LAUNCH_FUEL
			_refresh_fuel_hud()
			status_hud.set_story_fuel_attention(true)
			_story_stop_navigation_guide()
			_planet_landing_active = false
			_gameplay_hud.show()
			ship.visible = true
			ship.scale = Vector2.ONE
			_story_move_to(StoryArcadeFlight.earth_hold_position(solar_system.earth_world_position()))
			_story_begin_navigation_guide("mars_navigation_target" if ["mars_navigation_target", "mars_navigation_selected", "mars_asteroid_approach"].has(navigation_beat) else "mars_navigation_open")
			if ["mars_navigation_selected", "mars_asteroid_approach"].has(navigation_beat) and solar_system.current_id == "mw":
				_on_target_selected("Mars")
		"mars_asteroid_stun", "mars_fuel_collect", "mars_fuel_absorbing":
			_planet_landing_active = false
			_gameplay_hud.show()
			ship.visible = true
			ship.scale = Vector2.ONE
			_story_move_to(StoryArcadeFlight.earth_hold_position(solar_system.earth_world_position()))
			get_tree().paused = false
			asteroid_field.spawn_story_mars_crystals(_ship_world())
			_story_show_mars_fuel_hand()
		"mars_navigation_resume":
			_planet_landing_active = false
			_gameplay_hud.show()
			ship.visible = true
			ship.scale = Vector2.ONE
			_story_move_to(StoryArcadeFlight.earth_hold_position(solar_system.earth_world_position()))
			_fuel_units = FUEL_CAPACITY
			_refresh_fuel_hud()
			status_hud.set_story_fuel_attention(false)
			get_tree().paused = false
			_story_set_phase("mars_navigation_resume")
			_on_target_selected("Mars")
		"mars_arrived", "mars_arrival_panels":
			_planet_landing_active = true
			ship.visible = false
			_story_show_panels("mars_arrival_panels", ["p04_mars_landing", "p04_mika_walk", "p04_reception"])
		"mars_word_trace":
			_story_show_mars_hub("trace")
		"mars_word_done", "mars_story_after_word_panels":
			_story_show_mars_after_word()
		"mars_launch":
			_story_show_mars_hub("launch")
		"mars_departure_panels":
			_planet_landing_active = true
			ship.visible = false
			_story_show_mars_departure_panels()
		"mars_departed", "free_prologue_complete":
			_planet_landing_active = false
			_gameplay_hud.show()
			ship.visible = true
			ship.scale = Vector2.ONE
			var mars_departure_state: Dictionary = solar_system.get_target_state("Mars")
			if bool(mars_departure_state.get("valid", false)):
				_story_move_to(mars_departure_state["world"] + Vector2(float(mars_departure_state.get("arrival_radius", 200.0)) + 155.0, 0.0))
			_story_begin_free_prologue_flight()
		"station_arrival_panels":
			_planet_landing_active = true
			ship.visible = false
			_story_show_panels("station_arrival_panels", [
				"p07_station_hangar", "p07_mika_staff", "p07_mika_worried",
				"p07_professor_arrives", "p07_professor_talks", "p07_ship_repair"
			])
		"station_hub_list":
			_story_show_station_hub("list")
		"station_hub_launch":
			_story_show_station_hub("launch")
		"station_map_lmc", "station_warp_out":
			_story_begin_lmc_map_lesson()
		"station_final_panel":
			# The player may quit midway through PDF 7. Replay its last shot
			# while the real MW-to-LMC transit is still pending.
			_warp_active = true
			_warp_phase = "story_interlude"
			_warp_destination = "lmc"
			_warp_direction = Vector2(0.20, -0.14).normalized()
			_warp_overlay.clear_effect()
			ship.visible = false
			_story_show_panels("station_final_panel", ["p07_lmc_window"])
		"lmc_arrived":
			if solar_system.current_id != "lmc":
				_arrive_new_region("lmc", HyperjumpMotion.arrival_world(Vector2.RIGHT))
			_story_restore_after_lmc_jump()
		"talos_arrival_panels":
			_planet_landing_active = true
			ship.visible = false
			_story_show_talos_arrival_panels()
		"talos_hub_maze":
			_story_show_talos_hub("maze")
		"talos_hub_launch":
			_story_show_talos_hub("launch")
		"talos_departure_panel":
			_planet_landing_active = true
			ship.visible = false
			_story_show_panels("talos_departure_panel", ["p22_planet_departure"])
		"talos_departed":
			_story_set_phase("talos_departed")
			_gameplay_hud.show()
			ship.visible = true
			_story_set_flight_controls_visible(true)
			get_tree().paused = false
			if solar_system.current_id == "lmc":
				goal_picker.set_story_navigation_guide("molly_open")
		"molly_arrival_panels":
			_planet_landing_active = true
			ship.visible = false
			_story_show_molly_arrival_panels()
		"molly_hub_tree":
			_story_show_molly_hub("tree")
		"molly_final_panel":
			_planet_landing_active = true
			ship.visible = false
			_story_show_panels("molly_final_panel", ["p23_loading_ship"])
		"molly_hub_launch":
			_story_show_molly_hub("launch")
		"molly_departed":
			_story_set_phase("molly_departed")
			_gameplay_hud.show()
			ship.visible = true
			_story_set_flight_controls_visible(true)
			get_tree().paused = false
			if solar_system.current_id == "lmc":
				goal_picker.set_story_navigation_guide("station_open")
		"lmc_station_arrival_panels":
			_planet_landing_active = true
			ship.visible = false
			_story_show_lmc_station_arrival_panels()
		"lmc_station_hub_sunbeam":
			_story_show_lmc_station_hub("sunbeam")
		"lmc_station_hub_launch":
			_story_show_lmc_station_hub("launch")
		"lmc_station_departed", "lmc_station_map_smc", "lmc_station_warp_smc":
			# The post-launch map lesson has its own Chapter 2 checkpoint.
			_story_begin_smc_map_hint()
		"smc_arrived", "smc_intro_panels":
			if solar_system.current_id != "smc":
				_arrive_new_region("smc", HyperjumpMotion.arrival_world(Vector2.RIGHT))
			_story_arrive_smc()
		"okea_arrival_panels":
			if solar_system.current_id != "smc":
				_arrive_new_region("smc", HyperjumpMotion.arrival_world(Vector2.RIGHT))
			var okea: Dictionary = solar_system.get_target_state("smc_p01")
			if bool(okea.get("valid", false)):
				_story_move_to(okea["world"] + Vector2(float(okea.get("arrival_radius", 200.0)) + 110.0, 0.0))
			_planet_landing_active = true
			ship.visible = false
			_story_show_okea_arrival_panels()
		"okea_hub_lab":
			_story_show_okea_hub("lab")
		"okea_after_lab_panels":
			_planet_landing_active = true
			ship.visible = false
			_story_show_panels("okea_after_lab_panels", ["p31_okea_observes", "p31_okea_lizard_sad", "p31_okea_lizard_talks"])
		"okea_hub_launch":
			_story_show_okea_hub("launch")
		"okea_departure_panel":
			_planet_landing_active = true
			ship.visible = false
			_story_show_panels("okea_departure_panel", ["p31_okea_to_cela"])
		"okea_departed":
			_story_restore_after_okea_launch()
		"cela_arrival_panels":
			if solar_system.current_id != "smc":
				_arrive_new_region("smc", HyperjumpMotion.arrival_world(Vector2.RIGHT))
			var cela: Dictionary = solar_system.get_target_state("smc_p02")
			if bool(cela.get("valid", false)):
				_story_move_to(cela["world"] + Vector2(float(cela.get("arrival_radius", 200.0)) + 110.0, 0.0))
			_planet_landing_active = true
			ship.visible = false
			_story_show_cela_arrival_panels()
		"cela_hub_crystals":
			_story_show_cela_hub("crystals")
		"cela_after_crystals_panels":
			_planet_landing_active = true
			ship.visible = false
			_story_show_panels("cela_after_crystals_panels", ["p32_mika_surprised", "p32_professor_calls", "p32_lotus_route"])
		"cela_bubble_panels":
			_planet_landing_active = true
			ship.visible = false
			_story_show_panels("cela_bubble_panels", ["p33_cela_bubble", "p33_mika_encounter", "p33_lotus_flower"])
		"cela_hub_launch":
			_story_show_cela_hub("launch")
		"cela_departed":
			_story_restore_after_cela_launch()
		"lotus_arrival_panels":
			if solar_system.current_id != "smc":
				_arrive_new_region("smc", HyperjumpMotion.arrival_world(Vector2.RIGHT))
			var archive: Dictionary = solar_system.get_target_state("st_smc")
			if bool(archive.get("valid", false)):
				_story_move_to(archive["world"] + Vector2(float(archive.get("arrival_radius", 200.0)) + 110.0, 0.0))
			_planet_landing_active = true
			ship.visible = false
			_story_show_lotus_arrival_panels()
		"lotus_hub_molecule":
			_story_show_lotus_hub("molecule")
		"lotus_after_molecule_panels":
			_planet_landing_active = true
			ship.visible = false
			_story_show_panels("lotus_after_molecule_panels", ["p34_liquid_phase", "p34_crystal_phase", "p34_phase_cavern", "p34_new_hero", "p34_ship_departure"])
		"lotus_hub_launch":
			_story_show_lotus_hub("launch")
		"lotus_departure_panel":
			_story_show_panels("lotus_departure_panel", ["p34_ship_departure"])
		"lotus_map_barnard", "lotus_warp_barnard":
			_story_begin_barnard_map_hint()
		"barnard_arrived":
			if solar_system.current_id != "ngc6822":
				_arrive_new_region("ngc6822", HyperjumpMotion.arrival_world(Vector2.RIGHT))
			# Chapter 4 catalog replay starts with the jokes even when we are
			# already in Barnard; the real warp was completed in the main story.
			_story_show_panels("barnard_prearrival_panels", [
				"p41_professor_bath_walk", "p41_professor_bath_rest",
				"p41_phase_bath_surprise", "p41_pirate_ships"
			])
		"barnard_prearrival_panels":
			_story_show_panels("barnard_prearrival_panels", ["p41_professor_bath_walk", "p41_professor_bath_rest", "p41_phase_bath_surprise", "p41_pirate_ships"])
		"barnard_warp_resume", "barnard_pirate_intercept":
			_story_barnard_begin_interception()
		"barnard_threat_panels":
			_story_show_panels("barnard_threat_panels", ["p41_flagship_threat", "p42_pirates_capture"])
		"barnard_pirate_escort", "barnard_pirate_landing":
			_story_barnard_begin_pirate_escort()
		"barnard_station_panels":
			_story_show_panels("barnard_station_panels", ["p42_station_prison", "p42_lizard_interrogates", "p42_lizard_changes_mind", "p42_phase_in_cage"])
		"barnard_station_hub_pizza":
			_story_show_barnard_station_hub("pizza")
		"barnard_escape_panel":
			_story_show_panels("barnard_escape_panel", ["p42_run_to_ship"])
		"barnard_station_hub_launch":
			_story_show_barnard_station_hub("launch")
		"barnard_station_departed":
			_story_barnard_restore_flight()
		"archeon_arrival_panels":
			_planet_landing_active = true
			ship.visible = false
			_story_show_panels("archeon_arrival_panels", ["p43_cockpit_decision", "p43_ship_landing", "p43_scientist_meeting"])
		"archeon_hub_fossils":
			_story_show_archeon_hub("fossils")
		"archeon_after_fossils_panels":
			_story_show_panels("archeon_after_fossils_panels", ["p43_loading_fossils"])
		"archeon_hub_launch":
			_story_show_archeon_hub("launch")
		"archeon_departure_panels":
			_planet_landing_active = true
			ship.visible = false
			_story_show_panels("archeon_departure_panels", ["p43_next_target", "p43_space_departure"])
		"archeon_departed":
			_story_restore_after_archeon_launch()
		"runa_arrival_panels":
			_planet_landing_active = true
			ship.visible = false
			_story_show_panels("runa_arrival_panels", [
				"p44_professor_studies_fossil", "p44_professor_realization",
				"p44_dinosaur_dna", "p44_ancient_dinosaurs", "p44_ancient_meteorite",
				"p45_ruins_entrance", "p45_museum_walk", "p45_professor_handshake",
				"p45_evolution_display", "p45_white_evolution"
			])
		"runa_hub_evolution":
			_story_show_runa_hub("evolution")
		"runa_after_evolution_panels":
			_planet_landing_active = true
			ship.visible = false
			_story_show_panels("runa_after_evolution_panels", ["p45_scientists_farewell", "p45_shadow_of_origin"])
		"runa_hub_launch":
			_story_show_runa_hub("launch")
		"runa_departed", "runa_map_andromeda", "runa_warp_andromeda":
			_story_begin_andromeda_map_hint()
		"m31_arrived":
			_story_arrive_andromeda()
		"m31_landing_reactions":
			_planet_landing_active = true
			ship.visible = false
			_story_show_panels("m31_landing_reactions", [
				"p51_mika_frightened", "p51_lizard_frightened",
				"p51_pyramid_landing", "p51_magnetic_creatures"
			])
		"m31_hub_pinball", "m31_pinball_preview":
			_story_show_m31_hub("pinball")
		"m31_after_pinball_panels":
			_planet_landing_active = true
			ship.visible = false
			_story_show_panels("m31_after_pinball_panels", ["p52_mika_talks", "p52_ship_departure"])
		"m31_hub_launch":
			_story_show_m31_hub("launch")
		"m31_departed":
			_story_restore_after_m31_launch()
		"m31_station_intro_panels":
			_planet_landing_active = true
			ship.visible = false
			_story_show_panels("m31_station_intro_panels", ["p53_archive_hall", "p53_mika_console"])
		"m31_station_hub_ball":
			_story_show_m31_station_hub("ball")
		"m31_station_after_ball_panels":
			_planet_landing_active = true
			ship.visible = false
			_story_show_m31_after_ball()
		"m31_station_hub_pulses":
			_story_show_m31_station_hub("pulses")
		"m31_station_after_pulses_panels":
			_planet_landing_active = true
			ship.visible = false
			_story_show_panels("m31_station_after_pulses_panels", ["p54_black_hole", "p54_mika_farewell", "p54_ship_departure"])
		"m31_station_hub_launch":
			_story_show_m31_station_hub("station_launch")
		"m31_station_departed", "m31_map_triangulum", "m31_warp_triangulum":
			_story_begin_triangulum_map_hint()
		"m33_arrived", "m33_intro_panels":
			_story_show_panels("m33_intro_panels", CH06_INTRO)
		"m33_story_preview", "m33_to_lentis":
			_ch06_restore_flight("m33_to_lentis")
		"m33_lentis_panels":
			_planet_landing_active = true
			ship.visible = false
			_story_show_panels("m33_lentis_panels", CH06_BEFORE_MATH)
		"m33_hub_math":
			_ch06_show_hub("math")
		"m33_after_math_panels":
			_planet_landing_active = true
			ship.visible = false
			_story_show_panels("m33_after_math_panels", CH06_AFTER_MATH)
		"m33_hub_launch":
			_ch06_show_hub("launch")
		"m33_departed":
			_ch06_restore_flight("m33_departed")
		"m33_station_arrived":
			_ch06_start_gate_comic()
		"m33_gate_rebus":
			_ch06_open_gate_rebus()
		"m33_gate_exit_panels":
			_planet_landing_active = true
			_story_show_panels("m33_gate_exit_panels", CH06_GATE_AFTER_REBUS)
		"m33_gate_transfer":
			_ch06_gate_transfer()
		"m33_crossroads_arrived":
			_ch06_enter_crossroads()
		_:
			_start_story_comic()


func _story_show_earth_hub(stage: String) -> void:
	# Reuse the real Earth Planet Hub; only its available actions change.
	_story_ensure_comic()
	_comic_prologue.finish()
	_intro_comic_playing = false
	_intro_space_flying = false
	_story_simulator_required = false
	_story_set_phase("earth_launch" if stage == "launch" else "earth_puzzle")
	_planet_landing_active = true
	_gameplay_hud.show()
	ship.visible = false
	var hub: Control = _ensure_planet_hub()
	if hub == null:
		push_error("Story: existing Planet Hub could not be loaded")
		return
	hub.size = get_viewport_rect().size
	hub.call("show_for_planet", "mw_p01", "Земля", floori(_fuel_units + 0.001))
	hub.call("set_story_earth_stage", stage)
	_set_music_context("calm")
	get_tree().paused = true
	diagnostics.write("story_earth_hub_lesson", {"stage": stage, "native_hub": true})


func _story_show_mars_hub(stage: String) -> void:
	# Native Planet Hub, exactly as on Earth. Only the single Story card is active.
	_story_ensure_comic()
	_comic_prologue.finish()
	_intro_comic_playing = false
	_intro_space_flying = false
	_story_simulator_required = false
	var beat: String = "mars_word_trace"
	if stage == "trace_done":
		beat = "mars_word_done"
	elif stage == "launch":
		beat = "mars_launch"
	_story_set_phase(beat)
	_planet_landing_active = true
	_gameplay_hud.show()
	ship.visible = false
	var hub: Control = _ensure_planet_hub()
	if hub == null:
		push_error("Story: existing Mars Planet Hub could not be loaded")
		return
	hub.size = get_viewport_rect().size
	var mars_names: Dictionary = {"ru": "Марс", "en": "Mars", "fr": "Mars", "de": "Mars", "es": "Marte", "pt_BR": "Marte"}
	hub.call("show_for_planet", "mw_p02", str(mars_names.get(str(MobileLocale.language), "Mars")), floori(_fuel_units + 0.001))
	hub.call("set_story_mars_stage", stage)
	get_tree().paused = true
	_set_music_context("silent", true)
	diagnostics.write("story_mars_word_lesson", {"stage": stage, "native_hub": true})


func _story_show_station_hub(stage: String) -> void:
	# The SAME real Planet Hub as Free World, not a copied station scene.
	_story_ensure_comic()
	_comic_prologue.finish()
	_intro_comic_playing = false
	_intro_space_flying = false
	_story_simulator_required = false
	_story_set_phase("station_hub_launch" if stage == "launch" else "station_hub_list")
	_planet_landing_active = true
	_gameplay_hud.show()
	ship.visible = false
	var hub: Control = _ensure_planet_hub()
	if hub == null:
		push_error("Story station: cannot load the existing Planet Hub")
		return
	hub.size = get_viewport_rect().size
	var names: Dictionary = {
		"ru": "Космическая станция", "en": "Space Station", "fr": "Station spatiale",
		"de": "Raumstation", "es": "Estación espacial", "pt_BR": "Estação espacial"
	}
	hub.call("show_for_planet", "st_mw", str(names.get(str(MobileLocale.language), names["en"])), floori(_fuel_units + 0.001))
	hub.call("set_story_station_stage", stage)
	_set_music_context("calm")
	get_tree().paused = true
	diagnostics.write("story_station_hub_lesson", {"stage": stage, "native_hub": true})


func _story_show_talos_arrival_panels() -> void:
	# Original PDF 2-1 (five frames) + 2-2 (first two). Last shot reserved.
	_story_show_panels("talos_arrival_panels", [
		"p21_flight_cabin", "p21_professor_door", "p21_ocean_city",
		"p21_mika_enters", "p21_mika_meets_fungus",
		"p22_fungal_conversation", "p22_mika_calls_bubble"
	])


func _story_show_talos_hub(stage: String) -> void:
	# Keep the real, unchanged Planet Hub with precisely one Fungal Paths card.
	_story_ensure_comic()
	_comic_prologue.finish()
	_intro_comic_playing = false
	_intro_space_flying = false
	_story_set_phase("talos_hub_launch" if stage == "launch" else "talos_hub_maze")
	_planet_landing_active = true
	_gameplay_hud.show()
	ship.visible = false
	var hub: Control = _ensure_planet_hub()
	if hub == null:
		push_error("Talos Story: existing Planet Hub missing")
		return
	hub.size = get_viewport_rect().size
	var planet_meta: Dictionary = solar_system.get_system("lmc")
	var displayed_name: String = "Талос"
	for item in planet_meta.get("planets", []):
		if str(item.get("id", "")) == "lmc_p02":
			displayed_name = str(item.get("name_ru", displayed_name))
			break
	hub.call("show_for_planet", "lmc_p02", displayed_name, floori(_fuel_units + 0.001))
	hub.call("set_story_talos_stage", stage)
	_set_music_context("calm")
	get_tree().paused = true
	diagnostics.write("story_talos_hub", {"stage": stage, "original_hub": true, "game": "lmc__fungal_paths"})


func _story_talos_maze_solved() -> void:
	if _story_phase != "talos_hub_maze" or StoryProgress.read_mode() != "story":
		return
	_story_show_talos_hub("launch")
	diagnostics.write("story_talos_maze_solved", {"next": "real_launch"})


func _story_show_molly_arrival_panels() -> void:
	# Four original pictures from PDF 2-3. The cargo-loading last picture
	# belongs AFTER the child successfully grows the tree in the real game.
	_story_show_panels("molly_arrival_panels", [
		"p23_molly_orbit", "p23_ruins_meeting",
		"p23_mika_talks", "p23_plant_tutorial"
	])


func _story_show_molly_hub(stage: String) -> void:
	# Use the real planet Hub and real Grow Little Tree game; Story only
	# changes which actions are enabled during this mandatory episode.
	_story_ensure_comic()
	_comic_prologue.finish()
	_intro_comic_playing = false
	_intro_space_flying = false
	_story_simulator_required = false
	_story_set_phase("molly_hub_launch" if stage == "launch" else "molly_hub_tree")
	_planet_landing_active = true
	_gameplay_hud.show()
	ship.visible = false
	var hub: Control = _ensure_planet_hub()
	if hub == null:
		push_error("Molly Story: original Planet Hub is unavailable")
		return
	hub.size = get_viewport_rect().size
	var names: Dictionary = {
		"ru": "Молли", "en": "Molly", "fr": "Molly",
		"de": "Molly", "es": "Molly", "pt_BR": "Molly"
	}
	hub.call("show_for_planet", "lmc_p03", str(names.get(str(MobileLocale.language), "Molly")), floori(_fuel_units + 0.001))
	hub.call("set_story_molly_stage", stage)
	_set_music_context("calm")
	get_tree().paused = true
	diagnostics.write("story_molly_hub", {"stage": stage, "native_hub": true, "game": "lmc__fungal_race"})


func _story_molly_tree_solved() -> void:
	if _story_phase != "molly_hub_tree" or StoryProgress.read_mode() != "story":
		return
	if is_instance_valid(_planet_hub):
		_planet_hub.visible = false
	_story_show_panels("molly_final_panel", ["p23_loading_ship"])
	diagnostics.write("story_molly_tree_solved", {"next": "cargo_panel_then_real_hub_launch"})


func _story_show_lmc_station_arrival_panels() -> void:
	# One original image from PDF 2-4; its nine panels run sequentially.
	_story_show_panels("lmc_station_arrival_panels", [
		"p24_station_exterior", "p24_fungal_garden", "p24_factory",
		"p24_reclaimed_city", "p24_fungus_portrait", "p24_meteor",
		"p24_mycelium_net", "p24_mika_smiles", "p24_professor_and_fungus"
	])


func _story_show_lmc_station_hub(stage: String) -> void:
	# The SAME station Hub, temporarily narrowed to one existing minigame.
	_story_ensure_comic()
	_comic_prologue.finish()
	_intro_comic_playing = false
	_intro_space_flying = false
	_story_simulator_required = false
	_story_set_phase("lmc_station_hub_launch" if stage == "launch" else "lmc_station_hub_sunbeam")
	_planet_landing_active = true
	_gameplay_hud.show()
	ship.visible = false
	var hub: Control = _ensure_planet_hub()
	if hub == null:
		push_error("LMC station Story: original Planet Hub is unavailable")
		return
	hub.size = get_viewport_rect().size
	var station_names: Dictionary = {
		"ru": "Лаборатория «Тарантул»", "en": "Tarantula Laboratory",
		"fr": "Laboratoire Tarentule", "de": "Tarantula-Labor",
		"es": "Laboratorio Tarántula", "pt_BR": "Laboratório Tarântula"
	}
	hub.call("show_for_planet", "st_lmc", str(station_names.get(str(MobileLocale.language), station_names["en"])), floori(_fuel_units + 0.001))
	hub.call("set_story_lmc_station_stage", stage)
	_set_music_context("calm")
	get_tree().paused = true
	diagnostics.write("story_lmc_station_hub", {"stage": stage, "native_hub": true, "game": "lmc__sunbeam_catcher"})


func _story_lmc_station_sunbeam_solved() -> void:
	if _story_phase != "lmc_station_hub_sunbeam" or StoryProgress.read_mode() != "story":
		return
	# A full native Sunbeam bio-battery equals a full ship tank, but only
	# this mandatory chapter visit transfers it into the real flight HUD.
	_fuel_units = FUEL_CAPACITY
	_refresh_fuel_hud()
	_story_show_lmc_station_hub("launch")
	diagnostics.write("story_lmc_station_refuelled", {"fuel": _fuel_units, "next": "real_launch_then_smc_map"})


func _story_station_list_solved() -> void:
	if _story_phase != "station_hub_list" or StoryProgress.read_mode() != "story":
		return
	_story_show_station_hub("launch")
	diagnostics.write("story_station_shopping_list_solved", {"next": "station_hub_launch"})


func _story_set_lmc_control_lock(locked: bool) -> void:
	# Preserve all familiar flight instruments while making their input inert.
	# Hiding them made the scene look like a different, empty game mode.
	if is_instance_valid(joystick):
		joystick.set_process_input(not locked)
		joystick.clear_input()
		if locked:
			joystick.show()
		joystick.modulate = Color(0.60, 0.72, 0.86, 0.60) if locked else Color.WHITE
	if is_instance_valid(goal_picker):
		if locked:
			goal_picker.show()
		goal_picker.set_story_input_locked(locked)
	if is_instance_valid(mini_map):
		if locked:
			mini_map.show()
		mini_map.mouse_filter = Control.MOUSE_FILTER_IGNORE if locked else Control.MOUSE_FILTER_STOP
		mini_map.modulate = Color(0.70, 0.80, 0.94, 0.68) if locked else Color.WHITE
	if is_instance_valid(action_button):
		if locked:
			action_button.show()
			action_button.set_action_available(false)
		action_button.modulate = Color(0.60, 0.72, 0.86, 0.60) if locked else Color.WHITE


func _story_begin_lmc_map_lesson() -> void:
	# Only the existing upper-right hyperspace button remains usable.
	_story_stop_navigation_guide()
	_story_set_phase("station_map_lmc")
	StoryProgress.unlock_region("lmc")
	if solar_system.current_id == "mw":
		var station: Dictionary = solar_system.get_target_state("st_mw")
		if bool(station.get("valid", false)) and _ship_world().distance_to(station["world"]) > 600.0:
			_story_move_to(station["world"] + Vector2(255.0, -170.0))
	_planet_landing_active = false
	_intro_comic_playing = false
	_intro_space_flying = false
	_gameplay_hud.show()
	status_hud.show()
	ship.visible = true
	ship.scale = Vector2.ONE
	ship.throttle = 0.0
	velocity = Vector2.ZERO
	current_input = Vector2.ZERO
	joystick.clear_input()
	_story_set_lmc_control_lock(true)
	auto_stop_button.hide()
	status_hud.set_story_galaxy_attention(true)
	galactic_map.set_story_lmc_lesson(true)
	if is_instance_valid(_bubble_popup):
		_bubble_popup.hide()
	get_tree().paused = false
	_set_music_context("flight")
	_layout()
	diagnostics.write("story_lmc_map_lesson", {"only": "lmc", "other_controls_locked": true})


func _story_restore_after_lmc_jump() -> void:
	_story_set_phase("lmc_arrived")
	_story_set_lmc_control_lock(false)
	_story_set_flight_controls_visible(true)
	status_hud.set_story_galaxy_attention(false)
	galactic_map.set_story_lmc_lesson(false)
	if solar_system.current_id == "lmc" and StoryProgress.read_mode() == "story":
		goal_picker.set_story_navigation_guide("talos_open")
	get_tree().paused = false
	_layout()


func _story_begin_smc_map_hint() -> void:
	# Chapter 2 ends with an OPTIONAL map hint. Unlike the first galaxy
	# tutorial, neither the joystick nor any ordinary flight button is locked.
	_story_stop_navigation_guide()
	_story_set_lmc_control_lock(false)
	_story_set_phase("lmc_station_map_smc")
	StoryProgress.unlock_region("smc")
	_planet_landing_active = false
	_intro_comic_playing = false
	_intro_space_flying = false
	_gameplay_hud.show()
	status_hud.show()
	ship.visible = true
	_story_set_flight_controls_visible(true)
	status_hud.set_story_galaxy_attention(true)
	galactic_map.set_story_lmc_lesson(false)
	galactic_map.set_story_destination_hint("smc")
	get_tree().paused = false
	_set_music_context("flight")
	_layout()
	diagnostics.write("story_smc_map_hint", {"destination": "smc", "other_flight_controls_locked": false})


func _story_arrive_smc() -> void:
	# Durable checkpoint is reached BEFORE its original two-panel intro,
	# so resuming Chapter 3 replays both frames from the beginning.
	_story_set_phase("smc_arrived")
	_story_set_lmc_control_lock(false)
	_story_set_flight_controls_visible(true)
	status_hud.set_story_galaxy_attention(false)
	galactic_map.set_story_lmc_lesson(false)
	galactic_map.set_story_destination_hint("")
	ship.visible = true
	goal_picker.set_story_navigation_guide("")
	_layout()
	_story_show_panels("smc_intro_panels", ["p31_professor_sandwich", "p31_fungus_and_professor"])
	diagnostics.write("story_chapter_three_begun", {"region": "smc", "checkpoint": "smc_arrived", "comic": "pdf_3_1_first_two"})


func _story_finish_smc_arrival_intro() -> void:
	if _story_phase != "smc_intro_panels" or StoryProgress.read_mode() != "story":
		return
	_comic_prologue.finish()
	_intro_comic_playing = false
	_story_set_phase("smc_arrived")
	_gameplay_hud.show()
	ship.visible = true
	ship.scale = Vector2.ONE
	_story_set_flight_controls_visible(true)
	goal_picker.set_story_navigation_guide("okea_open")
	get_tree().paused = false
	_set_music_context("flight")
	_layout()
	diagnostics.write("story_chapter_three_okea_hint", {"target": "smc_p01", "controls_locked": false})


func _story_show_okea_arrival_panels() -> void:
	# Native landing first, then the original second row of PDF 3-1.
	goal_picker.set_story_navigation_guide("")
	_story_show_panels("okea_arrival_panels", ["p31_okea_city", "p31_okea_meeting"])


func _story_show_okea_hub(stage: String) -> void:
	# Use the same live Planet Hub as every other inhabited planet.
	_story_ensure_comic()
	_comic_prologue.finish()
	_intro_comic_playing = false
	_intro_space_flying = false
	_story_simulator_required = false
	_story_set_phase("okea_hub_launch" if stage == "launch" else "okea_hub_lab")
	_planet_landing_active = true
	_gameplay_hud.show()
	ship.visible = false
	var hub: Control = _ensure_planet_hub()
	if hub == null:
		push_error("Okea Story: existing Planet Hub could not be loaded")
		return
	hub.size = get_viewport_rect().size
	var okea_name: String = "Окея" if str(MobileLocale.language) == "ru" else "Okea"
	hub.call("show_for_planet", "smc_p01", okea_name, floori(_fuel_units + 0.001))
	hub.call("set_story_okea_stage", stage)
	_set_music_context("calm")
	get_tree().paused = true
	diagnostics.write("story_okea_hub", {"stage": stage, "native_hub": true, "game": "smc__solutions_lab"})


func _story_okea_solutions_solved() -> void:
	if _story_phase != "okea_hub_lab" or StoryProgress.read_mode() != "story":
		return
	# Only three correct, different native Solution Lab recipes unblock the
	# rest of the PDF. The entire third row stays on its original sheet.
	if is_instance_valid(_planet_hub):
		_planet_hub.visible = false
	_story_show_panels("okea_after_lab_panels", [
		"p31_okea_observes", "p31_okea_lizard_sad", "p31_okea_lizard_talks"
	])
	diagnostics.write("story_okea_three_colors_completed", {"colors": 3, "next": "lizard_triptych"})


func _story_restore_after_okea_launch() -> void:
	_story_set_phase("okea_departed")
	_story_set_lmc_control_lock(false)
	_story_set_flight_controls_visible(true)
	_gameplay_hud.show()
	ship.visible = true
	ship.scale = Vector2.ONE
	_planet_landing_active = false
	goal_picker.set_story_navigation_guide("cela_open")
	get_tree().paused = false
	_set_music_context("flight")
	_layout()


func _story_show_cela_arrival_panels() -> void:
	# Start at the FIRST original PDF 3-2 panel only after native landing.
	goal_picker.set_story_navigation_guide("")
	_story_show_panels("cela_arrival_panels", ["p32_cela_temple", "p32_cela_cave", "p32_cela_crystals"])


func _story_show_cela_hub(stage: String) -> void:
	_story_ensure_comic()
	_comic_prologue.finish()
	_intro_comic_playing = false
	_intro_space_flying = false
	_story_simulator_required = false
	_story_set_phase("cela_hub_launch" if stage == "launch" else "cela_hub_crystals")
	_planet_landing_active = true
	_gameplay_hud.show()
	ship.visible = false
	var hub: Control = _ensure_planet_hub()
	if hub == null:
		push_error("Cela Story: existing Planet Hub could not be loaded")
		return
	hub.size = get_viewport_rect().size
	var cela_name: String = "Целе" if str(MobileLocale.language) == "ru" else "Cela"
	hub.call("show_for_planet", "smc_p02", cela_name, floori(_fuel_units + 0.001))
	hub.call("set_story_cela_stage", stage)
	_set_music_context("calm")
	get_tree().paused = true
	diagnostics.write("story_cela_hub", {"stage": stage, "native_hub": true, "game": "smc__resource_rush", "crystals_required": 5})


func _story_cela_crystals_solved() -> void:
	if _story_phase != "cela_hub_crystals" or StoryProgress.read_mode() != "story":
		return
	if is_instance_valid(_planet_hub):
		_planet_hub.visible = false
	_story_show_panels("cela_after_crystals_panels", ["p32_mika_surprised", "p32_professor_calls", "p32_lotus_route"])
	diagnostics.write("story_cela_five_crystals_completed", {"crystals": 5, "next": "pdf_3_2_last_three"})


func _story_restore_after_cela_launch() -> void:
	_story_set_phase("cela_departed")
	_story_set_lmc_control_lock(false)
	_story_set_flight_controls_visible(true)
	_gameplay_hud.show()
	ship.visible = true
	ship.scale = Vector2.ONE
	_planet_landing_active = false
	goal_picker.set_story_navigation_guide("lotus_open")
	get_tree().paused = false
	_set_music_context("flight")
	_layout()


func _story_show_lotus_arrival_panels() -> void:
	# The ORIGINAL wide LAST frame from PDF 3-3 is the station arrival.
	# Continue directly to the seated council FIRST frame of PDF 3-4.
	goal_picker.set_story_navigation_guide("")
	_story_show_panels("lotus_arrival_panels", ["p33_lotus_archive", "p34_lotus_council"])


func _story_show_lotus_hub(stage: String) -> void:
	_story_ensure_comic()
	_comic_prologue.finish()
	_intro_comic_playing = false
	_intro_space_flying = false
	_story_simulator_required = false
	_story_set_phase("lotus_hub_launch" if stage == "launch" else "lotus_hub_molecule")
	_planet_landing_active = true
	_gameplay_hud.show()
	ship.visible = false
	var hub: Control = _ensure_planet_hub()
	if hub == null:
		push_error("Lotus Story: existing Living Archive Planet Hub could not be loaded")
		return
	hub.size = get_viewport_rect().size
	var archive_name: String = "Живой архив" if str(MobileLocale.language) == "ru" else "Living Archive"
	hub.call("show_for_planet", "st_smc", archive_name, floori(_fuel_units + 0.001))
	hub.call("set_story_lotus_stage", stage)
	_set_music_context("calm")
	get_tree().paused = true
	diagnostics.write("story_lotus_hub", {"stage": stage, "native_hub": true, "game": "smc__build_molecule", "molecule": "H2O"})


func _story_lotus_water_solved() -> void:
	if _story_phase != "lotus_hub_molecule" or StoryProgress.read_mode() != "story":
		return
	if is_instance_valid(_planet_hub):
		_planet_hub.visible = false
	_story_show_panels("lotus_after_molecule_panels", [
		"p34_liquid_phase", "p34_crystal_phase", "p34_phase_cavern",
		"p34_new_hero", "p34_ship_departure"
	])
	diagnostics.write("story_lotus_water_completed", {"molecule": "H2O", "next": "pdf_3_4_2_through_6_then_hub"})


func _story_begin_barnard_map_hint() -> void:
	# Exactly as the post-Tarantula station lesson: NO movement restriction.
	_story_stop_navigation_guide()
	if is_instance_valid(_comic_prologue):
		_comic_prologue.finish()
	_story_set_lmc_control_lock(false)
	_story_set_phase("lotus_map_barnard")
	StoryProgress.unlock_region("ngc6822")
	_intro_comic_playing = false
	_intro_space_flying = false
	_planet_landing_active = false
	_gameplay_hud.show()
	status_hud.show()
	ship.visible = true
	ship.scale = Vector2.ONE
	_story_set_flight_controls_visible(true)
	status_hud.set_story_galaxy_attention(true)
	galactic_map.set_story_lmc_lesson(false)
	galactic_map.set_story_destination_hint("ngc6822")
	get_tree().paused = false
	_set_music_context("flight")
	_layout()
	diagnostics.write("story_barnard_map_hint", {"destination": "ngc6822", "controls_locked": false})


func _story_arrive_barnard() -> void:
	# Durable start of Chapter 4. The bath comedy already played DURING
	# hyperspace; now intercept Mika in the actual Barnard flight world.
	_story_set_phase("barnard_arrived")
	_story_set_lmc_control_lock(false)
	status_hud.set_story_galaxy_attention(false)
	galactic_map.set_story_lmc_lesson(false)
	galactic_map.set_story_destination_hint("")
	ship.visible = true
	ship.scale = Vector2.ONE
	get_tree().paused = false
	_set_music_context("flight")
	_layout()
	diagnostics.write("story_chapter_four_barnard_arrived", {"region": "ngc6822", "checkpoint": "barnard_arrived"})
	_story_barnard_begin_interception()


func _story_barnard_resume_warp_after_comic() -> void:
	# The first four PDF 4-1 panels are the interlude BETWEEN real NPC-style
	# warp departure and arrival. On chapter replay there is no active jump;
	# the already loaded Barnard galaxy hosts the scripted interception.
	_comic_prologue.finish()
	_intro_comic_playing = false
	get_tree().paused = false
	if _warp_active and _warp_destination == "ngc6822":
		_story_set_phase("barnard_warp_resume")
		_warp_phase = "transit"
		_warp_time = 0.0
	else:
		_story_arrive_barnard()


func _story_barnard_ensure_pirate_escort() -> Node2D:
	if is_instance_valid(_barnard_pirate_escort):
		return _barnard_pirate_escort
	_barnard_pirate_escort = StoryBarnardEscortScene.new() as Node2D
	_barnard_pirate_escort.name = "TwoRealBarnardPirateNPCs"
	add_child(_barnard_pirate_escort)
	_barnard_pirate_escort.connect("interception_completed", Callable(self, "_story_barnard_interception_completed"))
	return _barnard_pirate_escort


func _story_barnard_begin_interception() -> void:
	if StoryProgress.read_mode() != "story" or solar_system.current_id != "ngc6822":
		return
	_story_set_phase("barnard_pirate_intercept")
	_story_set_lmc_control_lock(false)
	_story_set_flight_controls_visible(false)
	_gameplay_hud.hide()
	velocity = Vector2.ZERO
	current_input = Vector2.ZERO
	joystick.clear_input()
	ship.visible = true
	ship.scale = Vector2.ONE
	ship.throttle = 0.0
	ship.position = get_viewport_rect().size * 0.5
	_story_barnard_ensure_pirate_escort().call("intercept", get_viewport_rect().size)
	get_tree().paused = false
	diagnostics.write("story_barnard_interception_started", {"npc_count": 2, "input_locked": true, "native_world": true})


func _story_barnard_interception_completed() -> void:
	if _story_phase != "barnard_pirate_intercept" or StoryProgress.read_mode() != "story":
		return
	if is_instance_valid(_barnard_pirate_escort):
		_barnard_pirate_escort.call("stop")
	# The giant dark flagship is a separate original PDF 4-1 panel, followed
	# by the frightened captives in PDF 4-2's first panel.
	_story_show_panels("barnard_threat_panels", ["p41_flagship_threat", "p42_pirates_capture"])


func _story_barnard_begin_pirate_escort() -> void:
	if solar_system.current_id != "ngc6822":
		_arrive_new_region("ngc6822", HyperjumpMotion.arrival_world(Vector2.RIGHT))
	if is_instance_valid(_comic_prologue):
		_comic_prologue.finish()
	_intro_comic_playing = false
	_story_set_phase("barnard_pirate_escort")
	_story_set_flight_controls_visible(false)
	_gameplay_hud.hide()
	velocity = Vector2.ZERO
	current_input = Vector2.ZERO
	joystick.clear_input()
	var station: Dictionary = solar_system.get_target_state("st_ngc6822")
	if not bool(station.get("valid", false)):
		push_error("Barnard Story: the native Titan Head pirate station is absent")
		return
	_barnard_escort_start = _ship_world()
	_barnard_escort_end = station["world"] + Vector2(float(station.get("arrival_radius", 190.0)) + 55.0, -55.0)
	_barnard_escort_time = 0.0
	_barnard_escort_duration = clampf(_barnard_escort_start.distance_to(_barnard_escort_end) / 200.0, 6.0, 11.5)
	_barnard_escort_speed = 0.0
	_barnard_landing_stage = "idle"
	var heading: Vector2 = (_barnard_escort_end - _barnard_escort_start).normalized()
	ship.visible = true
	ship.scale = Vector2.ONE
	ship.modulate.a = 1.0
	ship.throttle = 0.0
	_story_barnard_ensure_pirate_escort().call("escort", get_viewport_rect().size, heading, _ship_world(), station["world"])
	get_tree().paused = false
	_set_music_context("flight")
	diagnostics.write("story_barnard_escort_started", {"target": "st_ngc6822", "npc_count": 2, "input_locked": true, "forward_thrusters": true, "station_approach": true})


func _story_barnard_steer_player(delta: float, destination: Vector2, max_speed: float) -> bool:
	# Use the same acceleration / stopping-distance steering as the native
	# autopilot, but advance ONLY along the actual ship nose. This prevents
	# the lateral gliding caused by tweening world positions independently
	# of the ship's direction, and lets it turn before applying thrust.
	var here: Vector2 = _ship_world()
	var direction: Vector2 = destination - here
	var distance: float = direction.length()
	if distance < 16.0 and _barnard_escort_speed < 25.0:
		_barnard_escort_speed = 0.0
		ship.throttle = 0.0
		return true
	var target_heading: float = direction.angle() + PI * 0.5
	var angular_error: float = wrapf(target_heading - _ship_heading, -PI, PI)
	_ship_heading += clampf(angular_error, -2.9 * delta, 2.9 * delta)
	ship.rotation = _ship_heading
	var remaining_error: float = absf(wrapf(target_heading - _ship_heading, -PI, PI))
	var aligned: float = pow(maxf(0.0, cos(remaining_error)), 2.0)
	var desired_speed: float = minf(max_speed, sqrt(2.0 * AUTO_BRAKE_ACCEL * maxf(distance - 16.0, 0.0))) * aligned
	var acceleration: float = AUTO_STEERING_ACCEL if desired_speed >= _barnard_escort_speed else AUTO_BRAKE_ACCEL
	_barnard_escort_speed = move_toward(_barnard_escort_speed, desired_speed, acceleration * delta)
	var forward: Vector2 = Vector2.from_angle(_ship_heading - PI * 0.5)
	_story_move_to(here + forward * _barnard_escort_speed * delta)
	ship.throttle = clampf(_barnard_escort_speed / maxf(AUTO_CRUISE_SPEED, 1.0), 0.0, 0.85)
	return false


func _story_advance_barnard_escort(delta: float) -> void:
	var station: Dictionary = solar_system.get_target_state("st_ngc6822")
	if not bool(station.get("valid", false)):
		return
	_barnard_escort_end = station["world"] + Vector2(float(station.get("arrival_radius", 190.0)) + 55.0, -55.0)
	var reached: bool = _story_barnard_steer_player(delta, _barnard_escort_end, AUTO_CRUISE_SPEED * 0.9)
	if is_instance_valid(_barnard_pirate_escort):
		var forward: Vector2 = Vector2.from_angle(_ship_heading - PI * 0.5)
		_barnard_pirate_escort.call("update_escort", delta, get_viewport_rect().size, _ship_world(), station["world"], forward)
	if reached:
		_story_barnard_finish_pirate_landing()


func _story_barnard_finish_pirate_landing() -> void:
	if _story_phase != "barnard_pirate_escort":
		return
	_story_set_phase("barnard_pirate_landing")
	ship.throttle = 0.0
	_barnard_escort_speed = 0.0
	_barnard_landing_time = 0.0
	_barnard_landing_stage = "approach"
	_barnard_landing_npcs_docked = false
	if is_instance_valid(_barnard_pirate_escort):
		_barnard_pirate_escort.call("landing")
	diagnostics.write("story_barnard_station_approach", {"native_station": "st_ngc6822", "docking_slots": 3})


func _story_advance_barnard_landing(delta: float) -> void:
	var station: Dictionary = solar_system.get_target_state("st_ngc6822")
	if not bool(station.get("valid", false)):
		return
	var station_world: Vector2 = station["world"]
	if _barnard_landing_stage == "approach":
		if _story_barnard_steer_player(delta, station_world + Vector2(0.0, -18.0), 210.0):
			_barnard_landing_stage = "hover"
			_barnard_landing_time = 0.0
	elif _barnard_landing_stage == "hover":
		ship.throttle = 0.0
		_barnard_landing_time += delta
		if _barnard_landing_time >= 0.52:
			_barnard_landing_stage = "descent"
			_barnard_landing_time = 0.0
	elif _barnard_landing_stage == "descent":
		_barnard_landing_time += delta
		var descent: float = StoryLandingMotion.smooth_step(_barnard_landing_time / 1.12)
		ship.scale = Vector2.ONE * (1.0 - 0.80 * descent)
		ship.modulate.a = 1.0 - descent
	if is_instance_valid(_barnard_pirate_escort):
		_barnard_landing_npcs_docked = bool(_barnard_pirate_escort.call("update_landing", delta, get_viewport_rect().size, _ship_world(), station_world))
	if _barnard_landing_stage != "descent" or _barnard_landing_time < 1.12 or not _barnard_landing_npcs_docked:
		return
	if is_instance_valid(_barnard_pirate_escort):
		_barnard_pirate_escort.call("stop")
	ship.visible = false
	_story_show_panels("barnard_station_panels", [
		"p42_station_prison", "p42_lizard_interrogates",
		"p42_lizard_changes_mind", "p42_phase_in_cage"
	])


func _story_show_barnard_station_hub(stage: String) -> void:
	_story_ensure_comic()
	_comic_prologue.finish()
	_intro_comic_playing = false
	_intro_space_flying = false
	_story_set_phase("barnard_station_hub_launch" if stage == "launch" else "barnard_station_hub_pizza")
	_planet_landing_active = true
	_gameplay_hud.show()
	ship.visible = false
	var hub: Control = _ensure_planet_hub()
	if hub == null:
		push_error("Barnard Story: original Titan Head Planet Hub missing")
		return
	hub.size = get_viewport_rect().size
	var station_names: Dictionary = {
		"ru": "Пиратский порт «Голова Титана»", "en": "Titan Head Pirate Port",
		"fr": "Port pirate Tête du Titan", "de": "Piratenhafen Titanenkopf",
		"es": "Puerto pirata Cabeza de Titán", "pt_BR": "Porto Pirata Cabeça de Titã"
	}
	var station_name: String = str(station_names.get(str(MobileLocale.language), station_names["en"]))
	hub.call("show_for_planet", "st_ngc6822", station_name, floori(_fuel_units + 0.001))
	hub.call("set_story_barnard_stage", stage)
	_set_music_context("calm")
	get_tree().paused = true
	diagnostics.write("story_barnard_station_hub", {"native_hub": true, "stage": stage})


func _story_barnard_pizza_solved() -> void:
	if _story_phase != "barnard_station_hub_pizza" or StoryProgress.read_mode() != "story":
		return
	# The first fraction is solved in the EXISTING planet game. Resume
	# the original final PDF panel only after returning to the native Hub.
	if is_instance_valid(_planet_hub):
		_planet_hub.visible = false
	_story_show_panels("barnard_escape_panel", ["p42_run_to_ship"])
	diagnostics.write("story_barnard_pizza_solved", {"real_game": "ngc6822__pizza_fraction", "next": "escape_panel"})


func _story_barnard_restore_flight() -> void:
	_story_set_phase("barnard_station_departed")
	_story_set_lmc_control_lock(false)
	_story_set_flight_controls_visible(true)
	_gameplay_hud.show()
	status_hud.show()
	ship.visible = true
	ship.scale = Vector2.ONE
	_planet_landing_active = false
	get_tree().paused = false
	_set_music_context("flight")
	_layout()
	goal_picker.set_story_navigation_guide("archeon_open")
	diagnostics.write("story_barnard_pirate_escape_completed", {"system": "ngc6822", "target": "ngc6822_p01", "input_locked": false})


func _story_show_archeon_hub(stage: String) -> void:
	# The *existing* full-screen Planet Hub, not a replacement Story scene.
	_story_ensure_comic()
	_comic_prologue.finish()
	_intro_comic_playing = false
	_intro_space_flying = false
	_story_set_phase("archeon_hub_launch" if stage == "launch" else "archeon_hub_fossils")
	_planet_landing_active = true
	_gameplay_hud.show()
	ship.visible = false
	var hub: Control = _ensure_planet_hub()
	if hub == null:
		push_error("Archeon Story: native Planet Hub unavailable")
		return
	hub.size = get_viewport_rect().size
	var display_name: String = "Археон" if str(MobileLocale.language) == "ru" else "Archeon"
	hub.call("show_for_planet", "ngc6822_p01", display_name, floori(_fuel_units + 0.001))
	hub.call("set_story_archeon_stage", stage)
	_set_music_context("calm")
	get_tree().paused = true
	diagnostics.write("story_archeon_hub", {"native_hub": true, "stage": stage, "game": "ngc6822__fossil_search"})


func _story_archeon_fossils_solved() -> void:
	if _story_phase != "archeon_hub_fossils" or StoryProgress.read_mode() != "story":
		return
	if is_instance_valid(_planet_hub):
		_planet_hub.visible = false
	# Only the loading-crates original frame follows the three real fossils.
	_story_show_panels("archeon_after_fossils_panels", ["p43_loading_fossils"])
	diagnostics.write("story_archeon_fossils_completed", {"required": 3, "native_game": true})


func _story_restore_after_archeon_launch() -> void:
	_story_set_phase("archeon_departed")
	_story_set_lmc_control_lock(false)
	_story_set_flight_controls_visible(true)
	_intro_comic_playing = false
	_gameplay_hud.show()
	status_hud.show()
	ship.visible = true
	ship.scale = Vector2.ONE
	_planet_landing_active = false
	get_tree().paused = false
	_set_music_context("flight")
	_layout()
	goal_picker.set_story_navigation_guide("runa_open")


func _story_show_runa_hub(stage: String) -> void:
	# Native Planet Hub and native Evolution game. The story merely narrows the
	# available actions until the child completes the five real sequences.
	_story_ensure_comic()
	_comic_prologue.finish()
	_intro_comic_playing = false
	_intro_space_flying = false
	_story_set_phase("runa_hub_launch" if stage == "launch" else "runa_hub_evolution")
	_planet_landing_active = true
	_gameplay_hud.show()
	ship.visible = false
	var hub: Control = _ensure_planet_hub()
	if hub == null:
		push_error("Runa Story: native Planet Hub unavailable")
		return
	hub.size = get_viewport_rect().size
	var display_name: String = "Руна" if str(MobileLocale.language) == "ru" else "Runa"
	hub.call("show_for_planet", "ngc6822_p06", display_name, floori(_fuel_units + 0.001))
	hub.call("set_story_runa_stage", stage)
	_set_music_context("calm")
	get_tree().paused = true
	diagnostics.write("story_runa_hub", {"native_hub": true, "stage": stage, "game": "ngc6822__evolution_order"})


func _story_runa_evolution_solved() -> void:
	if _story_phase != "runa_hub_evolution" or StoryProgress.read_mode() != "story":
		return
	if is_instance_valid(_planet_hub):
		_planet_hub.visible = false
	_story_show_panels("runa_after_evolution_panels", ["p45_scientists_farewell", "p45_shadow_of_origin"])
	diagnostics.write("story_runa_evolution_completed", {"real_game": "ngc6822__evolution_order", "chains": 5})


func _story_show_m31_hub(stage: String) -> void:
	# The actual native Planet Hub over Phasis, not a stand-in game scene.
	_story_ensure_comic()
	_comic_prologue.finish()
	_intro_comic_playing = false
	_intro_space_flying = false
	_story_simulator_required = false
	_story_set_phase("m31_hub_launch" if stage == "launch" else "m31_hub_pinball")
	_planet_landing_active = true
	_gameplay_hud.show()
	ship.visible = false
	var hub: Control = _ensure_planet_hub()
	if hub == null:
		push_error("Andromeda Story: native Planet Hub unavailable")
		return
	hub.size = get_viewport_rect().size
	var name_for_player: String = "Фазис" if str(MobileLocale.language) == "ru" else "Phasis"
	hub.call("show_for_planet", M31_STORY_PLANET_ID, name_for_player, floori(_fuel_units + 0.001))
	hub.call("set_story_m31_stage", stage)
	_set_music_context("calm")
	get_tree().paused = true
	diagnostics.write("story_m31_hub", {"planet": M31_STORY_PLANET_ID, "stage": stage, "game": "m31__gravity_pinball"})


func _story_m31_pinball_solved() -> void:
	if _story_phase != "m31_hub_pinball" or StoryProgress.read_mode() != "story":
		return
	if is_instance_valid(_planet_hub):
		_planet_hub.visible = false
	_story_show_panels("m31_after_pinball_panels", ["p52_mika_talks", "p52_ship_departure"])
	diagnostics.write("story_m31_pinball_solved", {"points_required": 1, "next": "last_two_pdf_5_2"})


func _story_show_m31_station_hub(stage: String) -> void:
	# The native station Hub stays intact. Only Story cards are narrowed.
	_story_ensure_comic()
	_comic_prologue.finish()
	_intro_comic_playing = false
	_intro_space_flying = false
	_story_simulator_required = false
	var beat: String = "m31_station_hub_launch" if stage == "station_launch" else ("m31_station_hub_pulses" if stage == "pulses" else "m31_station_hub_ball")
	_story_set_phase(beat)
	_planet_landing_active = true
	_gameplay_hud.show()
	ship.visible = false
	var hub: Control = _ensure_planet_hub()
	if hub == null:
		push_error("Andromeda Story: original station Hub unavailable")
		return
	hub.size = get_viewport_rect().size
	hub.call("show_for_planet", "st_m31", "", floori(_fuel_units + 0.001))
	hub.call("set_story_m31_stage", stage)
	_set_music_context("calm")
	get_tree().paused = true
	diagnostics.write("story_m31_station_hub", {"stage": stage, "station": "st_m31"})


func _story_m31_ball_solved() -> void:
	if _story_phase != "m31_station_hub_ball" or StoryProgress.read_mode() != "story":
		return
	if is_instance_valid(_planet_hub):
		_planet_hub.visible = false
	_story_show_m31_after_ball()
	diagnostics.write("story_m31_ball_solved", {"required": "one_real_maze_completion"})


func _story_show_m31_after_ball() -> void:
	# Three remaining original 5-3 frames, followed by first three of 5-4.
	_story_show_panels("m31_station_after_ball_panels", [
		"p53_volcanic_city", "p53_evacuating_ships", "p53_gravity_anomaly",
		"p54_galaxy_network", "p54_species_meet", "p54_pulse_signal"
	])


func _story_m31_pulses_solved() -> void:
	if _story_phase != "m31_station_hub_pulses" or StoryProgress.read_mode() != "story":
		return
	if is_instance_valid(_planet_hub):
		_planet_hub.visible = false
	_story_show_panels("m31_station_after_pulses_panels", [
		"p54_black_hole", "p54_mika_farewell", "p54_ship_departure"
	])
	diagnostics.write("story_m31_pulse_solved", {"level": 1, "sequence_length": 2})


func _story_begin_triangulum_map_hint() -> void:
	# Chapter 6 is WIP; unlock/hint the REAL galaxy, do not substitute content.
	_story_stop_navigation_guide()
	_story_set_lmc_control_lock(false)
	_story_set_phase("m31_map_triangulum")
	if not StoryProgress.unlock_region("m33"):
		push_warning("Triangulum could not be persisted as unlocked")
	_planet_landing_active = false
	_intro_comic_playing = false
	_intro_space_flying = false
	_gameplay_hud.show()
	status_hud.show()
	ship.visible = true
	ship.scale = Vector2.ONE
	_story_set_flight_controls_visible(true)
	status_hud.set_story_galaxy_attention(true)
	galactic_map.set_story_lmc_lesson(false)
	galactic_map.set_story_destination_hint("m33")
	get_tree().paused = false
	_set_music_context("flight")
	_layout()
	diagnostics.write("story_m31_completed", {"next_galaxy": "m33", "chapter06": "in_development"})


func _story_arrive_triangulum_preview() -> void:
	_story_set_phase("m33_arrived")
	if not StoryProgress.complete_arc("chapter05"):
		push_warning("Could not persist Chapter 5 completion")
	_ch06_restore_flight("m33_to_lentis")


func _story_restore_after_m31_launch() -> void:
	# Restore ALL native flight controls only after the real takeoff finishes.
	_story_stop_navigation_guide()
	_story_set_lmc_control_lock(false)
	_story_set_phase("m31_departed")
	_planet_landing_active = false
	_intro_comic_playing = false
	_intro_space_flying = false
	_gameplay_hud.show()
	status_hud.show()
	ship.visible = true
	ship.scale = Vector2.ONE
	ship.modulate = Color.WHITE
	ship.throttle = 0.0
	_story_set_flight_controls_visible(true)
	status_hud.set_story_galaxy_attention(false)
	goal_picker.set_story_navigation_guide("station_open")
	get_tree().paused = false
	_set_music_context("flight")
	_layout()
	diagnostics.write("story_m31_launch_completed", {"galaxy": "m31", "destination": "st_m31", "controls_locked": false})


func _story_begin_andromeda_map_hint() -> void:
	# An invitation to Chapter 5, not a forced jump: flight stays playable and
	# the existing atlas/galactic fog controls the actual intergalactic warp.
	_story_stop_navigation_guide()
	_story_set_lmc_control_lock(false)
	_story_set_phase("runa_map_andromeda")
	StoryProgress.unlock_region("m31")
	_planet_landing_active = false
	_intro_comic_playing = false
	_intro_space_flying = false
	_gameplay_hud.show()
	status_hud.show()
	ship.visible = true
	ship.scale = Vector2.ONE
	_story_set_flight_controls_visible(true)
	status_hud.set_story_galaxy_attention(true)
	galactic_map.set_story_lmc_lesson(false)
	galactic_map.set_story_destination_hint("m31")
	get_tree().paused = false
	_set_music_context("flight")
	_layout()
	diagnostics.write("story_runa_completed", {"galaxy_hint": "m31", "unrestricted_flight": true, "next_chapter": 5})


func _story_arrive_andromeda() -> void:
	# Chapter 5 begins at the REAL hyperspace arrival. Free World is unchanged.
	_planet_landing_active = false
	_story_set_lmc_control_lock(false)
	status_hud.set_story_galaxy_attention(false)
	galactic_map.set_story_destination_hint("")
	ship.visible = true
	ship.scale = Vector2.ONE
	if StoryProgress.read_mode() != "story":
		_story_set_flight_controls_visible(true)
		_gameplay_hud.show()
		get_tree().paused = false
		_set_music_context("flight")
		return
	_story_set_phase("m31_arrived")
	# Reuse the existing PDF player and retain the actual M31 world below it.
	_story_show_panels("m31_opening_panels", ["p51_cabin_alarm"])
	diagnostics.write("story_chapter05_opening", {"galaxy": "m31", "preview": "part_A"})


func _story_begin_andromeda_drift() -> void:
	# The ship itself flies in the EXISTING galaxy, with no gameplay UI.
	_comic_prologue.finish()
	_intro_comic_playing = false
	_intro_space_flying = false
	_story_set_phase("m31_lost_drift")
	_story_set_flight_controls_visible(false)
	_gameplay_hud.hide()
	status_hud.hide()
	if _autopilot_active:
		_stop_autopilot("m31_cinematic")
	joystick.clear_input()
	current_input = Vector2.ZERO
	velocity = Vector2.ZERO
	_m31_flight_time = 0.0
	_m31_drift_heading = _ship_heading
	_m31_flight_velocity = Vector2.ZERO
	ship.visible = true
	ship.scale = Vector2.ONE
	ship.modulate = Color.WHITE
	get_tree().paused = false
	_set_music_context("silent", true)


func _story_begin_andromeda_pull() -> void:
	_comic_prologue.finish()
	_intro_comic_playing = false
	_story_set_phase("m31_gravity_pull")
	_m31_flight_time = 0.0
	_m31_flight_velocity = Vector2.from_angle(_ship_heading - PI * 0.5) * 90.0
	_gameplay_hud.hide()
	status_hud.hide()
	ship.visible = true
	get_tree().paused = false
	_set_music_context("silent", true)


func _story_resume_andromeda_final_approach() -> void:
	# A cinematic still is not a teleport: preserve the world-space position.
	_comic_prologue.finish()
	_intro_comic_playing = false
	_intro_space_flying = false
	_story_set_phase("m31_final_approach")
	_story_set_flight_controls_visible(false)
	_gameplay_hud.hide()
	status_hud.hide()
	_m31_flight_time = 0.0
	_m31_flight_velocity = Vector2.from_angle(_ship_heading - PI * 0.5) * 65.0
	ship.visible = true
	ship.scale = Vector2.ONE
	get_tree().paused = false
	_set_music_context("silent", true)


func _story_advance_andromeda_cinematic(delta: float) -> void:
	# This is a flight model, not a tween of screen positions. It updates the
	# same world/camera/asteroid/planet addresses as normal controlled flight.
	_m31_flight_time += delta
	if _story_phase == "m31_lost_drift":
		# Searching: gentle heading changes and throttle adjustments, no input.
		var wander: float = sin(_m31_flight_time * 0.63) * 0.44 + sin(_m31_flight_time * 1.27) * 0.20
		_ship_heading = lerp_angle(_ship_heading, _m31_drift_heading + wander, minf(1.0, delta * 1.20))
		var direction: Vector2 = Vector2.from_angle(_ship_heading - PI * 0.5)
		var desired_speed: float = 165.0 + 43.0 * sin(_m31_flight_time * 1.13)
		_m31_flight_velocity = _m31_flight_velocity.move_toward(direction * desired_speed, delta * 260.0)
		_story_move_to(_ship_world() + _m31_flight_velocity * delta)
		ship.rotation = _ship_heading
		ship.throttle = 0.45
		if _m31_flight_time >= 6.8:
			ship.throttle = 0.0
			# First the ship is lost in space. The separate RED planet shot
			# belongs later, once the live ship is physically close to it.
			_story_show_panels("m31_gravity_reveal", ["p51_ship_lost"])
		return
	if not ["m31_gravity_pull", "m31_final_approach"].has(_story_phase):
		return
	var target: Dictionary = solar_system.get_target_state(M31_STORY_PLANET_ID)
	if not bool(target.get("valid", false)):
		push_error("Andromeda story target missing: " + M31_STORY_PLANET_ID)
		return
	var center: Vector2 = target["world"]
	var offset: Vector2 = center - _ship_world()
	var distance: float = offset.length()
	var approach_radius: float = float(target.get("arrival_radius", 180.0)) + 56.0
	# A moving body must be captured BEFORE precision-limited braking can
	# asymptotically park the ship just outside the exact arrival radius.
	var capture_radius: float = approach_radius + M31_LANDING_CAPTURE_MARGIN
	# During the long gravitational pull the camera stays in the SAME real
	# galactic world. Only near the red planet is the original PDF insert shown.
	if _story_phase == "m31_gravity_pull" and distance <= maxf(M31_NEAR_PLANET_REVEAL_DISTANCE, approach_radius + 350.0):
		_story_set_phase("m31_near_planet_panels")
		_m31_flight_velocity = Vector2.ZERO
		ship.throttle = 0.0
		_story_show_panels("m31_near_planet_panels", ["p51_gravity_world"])
		return
	if distance <= capture_radius:
		_story_begin_andromeda_native_landing(distance)
		return
	# The pull gradually dominates the ship: acceleration, steering and a
	# braking envelope near the planet, with the nose aligned to the motion.
	var aim: Vector2 = offset / maxf(1.0, distance)
	var max_speed: float = 300.0 if _story_phase == "m31_final_approach" else 660.0
	var min_speed: float = 65.0 if _story_phase == "m31_final_approach" else 105.0
	var speed_limit: float = clampf((distance - capture_radius) * 0.72, min_speed, max_speed)
	_m31_flight_velocity = _m31_flight_velocity.move_toward(aim * speed_limit, delta * 420.0)
	var step: Vector2 = _m31_flight_velocity * delta
	var remaining: float = maxf(0.0, distance - capture_radius)
	# Do not clamp to the boundary and hope the next frame's floating-point
	# comparison succeeds. Finish the approach and begin the shared native
	# ship-shrinking landing transition in THIS SAME physics frame.
	if step.dot(aim) >= remaining:
		_story_move_to(center - aim * capture_radius)
		_ship_heading = lerp_angle(_ship_heading, aim.angle() + PI * 0.5, minf(1.0, delta * 1.6))
		ship.rotation = _ship_heading
		_story_begin_andromeda_native_landing(capture_radius)
		return
	_story_move_to(_ship_world() + step)
	if _m31_flight_velocity.length_squared() > 1.0:
		_ship_heading = lerp_angle(_ship_heading, _m31_flight_velocity.angle() + PI * 0.5, minf(1.0, delta * 1.6))
	ship.rotation = _ship_heading
	ship.throttle = clampf(_m31_flight_velocity.length() / 660.0, 0.08, 1.0)


func _story_begin_andromeda_native_landing(distance: float) -> void:
	# Preserve the original planet landing mechanism: tween ship.scale to zero,
	# then continue the existing PDF reaction sequence. No duplicate scene.
	if _story_phase != "m31_final_approach" or _planet_landing_active:
		return
	_story_set_phase("m31_gravity_landing")
	_m31_flight_velocity = Vector2.ZERO
	velocity = Vector2.ZERO
	current_input = Vector2.ZERO
	ship.throttle = 0.0
	ship.scale = Vector2.ONE
	ship.visible = true
	_gameplay_hud.hide()
	status_hud.hide()
	get_tree().paused = false
	diagnostics.write("story_m31_native_landing_started", {
		"planet": M31_STORY_PLANET_ID, "distance": distance,
		"native_scale_tween": true, "ui_hidden": true
	})
	_begin_planet_landing(M31_STORY_PLANET_ID, "Фазис", true)


func _story_mars_word_solved() -> void:
	if _story_phase != "mars_word_trace" or StoryProgress.read_mode() != "story":
		return
	# The word is the transition into the rest of page four and pages five/six.
	_story_show_mars_after_word()
	diagnostics.write("story_mars_word_solved", {"next": "mars_story_after_word_panels"})


func _story_show_mars_after_word() -> void:
	if is_instance_valid(_planet_hub):
		_planet_hub.visible = false
	_story_show_panels("mars_story_after_word_panels", [
		"p04_elevator", "p04_ai_core", "p04_mika_orb_close",
		"p05_mika_orb", "p05_mika_happy", "p05_pink_city",
		"p05_mika_shocked", "p05_red_city", "p05_mika_worried",
		"p05_mika_sad", "p05_mika_question",
		"p06_pink_vortex", "p06_mika_thinks", "p06_galaxies_in_orb", "p06_mika_smiles",
		"p06_orb_whole", "p06_bubble_elevator", "p06_mika_bubble_runs"
	])


func _story_show_mars_departure_panels() -> void:
	if is_instance_valid(_planet_hub):
		_planet_hub.visible = false
	_story_show_panels("mars_departure_panels", ["p06_ship_departure", "p06_station_destination"])


func _story_begin_free_prologue_flight() -> void:
	# First and last free-story teaching checkpoint. The game stays the REAL
	# flight scene. The choice of station is encouraged, never enforced.
	if StoryProgress.read_mode() != "story":
		return
	_story_stop_navigation_guide()
	_story_set_phase("free_prologue_complete")
	_planet_landing_active = false
	_story_simulator_required = false
	_intro_comic_playing = false
	_intro_space_flying = false
	_gameplay_hud.show()
	_story_set_flight_controls_visible(true)
	ship.visible = true
	ship.scale = Vector2.ONE
	get_tree().paused = false
	_set_music_context("flight")
	story_bubble_joins_on_mars()
	if StoryProgress.story_bubble_joined():
		# Show the existing clickable simulator-style Bubble care card once.
		# Future reminder cards use the normal 180-second care clock.
		_bubble_attention_pending = not StoryProgress.story_bubble_intro_done()
		_refresh_bubble_popup()
	var has_station_route: bool = _story_refresh_local_route()
	diagnostics.write("story_free_prologue_completed", {
		"bubble_unlocked": StoryProgress.story_bubble_joined(),
		"station_hint": has_station_route,
		"controls_locked": false, "payments_enabled": false
	})


func _story_earth_puzzle_solved() -> void:
	if _story_phase != "earth_puzzle" or not _planet_landing_active:
		return
	# The solved puzzle becomes the opening shot of page three. The Launch
	# lesson starts only AFTER all three page-three shots have played.
	if is_instance_valid(_planet_hub):
		_planet_hub.visible = false
	_story_show_panels("earth_after_puzzle_panels", ["p03_puzzle_reveal", "p03_mika_upset", "p03_ship_refuel"])
	diagnostics.write("story_earth_puzzle_solved", {"puzzle": "spaceport_mission"})


func _story_skip_to_free_world() -> void:
	StoryProgress.write_mode("free_world")
	_sync_bubble_story_access()
	_skip_story()


func _on_story_mode_selected(mode: String, restart: bool) -> void:
	if mode == "free_world":
		_sync_bubble_story_access()
		_skip_story()
	elif mode == "story":
		if restart:
			StoryProgress.restart_story()
		_sync_bubble_story_access()
		_story_resume()


func _on_story_arc_selected(arc_id: String) -> void:
	# An unlocked chapter is replayable from its true native gameplay entry.
	# Station belongs to the subscription portion even on replay.
	if (arc_id == "station" or arc_id.begins_with("chapter02") or arc_id.begins_with("chapter03") or arc_id.begins_with("chapter04") or arc_id.begins_with("chapter05") or arc_id.begins_with("chapter06") or arc_id.begins_with("chapter07")) and not StorySubscriptionGate.has_verified_subscription():
		StorySubscriptionGate.show_notice(self, "station")
		return
	if not StoryProgress.begin_replay(arc_id):
		return
	StoryProgress.write_mode("story")
	_sync_bubble_story_access()
	_story_resume()
	diagnostics.write("story_chapter_checkpoint_opened", {"arc": arc_id, "main_save": not StoryProgress.is_replaying()})


func _story_prepare_checkpoint_world(beat: String) -> void:
	_ch08_close_draw()
	_ch07_close_choice()
	_ch06_close_gate_rebus()
	# A scene entry must relocate the REAL ship and restore the native systems,
	# even when the player currently flies in another galaxy. Keep the main save.
	get_tree().paused = false
	_story_stop_mars_hand_pulse()
	_story_stop_navigation_guide()
	if is_instance_valid(_barnard_pirate_escort):
		_barnard_pirate_escort.call("stop")
	_story_set_lmc_control_lock(false)
	status_hud.set_story_galaxy_attention(false)
	galactic_map.set_story_lmc_lesson(false)
	galactic_map.set_story_destination_hint("")
	if _autopilot_active:
		_stop_autopilot("story_chapter_checkpoint")
	_warp_active = false
	_warp_phase = "idle"
	_warp_overlay.clear_effect()
	_intro_comic_playing = false
	_intro_space_flying = false
	_planet_landing_active = false
	if is_instance_valid(_planet_hub):
		_planet_hub.visible = false
		_planet_hub.call("set_story_ch06_stage", "")
		_planet_hub.call("set_story_earth_stage", "")
		_planet_hub.call("set_story_mars_stage", "")
		_planet_hub.call("set_story_station_stage", "")
		_planet_hub.call("set_story_talos_stage", "")
		_planet_hub.call("set_story_molly_stage", "")
		_planet_hub.call("set_story_lmc_station_stage", "")
		_planet_hub.call("set_story_okea_stage", "")
		_planet_hub.call("set_story_cela_stage", "")
		_planet_hub.call("set_story_lotus_stage", "")
		_planet_hub.call("set_story_barnard_stage", "")
		_planet_hub.call("set_story_archeon_stage", "")
		_planet_hub.call("set_story_runa_stage", "")
	if is_instance_valid(_comic_prologue):
		_comic_prologue.finish()
	velocity = Vector2.ZERO
	current_input = Vector2.ZERO
	joystick.clear_input()
	ship.visible = true
	ship.scale = Vector2.ONE
	ship.modulate = Color.WHITE
	ship.throttle = 0.0
	_gameplay_hud.show()
	var resume_anchor: Array = StoryProgress.safe_resume_anchor(beat)
	if resume_anchor.size() == 2:
		var resume_region: String = str(resume_anchor[0])
		if solar_system.current_id != resume_region:
			_arrive_new_region(resume_region, HyperjumpMotion.arrival_world(Vector2.RIGHT))
		var resume_target: Dictionary = solar_system.get_target_state(str(resume_anchor[1]))
		if bool(resume_target.get("valid", false)):
			_story_move_to(resume_target["world"] + Vector2(float(resume_target.get("arrival_radius", 200.0)) + 155.0, 0.0))
			_layout()
			return
		push_warning("Story resume anchor not available: " + beat)
	if beat in ["smc_arrived", "okea_arrival_panels", "cela_arrival_panels", "lotus_arrival_panels", "lotus_map_barnard"]:
		if solar_system.current_id != "smc":
			_arrive_new_region("smc", HyperjumpMotion.arrival_world(Vector2.RIGHT))
		if beat in ["okea_arrival_panels", "cela_arrival_panels", "lotus_arrival_panels"]:
			var checkpoint_id: String = "smc_p01" if beat == "okea_arrival_panels" else "smc_p02" if beat == "cela_arrival_panels" else "st_smc"
			var checkpoint_target: Dictionary = solar_system.get_target_state(checkpoint_id)
			if bool(checkpoint_target.get("valid", false)):
				_story_move_to(checkpoint_target["world"] + Vector2(float(checkpoint_target.get("arrival_radius", 200.0)) + 110.0, 0.0))
	elif beat in ["barnard_arrived", "archeon_arrival_panels", "runa_arrival_panels"]:
		if solar_system.current_id != "ngc6822":
			_arrive_new_region("ngc6822", HyperjumpMotion.arrival_world(Vector2.RIGHT))
		if beat == "archeon_arrival_panels":
			var archeon_target: Dictionary = solar_system.get_target_state("ngc6822_p01")
			if bool(archeon_target.get("valid", false)):
				_story_move_to(archeon_target["world"] + Vector2(float(archeon_target.get("arrival_radius", 200.0)) + 110.0, 0.0))
		elif beat == "runa_arrival_panels":
			var runa_target: Dictionary = solar_system.get_target_state("ngc6822_p06")
			if bool(runa_target.get("valid", false)):
				_story_move_to(runa_target["world"] + Vector2(float(runa_target.get("arrival_radius", 200.0)) + 110.0, 0.0))
	elif beat == "m31_arrived" or beat.begins_with("m31_"):
		if solar_system.current_id != "m31":
			_arrive_new_region("m31", HyperjumpMotion.arrival_world(Vector2.RIGHT))
		# MIKA_CH05_EPISODE_CHECKPOINTS_V561: move into actual M31 world.
		if beat == "m31_landing_reactions":
			var phasis_checkpoint: Dictionary = solar_system.get_target_state(M31_STORY_PLANET_ID)
			if bool(phasis_checkpoint.get("valid", false)):
				_story_move_to(phasis_checkpoint["world"] + Vector2(float(phasis_checkpoint.get("arrival_radius", 200.0)) + 110.0, 0.0))
		if beat in [
			"m31_station_intro_panels", "m31_station_hub_ball", "m31_station_after_ball_panels",
			"m31_station_hub_pulses", "m31_station_after_pulses_panels",
			"m31_station_hub_launch", "m31_station_departed"
		]:
			# For a cold restart, the REAL ship remains physically beside the station.
			var archive_station: Dictionary = solar_system.get_target_state("st_m31")
			if bool(archive_station.get("valid", false)):
				_story_move_to(archive_station["world"] + Vector2(float(archive_station.get("arrival_radius", 200.0)) + 110.0, 0.0))
	elif beat == "m33_crossroads_arrived":
		if solar_system.current_id != "crossroads":
			_arrive_new_region("crossroads", Vector2(-320.0, 400.0))
	elif beat.begins_with("m33_"):
		if solar_system.current_id != "m33":
			_arrive_new_region("m33", HyperjumpMotion.arrival_world(Vector2.RIGHT))
	elif beat in ["lmc_arrived", "molly_arrival_panels", "lmc_station_arrival_panels", "lmc_station_map_smc"]:
		# Restore the actual Large Magellanic Cloud world, including the ship
		# near the correct native landing body before opening its comic/Hub.
		if solar_system.current_id != "lmc":
			_arrive_new_region("lmc", HyperjumpMotion.arrival_world(Vector2.RIGHT))
		var arrival_target_id: String = ""
		if beat == "molly_arrival_panels":
			arrival_target_id = "lmc_p03"
		elif beat == "lmc_station_arrival_panels":
			arrival_target_id = "st_lmc"
		if not arrival_target_id.is_empty():
			var arrival_target: Dictionary = solar_system.get_target_state(arrival_target_id)
			if bool(arrival_target.get("valid", false)):
				_story_move_to(arrival_target["world"] + Vector2(float(arrival_target.get("arrival_radius", 200.0)) + 110.0, 0.0))
	else:
		if solar_system.current_id != "mw":
			_arrive_new_region("mw", Vector2.ZERO)
		var checkpoint_world: Vector2 = Vector2.ZERO
		if beat in ["navigation_open", "navigation_earth", "navigation_selected"]:
			checkpoint_world = StoryArcadeFlight.earth_hold_position(solar_system.earth_world_position())
		elif beat in ["mars_arrival_panels", "mars_word_trace", "mars_word_done", "mars_story_after_word_panels", "mars_launch"]:
			var mars: Dictionary = solar_system.get_target_state("Mars")
			if bool(mars.get("valid", false)):
				checkpoint_world = mars["world"] + Vector2(float(mars.get("arrival_radius", 200.0)) + 110.0, 0.0)
		elif beat.begins_with("station_"):
			var station: Dictionary = solar_system.get_target_state("st_mw")
			if bool(station.get("valid", false)):
				checkpoint_world = station["world"] + Vector2(250.0, -170.0)
		_story_move_to(checkpoint_world)
	_layout()


func _begin_story_space_flight() -> void:
	get_tree().paused = false
	# Cinematic ejection is not player-controlled space flight.
	_set_music_context("silent", true)
	_story_set_phase("flight_to_earth")
	_story_simulator_required = false
	_intro_comic_playing = false
	_intro_space_flying = true
	_intro_time = 0.0
	_comic_prologue.begin_space_sequence()
	_gameplay_hud.visible = false
	_camera_following = true
	_camera_returning = false
	_map_camera_flying = false
	_camera_offset = Vector2.ZERO
	_story_move_to(StoryArcadeFlight.BLACK_HOLE_WORLD)
	_ship_heading = -0.7
	ship.rotation = _ship_heading
	_story_emphasize_black_hole()
	diagnostics.write("prologue_space_started", {"origin": "existing_black_hole", "mode": "tumble_then_stop_at_earth"})


func _story_emphasize_black_hole() -> void:
	if not is_instance_valid(black_hole):
		return
	black_hole.call("set_diameter", 485.0)
	black_hole.z_index = 12  # Behind the z=15 ship, above the distant starfield.
	black_hole.visible = true
	_story_black_hole_emphasized = true


func _story_restore_black_hole() -> void:
	if not _story_black_hole_emphasized:
		return
	_story_black_hole_emphasized = false
	if is_instance_valid(black_hole):
		black_hole.call("set_diameter", 335.0)
		black_hole.z_index = 0
		_update_black_hole_position()


func _skip_story() -> void:
	_ch08_close_draw()
	_ch07_close_choice()
	_ch06_close_gate_rebus()
	_story_stop_mars_hand_pulse()
	if _story_phase == "m33_intro_panels" and _warp_active:
		_warp_active = false
		_warp_phase = "idle"
		_warp_overlay.clear_effect()
	if is_instance_valid(_barnard_pirate_escort):
		_barnard_pirate_escort.call("stop")
	_story_set_lmc_control_lock(false)
	if is_instance_valid(status_hud):
		status_hud.set_story_fuel_attention(false)
		status_hud.set_story_galaxy_attention(false)
	if is_instance_valid(galactic_map):
		galactic_map.set_story_lmc_lesson(false)
		galactic_map.set_story_destination_hint("")
	if is_instance_valid(action_button):
		action_button.set_action_mode("use")
		action_button.set_action_available(false)
	if is_instance_valid(asteroid_field):
		asteroid_field.clear_story_mars_objects()
	_story_stop_navigation_guide()
	if is_instance_valid(_planet_hub):
		_planet_hub.visible = false
		_planet_hub.call("set_story_ch06_stage", "")
		_planet_hub.call("set_story_earth_stage", "")
		_planet_hub.call("set_story_mars_stage", "")
		_planet_hub.call("set_story_station_stage", "")
		_planet_hub.call("set_story_talos_stage", "")
		_planet_hub.call("set_story_molly_stage", "")
		_planet_hub.call("set_story_lmc_station_stage", "")
		_planet_hub.call("set_story_okea_stage", "")
		_planet_hub.call("set_story_cela_stage", "")
		_planet_hub.call("set_story_lotus_stage", "")
		_planet_hub.call("set_story_barnard_stage", "")
	_planet_landing_active = false
	get_tree().paused = false
	_story_restore_black_hole()
	_story_phase = "inactive"
	_story_simulator_required = false
	_intro_comic_playing = false
	_intro_space_flying = false
	if is_instance_valid(_comic_prologue):
		_comic_prologue.finish()
	_story_set_flight_controls_visible(true)
	ship.visible = true
	ship.modulate = Color.WHITE
	ship.scale = Vector2.ONE
	ship.throttle = 0.0
	ship.rotation = 0.0
	_ship_heading = 0.0
	velocity = Vector2.ZERO
	current_input = Vector2.ZERO
	_camera_offset = Vector2.ZERO
	_camera_following = true
	# A completed story starts its native Free World at Lentis, not at Earth.
	# Before either ending is completed, preserve the original Free World start.
	if StoryProgress.completed_ending_beat().is_empty() or not _ch08_place_at_lentis():
		_story_move_to(solar_system.earth_world_position() + Vector2(170.0, -80.0))
	else:
		_ch08_apply_crew()
	_gameplay_hud.visible = true
	_set_music_context("flight")
	diagnostics.write("prologue_skipped", {})


func _advance_story_flight(delta: float) -> void:
	_intro_time += delta
	var previous_world: Vector2 = _ship_world()
	var target_world: Vector2 = StoryArcadeFlight.world_position(_intro_time, solar_system.earth_world_position())
	var displacement: Vector2 = target_world - previous_world
	_story_move_to(target_world)
	var settling: bool = _intro_time >= StoryArcadeFlight.CRUISE_SECONDS
	ship.throttle = 0.0 if settling else 1.0
	_ship_heading = StoryArcadeFlight.heading_after_step(_intro_time, _ship_heading, displacement, delta)
	ship.rotation = _ship_heading
	ship.scale = Vector2.ONE * StoryArcadeFlight.visual_scale(_intro_time)
	ship.modulate.a = 1.0
	ship.position = get_viewport_rect().size * 0.5 - _camera_offset + StoryArcadeFlight.camera_shake(_intro_time)
	if _intro_time >= 2.5:
		_story_restore_black_hole()
	if _story_phase == "flight_to_earth" and _intro_time >= StoryArcadeFlight.TOTAL_SECONDS:
		_story_show_earth_view_panels()


func _story_move_to(world_position: Vector2) -> void:
	var old_world: Vector2 = Vector2(navigator.sector) * WorldAddress.SECTOR_SIZE + navigator.local
	var displacement: Vector2 = world_position - old_world
	navigator.advance(displacement)
	# Follow the uncontrolled flight so the camera never appears to stop.
	var camera_world: Vector2 = world_position
	var new_offset: Vector2 = camera_world - world_position
	var camera_displacement: Vector2 = camera_world - (old_world + _camera_offset)
	_camera_offset = new_offset
	starfield.advance(camera_displacement)
	starfield.set_camera_look(Vector2.ZERO)
	distant_events.advance_camera(camera_displacement)
	far_plasma.set_camera_address(navigator.sector, navigator.local, _camera_offset)
	cosmic_region.set_camera_address(navigator.sector, navigator.local, _camera_offset)
	solar_system.set_camera_address(navigator.sector, navigator.local, _camera_offset)
	npc_traffic.set_camera_address(navigator.sector, navigator.local, _camera_offset)
	foreign_traffic.set_camera_address(navigator.sector, navigator.local, _camera_offset)
	asteroid_field.set_camera_address(navigator.sector, navigator.local, _camera_offset)
	asteroid_field.set_ship_world(world_position)
	_update_black_hole_position()
	mini_map.set_ship_location(navigator.sector, navigator.local, _ship_heading)
	mini_map.set_camera_offset(_camera_offset)
	mini_map.set_solar_bodies(solar_system.get_navigation_bodies(), solar_system.OUTER_ORBIT_RADIUS)
	ship.position = get_viewport_rect().size * 0.5 - _camera_offset


func _exit_tree() -> void:
	if get_tree() != null:
		get_tree().paused = false
	diagnostics.write("session_end", {"ship_position": navigator.as_dictionary()})


func _update_black_hole_position() -> void:
	if not is_instance_valid(black_hole):
		return
	if solar_system != null and solar_system.current_id != "mw":
		black_hole.visible = false
		return
	var camera_world: Vector2 = Vector2(navigator.sector) * WorldAddress.SECTOR_SIZE + navigator.local + _camera_offset
	var screen_position: Vector2 = CosmicRegionScene.BLACK_HOLE_WORLD - camera_world + get_viewport_rect().size * 0.5
	black_hole.position = screen_position
	# Don't run the black hole's expensive screen-reading shader outside the view.
	var view: Vector2 = get_viewport_rect().size
	black_hole.visible = screen_position.x > -270.0 and screen_position.x < view.x + 270.0 and screen_position.y > -270.0 and screen_position.y < view.y + 270.0


func _on_npc_hyperjump_started(role: String, world: Vector2) -> void:
	diagnostics.write("npc_hyperjump", {"role": role, "x": snappedf(world.x, 1.0), "y": snappedf(world.y, 1.0)})


func _on_npc_landing_completed(role: String, destination: String) -> void:
	diagnostics.write("npc_landed", {"role": role, "destination": destination})


func _on_npc_takeoff_started(role: String, destination: String) -> void:
	diagnostics.write("npc_takeoff", {"role": role, "origin": destination})

# v59.1: one shared planet landing screen for every landable world.
# Planet surface backgrounds and card art can be provided by asset ID later.
func _ensure_planet_hub() -> Control:
	if is_instance_valid(_planet_hub):
		return _planet_hub
	var path: String = "res://planet_hub/scenes/planet_hub_overlay.tscn"
	var scene: PackedScene = load(path) as PackedScene
	if scene == null:
		push_error("Missing v59.1 planet hub scene: " + path)
		return null
	_planet_hub = scene.instantiate() as Control
	_planet_hub.name = "PlanetHubOverlay"
	_planet_hub.process_mode = Node.PROCESS_MODE_ALWAYS
	_gameplay_hud.add_child(_planet_hub)
	_planet_hub.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_planet_hub.size = get_viewport_rect().size
	_planet_hub.connect("flight_requested", Callable(self, "_on_planet_hub_flight_requested"))
	_planet_hub.connect("simulator_requested", Callable(self, "_on_planet_hub_simulator_requested"))
	_planet_hub.connect("representative_requested", Callable(self, "_on_planet_representative_requested"))
	_planet_hub.connect("story_earth_puzzle_solved", Callable(self, "_story_earth_puzzle_solved"))
	_planet_hub.connect("story_mars_word_solved", Callable(self, "_story_mars_word_solved"))
	_planet_hub.connect("story_station_list_solved", Callable(self, "_story_station_list_solved"))
	_planet_hub.connect("story_talos_maze_solved", Callable(self, "_story_talos_maze_solved"))
	_planet_hub.connect("story_molly_tree_solved", Callable(self, "_story_molly_tree_solved"))
	_planet_hub.connect("story_lmc_station_sunbeam_solved", Callable(self, "_story_lmc_station_sunbeam_solved"))
	_planet_hub.connect("story_okea_solutions_solved", Callable(self, "_story_okea_solutions_solved"))
	_planet_hub.connect("story_cela_crystals_solved", Callable(self, "_story_cela_crystals_solved"))
	_planet_hub.connect("story_lotus_water_solved", Callable(self, "_story_lotus_water_solved"))
	_planet_hub.connect("story_barnard_pizza_solved", Callable(self, "_story_barnard_pizza_solved"))
	_planet_hub.connect("story_archeon_fossils_solved", Callable(self, "_story_archeon_fossils_solved"))
	_planet_hub.connect("story_runa_evolution_solved", Callable(self, "_story_runa_evolution_solved"))
	_planet_hub.connect("story_m31_pinball_solved", Callable(self, "_story_m31_pinball_solved"))
	_planet_hub.connect("story_m31_ball_solved", Callable(self, "_story_m31_ball_solved"))
	_planet_hub.connect("story_m31_pulses_solved", Callable(self, "_story_m31_pulses_solved"))
	_planet_hub.connect("story_ch06_math_solved", Callable(self, "_ch06_math_solved"))
	return _planet_hub


func _ensure_representative_dialog() -> Control:
	if is_instance_valid(_representative_dialog):
		return _representative_dialog
	var path: String = "res://planet_hub/scenes/representative_dialog.tscn"
	var scene: PackedScene = load(path) as PackedScene
	if scene == null:
		push_error("Missing representative dialog: " + path)
		return null
	_representative_dialog = scene.instantiate() as Control
	_representative_dialog.name = "PlanetRepresentativeConversation"
	_representative_dialog.visible = false
	_representative_dialog.process_mode = Node.PROCESS_MODE_ALWAYS
	_gameplay_hud.add_child(_representative_dialog)
	_representative_dialog.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_representative_dialog.size = get_viewport_rect().size
	_representative_dialog.connect("return_requested", Callable(self, "_on_representative_return_requested"))
	return _representative_dialog


func _on_planet_representative_requested(planet_id: String) -> void:
	if not _planet_landing_active or not is_instance_valid(_planet_hub):
		return
	var planet_meta: Dictionary = _planet_hub.get("_meta")
	if not bool(planet_meta.get("inhabited", false)):
		return
	var dialog: Control = _ensure_representative_dialog()
	if dialog == null:
		return
	var planet_name: String = str(_planet_hub.get("_planet_name"))
	var background_path: String = str(_planet_hub.call("get_dialog_background_path"))
	var portrait_path: String = str(_planet_hub.call("get_dialog_portrait_path"))
	dialog.call("configure_for_planet", planet_id, planet_name, background_path, portrait_path)
	_planet_hub.visible = false
	dialog.visible = true
	get_tree().paused = true
	diagnostics.write("representative_dialog_opened", {"planet": planet_id})


func _on_representative_return_requested() -> void:
	if is_instance_valid(_representative_dialog):
		_representative_dialog.visible = false
	if _planet_landing_active and is_instance_valid(_planet_hub):
		_planet_hub.visible = true
	get_tree().paused = _planet_landing_active
	diagnostics.write("representative_dialog_closed", {})


func _begin_planet_landing(planet_id: String, display_name: String, with_animation: bool = true) -> void:
	# The ship reaches the station normally. Only the landing transition is
	# subscription-gated after Mars; manual flight and nearby planets remain free.
	if planet_id.begins_with("st_") and not StorySubscriptionGate.can_enter_station():
		if _autopilot_active:
			_stop_autopilot("story_station_subscription")
		if _story_phase == "free_prologue_complete" and StoryProgress.read_mode() == "story":
			goal_picker.set_story_navigation_guide("station")
		StorySubscriptionGate.show_notice(self, "station")
		diagnostics.write("story_subscription_station_gate", {"planet": planet_id})
		return
	if is_instance_valid(_bubble_popup):
		_bubble_popup.hide()

	if _planet_landing_active:
		return
	if planet_id == CH06_GATE and StoryProgress.read_mode() == "story" and solar_system.current_id == "m33":
		if _story_phase in ["m33_departed", "m33_station_arrived"]:
			_ch06_start_gate_comic()
			return
		# The station is not a normal Hub during the active Chapter 6 route.
		if _story_phase.begins_with("m33_") and _story_phase != "m33_crossroads_arrived":
			return
	var hub: Control = _ensure_planet_hub()
	if hub == null:
		return
	if planet_id == "st_mw" and _story_phase == "free_prologue_complete" and StoryProgress.read_mode() == "story":
		StoryProgress.mark_story_station_navigation_used()
		goal_picker.set_story_navigation_guide("")
	_planet_landing_active = true
	_set_music_context("calm")
	if _autopilot_active:
		_stop_autopilot("landing_on_planet")
	velocity = Vector2.ZERO
	current_input = Vector2.ZERO
	joystick.clear_input()
	ship.throttle = 0.0
	if with_animation:
		var tw: Tween = create_tween()
		tw.tween_property(ship, "scale", Vector2.ZERO, 0.42).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
		await tw.finished
	ship.visible = false
	if _story_phase == "m33_to_lentis" and planet_id == CH06_LENTIS and StoryProgress.read_mode() == "story":
		_ch06_clear_nav_hint()
		_story_show_panels("m33_lentis_panels", CH06_BEFORE_MATH)
		return
	if _story_phase == "m31_departed" and planet_id == "st_m31" and StoryProgress.read_mode() == "story":
		# Genuine station docking/ship shrink has finished: no UI gap.
		_story_show_panels("m31_station_intro_panels", ["p53_archive_hall", "p53_mika_console"])
		diagnostics.write("story_m31_station_docked", {"station": "st_m31", "frames": 2})
		return
	if _story_phase == "m31_gravity_landing" and planet_id == M31_STORY_PLANET_ID and StoryProgress.read_mode() == "story":
		_story_show_panels("m31_landing_reactions", [
			"p51_mika_frightened", "p51_lizard_frightened",
			"p51_pyramid_landing", "p51_magnetic_creatures"
		])
		return
	if _story_phase == "navigation_selected" and planet_id == "mw_p01" and StoryProgress.read_mode() == "story":
		# Finish ONLY the remaining two panels of page two. The third page
		# belongs to the completed puzzle, not the landing transition.
		_story_show_panels("earth_landing_panels", ["earth_approach", "earth_spaceport"])
		return
	if ["mars_navigation_selected", "mars_navigation_resume"].has(_story_phase) and planet_id == "mw_p02" and StoryProgress.read_mode() == "story":
		# Use the native landing, then only the first three frames of page four.
		_story_show_panels("mars_arrival_panels", ["p04_mars_landing", "p04_mika_walk", "p04_reception"])
		return
	if _story_phase == "free_prologue_complete" and planet_id == "st_mw" and StoryProgress.read_mode() == "story":
		# The existing animated landing leads to the first SIX panels of PDF 7.
		# The seventh belongs to the hyperjump, not this station arrival.
		_story_show_panels("station_arrival_panels", [
			"p07_station_hangar", "p07_mika_staff", "p07_mika_worried",
			"p07_professor_arrives", "p07_professor_talks", "p07_ship_repair"
		])
		return
	if _story_phase == "lmc_arrived" and planet_id == "lmc_p02" and solar_system.current_id == "lmc" and StoryProgress.read_mode() == "story":
		goal_picker.set_story_navigation_guide("")
		_story_show_talos_arrival_panels()
		return
	if _story_phase == "talos_departed" and planet_id == "lmc_p03" and solar_system.current_id == "lmc" and StoryProgress.read_mode() == "story":
		goal_picker.set_story_navigation_guide("")
		_story_show_molly_arrival_panels()
		return
	if _story_phase == "molly_departed" and planet_id == "st_lmc" and solar_system.current_id == "lmc" and StoryProgress.read_mode() == "story":
		goal_picker.set_story_navigation_guide("")
		_story_show_lmc_station_arrival_panels()
		return
	if _story_phase == "smc_arrived" and planet_id == "smc_p01" and solar_system.current_id == "smc" and StoryProgress.read_mode() == "story":
		# Two Okea introduction panels BEFORE the exact same Planet Hub.
		goal_picker.set_story_navigation_guide("")
		_story_show_okea_arrival_panels()
		return
	if _story_phase == "okea_departed" and planet_id == "smc_p02" and solar_system.current_id == "smc" and StoryProgress.read_mode() == "story":
		# Native Cela landing, then first three panels of PDF 3-2.
		_story_show_cela_arrival_panels()
		return
	if _story_phase == "cela_departed" and planet_id == "st_smc" and solar_system.current_id == "smc" and StoryProgress.read_mode() == "story":
		# Native station landing -> final PDF 3-3 panel -> PDF 3-4 first.
		_story_show_lotus_arrival_panels()
		return
	if _story_phase == "barnard_station_departed" and planet_id == "ngc6822_p01" and solar_system.current_id == "ngc6822" and StoryProgress.read_mode() == "story":
		# Real landing first, THEN the cockpit / arrival / scientist on PDF 4-3.
		goal_picker.set_story_navigation_guide("")
		_story_show_panels("archeon_arrival_panels", ["p43_cockpit_decision", "p43_ship_landing", "p43_scientist_meeting"])
		return
	if _story_phase == "archeon_departed" and planet_id == "ngc6822_p06" and solar_system.current_id == "ngc6822" and StoryProgress.read_mode() == "story":
		# Real landing leads into the entirety of PDF 4-4 and PDF 4-5 up to
		# the wide white evolution strip, before any mandatory game appears.
		goal_picker.set_story_navigation_guide("")
		_story_show_panels("runa_arrival_panels", [
			"p44_professor_studies_fossil", "p44_professor_realization",
			"p44_dinosaur_dna", "p44_ancient_dinosaurs", "p44_ancient_meteorite",
			"p45_ruins_entrance", "p45_museum_walk", "p45_professor_handshake",
			"p45_evolution_display", "p45_white_evolution"
		])
		return
	hub.size = get_viewport_rect().size
	hub.call("show_for_planet", planet_id, display_name, floori(_fuel_units + 0.001))
	get_tree().paused = true
	diagnostics.write("planet_hub_opened", {"planet": planet_id, "inhabited": true})


func _on_planet_hub_flight_requested() -> void:
	if _story_phase == "m33_hub_math" and StoryProgress.read_mode() == "story":
		return
	if not _planet_landing_active:
		return
	if ["earth_puzzle", "mars_word_trace", "mars_word_done", "talos_hub_maze", "molly_hub_tree", "lmc_station_hub_sunbeam", "okea_hub_lab", "cela_hub_crystals", "lotus_hub_molecule", "barnard_station_hub_pizza", "archeon_hub_fossils", "runa_hub_evolution", "m31_hub_pinball"].has(_story_phase):
		return
	if _story_phase == "earth_launch":
		# The child pressed the REAL Hub Launch button. First finish page
		# three; only after that may the existing ship takeoff run.
		_fuel_units = STORY_MARS_LAUNCH_FUEL
		_refresh_fuel_hud()
		status_hud.set_story_fuel_attention(true)
		_planet_hub.visible = false
		_story_show_panels("earth_departure_panels", ["p03_earth_departure", "p03_mars_destination"])
		return
	if _story_phase == "mars_launch":
		# Real Hub Launch first. Then the two reserved PDF6 shots; only then
		# animate the original ship taking off in the playable space.
		_story_show_mars_departure_panels()
		return
	if _story_phase == "station_hub_list":
		return
	if _story_phase == "talos_hub_launch":
		# Button -> last original comic frame -> normal ship takeoff.
		_planet_hub.visible = false
		_story_show_panels("talos_departure_panel", ["p22_planet_departure"])
		return
	if _story_phase == "okea_hub_launch":
		_planet_hub.visible = false
		_story_show_panels("okea_departure_panel", ["p31_okea_to_cela"])
		return
	if _story_phase == "archeon_hub_launch":
		_planet_hub.visible = false
		_story_show_panels("archeon_departure_panels", ["p43_next_target", "p43_space_departure"])
		return
	# On Molly the FINAL PDF picture was already shown after growing the
	# tree; Launch now returns directly to the normal Godot takeoff.
	var guided_mars_departure: bool = _story_phase == "earth_departure_panels"
	var guided_station_departure: bool = _story_phase == "mars_departure_panels"
	var guided_lmc_departure: bool = _story_phase == "station_hub_launch"
	var guided_talos_departure: bool = _story_phase == "talos_departure_panel"
	var guided_molly_departure: bool = _story_phase == "molly_hub_launch"
	var guided_smc_departure: bool = _story_phase == "lmc_station_hub_launch"
	var guided_cela_departure: bool = _story_phase == "okea_departure_panel"
	var guided_lotus_departure: bool = _story_phase == "cela_hub_launch"
	var guided_barnard_departure: bool = _story_phase == "lotus_hub_launch"
	var guided_pirate_station_departure: bool = _story_phase == "barnard_station_hub_launch"
	var guided_archeon_departure: bool = _story_phase == "archeon_departure_panels"
	var guided_runa_departure: bool = _story_phase == "runa_hub_launch"
	var guided_m31_departure: bool = _story_phase == "m31_hub_launch"
	var guided_ch06_departure: bool = _story_phase == "m33_hub_launch" and StoryProgress.read_mode() == "story"
	var guided_m31_station_departure: bool = _story_phase == "m31_station_hub_launch"
	_planet_hub.visible = false
	if guided_mars_departure:
		_story_set_phase("earth_departed")
		_planet_hub.call("set_story_earth_stage", "")
	if guided_station_departure:
		_story_set_phase("mars_departed")
		_planet_hub.call("set_story_mars_stage", "")
	if guided_lmc_departure:
		_planet_hub.call("set_story_station_stage", "")
	if guided_talos_departure:
		_story_set_phase("talos_departed")
		_planet_hub.call("set_story_talos_stage", "")
	if guided_molly_departure:
		_story_set_phase("molly_departed")
		_planet_hub.call("set_story_molly_stage", "")
	if guided_smc_departure:
		_story_set_phase("lmc_station_departed")
		_planet_hub.call("set_story_lmc_station_stage", "")
	if guided_cela_departure:
		_story_set_phase("okea_departed")
		_planet_hub.call("set_story_okea_stage", "")
	if guided_lotus_departure:
		_story_set_phase("cela_departed")
		_planet_hub.call("set_story_cela_stage", "")
	if guided_barnard_departure:
		# Keep the genuine native ship takeoff, but do not reveal a transient
		# gameplay HUD/map/controls frame between the station Hub and the
		# final comic image. They return after the page completes.
		_story_stop_navigation_guide()
		_gameplay_hud.hide()
		status_hud.hide()
		_planet_hub.call("set_story_lotus_stage", "")
	if guided_pirate_station_departure:
		# All three ships already landed inside the genuine Barnard world.
		# Keep the cockpit controls out of the launch tween; restore them on exit.
		_gameplay_hud.hide()
		status_hud.hide()
		_planet_hub.call("set_story_barnard_stage", "")
	if guided_archeon_departure:
		_planet_hub.call("set_story_archeon_stage", "")
		_story_set_phase("archeon_departed")
	if guided_runa_departure:
		_planet_hub.call("set_story_runa_stage", "")
		_story_set_phase("runa_departed")
	if guided_m31_departure:
		_planet_hub.call("set_story_m31_stage", "")
		_story_set_phase("m31_departed")
	if guided_m31_station_departure:
		_planet_hub.call("set_story_m31_stage", "")
		_story_set_phase("m31_station_departed")
	if guided_ch06_departure:
		_planet_hub.call("set_story_ch06_stage", "")
		_story_set_phase("m33_departed")
	_planet_landing_active = false
	_set_music_context("flight")
	get_tree().paused = false
	ship.visible = true
	ship.scale = Vector2.ZERO
	ship.modulate = Color.WHITE
	ship.throttle = 0.0
	var tw: Tween = create_tween()
	tw.tween_property(ship, "scale", Vector2.ONE, 0.33).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	joystick.clear_input()
	current_input = Vector2.ZERO
	_update_landing_offer()
	diagnostics.write("planet_hub_launch_requested", {})
	if guided_mars_departure:
		await tw.finished
		if _story_phase == "earth_departed" and StoryProgress.read_mode() == "story":
			_story_begin_navigation_guide("mars_navigation_open")
	elif guided_station_departure:
		await tw.finished
		if _story_phase == "mars_departed" and StoryProgress.read_mode() == "story":
			_story_begin_free_prologue_flight()
			diagnostics.write("story_mars_launch_completed", {"next": "free_prologue_complete"})
	elif guided_lmc_departure:
		await tw.finished
		if _story_phase == "station_hub_launch" and StoryProgress.read_mode() == "story":
			_story_begin_lmc_map_lesson()
	elif guided_talos_departure:
		await tw.finished
		if _story_phase == "talos_departed" and StoryProgress.read_mode() == "story":
			goal_picker.set_story_navigation_guide("molly_open")
	elif guided_molly_departure:
		await tw.finished
		if _story_phase == "molly_departed" and StoryProgress.read_mode() == "story":
			goal_picker.set_story_navigation_guide("station_open")
	elif guided_smc_departure:
		await tw.finished
		if _story_phase == "lmc_station_departed" and StoryProgress.read_mode() == "story":
			_story_begin_smc_map_hint()
	elif guided_cela_departure:
		await tw.finished
		if _story_phase == "okea_departed" and StoryProgress.read_mode() == "story":
			goal_picker.set_story_navigation_guide("cela_open")
	elif guided_lotus_departure:
		await tw.finished
		if _story_phase == "cela_departed" and StoryProgress.read_mode() == "story":
			goal_picker.set_story_navigation_guide("lotus_open")
	elif guided_barnard_departure:
		await tw.finished
		if _story_phase == "lotus_hub_launch" and StoryProgress.read_mode() == "story":
			# No second comic start: the ship was shown right after the prince.
			_story_begin_barnard_map_hint()
	elif guided_pirate_station_departure:
		await tw.finished
		if _story_phase == "barnard_station_hub_launch" and StoryProgress.read_mode() == "story":
			_story_barnard_restore_flight()
	elif guided_archeon_departure:
		await tw.finished
		if _story_phase == "archeon_departed" and StoryProgress.read_mode() == "story":
			_story_restore_after_archeon_launch()
	elif guided_runa_departure:
		await tw.finished
		if _story_phase == "runa_departed" and StoryProgress.read_mode() == "story":
			_story_begin_andromeda_map_hint()
	elif guided_m31_departure:
		await tw.finished
		if _story_phase == "m31_departed" and StoryProgress.read_mode() == "story":
			_story_restore_after_m31_launch()
	elif guided_ch06_departure:
		await tw.finished
		if _story_phase == "m33_departed" and StoryProgress.read_mode() == "story":
			_ch06_restore_flight("m33_departed")
	elif guided_m31_station_departure:
		await tw.finished
		if _story_phase == "m31_station_departed" and StoryProgress.read_mode() == "story":
			_story_begin_triangulum_map_hint()


func _on_planet_hub_simulator_requested() -> void:
	if is_instance_valid(_bubble_popup):
		_bubble_popup.hide()

	if not _planet_landing_active:
		return
	_planet_hub.visible = false
	_set_music_context("silent", true)
	main_menu.set_stats(status_hud.crystal_count, 0, 0.0)
	main_menu.open_menu(get_viewport_rect().size)
	# The normal ship simulator is unchanged; returning opens the planet hub.
	get_tree().paused = true
	diagnostics.write("planet_hub_simulator_opened", {})


func _v104_free_world_boot() -> void:
	# Story is the default on develop. The user's explicit Free World choice
	# survives restarts; --story allows an immediate preview from Terminal.
	var command_line: PackedStringArray = OS.get_cmdline_user_args()
	if command_line.has("--story") or command_line.has("--story-replay-prologue"):
		StoryProgress.write_mode("story")
	if command_line.has("--story-replay-prologue"):
		StoryProgress.begin_replay("prologue")
	_sync_bubble_story_access()
	if StoryProgress.read_mode() == "story":
		_story_resume()
	else:
		_skip_story()
	_ch08_apply_crew()


func _v104_open_crossroads_dialog() -> void:
	if not is_instance_valid(_v104_crossroads_dialog):
		_v104_crossroads_dialog = V104_CROSSROADS_UI.new() as Control
		if _v104_crossroads_dialog == null:
			push_error("Unable to instantiate the Crossroads conversation")
			return
		_v104_crossroads_dialog.name = "CrossroadsLivingPlanetConversation"
		_v104_crossroads_dialog.process_mode = Node.PROCESS_MODE_ALWAYS
		_gameplay_hud.add_child(_v104_crossroads_dialog)
		_v104_crossroads_dialog.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		_v104_crossroads_dialog.connect("return_requested",Callable(self,"_v104_close_crossroads_dialog"))
	if _autopilot_active:
		_stop_autopilot("crossroads_dialog")
	velocity = Vector2.ZERO
	_set_music_context("calm")
	current_input = Vector2.ZERO
	joystick.clear_input()
	_v104_crossroads_dialog.call("open_dialog")
	get_tree().paused = true


func _v104_close_crossroads_dialog() -> void:
	if is_instance_valid(_v104_crossroads_dialog):
		_v104_crossroads_dialog.visible = false
	get_tree().paused = false
	_set_music_context("flight")
	joystick.clear_input()
	current_input = Vector2.ZERO
	_update_landing_offer()


func _set_music_context(context: String, immediate: bool = false) -> void:
	if is_instance_valid(_adaptive_music):
		_adaptive_music.set_context(context, immediate)


# v122: the approved Bubble-style simulator card is clickable but never modal.
func _v122_build_empty_fuel_card(root: Control) -> void:
	var popup: Button = EmptyFuelSimulatorCardScript.new() as Button
	if popup == null:
		push_error("Fuel-empty simulator reminder: could not create the existing card")
		return
	popup.name = "FuelEmptySimulatorCenterReminder"
	root.add_child(popup)
	popup.call("configure", self)
	popup.connect("simulator_requested", Callable(self, "_on_story_simulator_card_requested"))


func _ch06_finish_intro() -> void:
	_comic_prologue.finish()
	_intro_comic_playing = false
	if _warp_active and _warp_destination == "m33":
		_gameplay_hud.hide()
		get_tree().paused = false
		_warp_phase = "transit"
		_warp_time = 0.0
	else:
		_story_arrive_triangulum_preview()

func _ch06_restore_flight(beat: String) -> void:
	_story_stop_navigation_guide()
	_story_set_lmc_control_lock(false)
	_story_set_phase(beat)
	_intro_comic_playing = false
	_intro_space_flying = false
	_planet_landing_active = false
	_gameplay_hud.show()
	status_hud.show()
	ship.visible = true
	ship.scale = Vector2.ONE
	ship.modulate = Color.WHITE
	ship.throttle = 0.0
	_story_set_flight_controls_visible(true)
	status_hud.set_story_galaxy_attention(false)
	galactic_map.set_story_destination_hint("")
	get_tree().paused = false
	_set_music_context("flight")
	_layout()
	_story_refresh_local_route()

func _ch06_show_hub(stage: String) -> void:
	_story_ensure_comic()
	_comic_prologue.finish()
	_intro_comic_playing = false
	_intro_space_flying = false
	_story_simulator_required = false
	_story_set_phase("m33_hub_launch" if stage == "launch" else "m33_hub_math")
	_planet_landing_active = true
	_gameplay_hud.show()
	ship.visible = false
	var hub: Control = _ensure_planet_hub()
	if hub == null:
		push_error("CH06: native Planet Hub unavailable")
		return
	hub.size = get_viewport_rect().size
	hub.call("show_for_planet", CH06_LENTIS, "Лентис" if str(MobileLocale.language) == "ru" else "Lentis", floori(_fuel_units + 0.001))
	hub.call("set_story_ch06_stage", stage)
	_set_music_context("calm")
	get_tree().paused = true

func _ch06_math_solved() -> void:
	if _story_phase != "m33_hub_math" or StoryProgress.read_mode() != "story":
		return
	if is_instance_valid(_planet_hub):
		_planet_hub.visible = false
	_story_show_panels("m33_after_math_panels", CH06_AFTER_MATH)

func _ch06_clear_nav_hint() -> void:
	if is_instance_valid(goal_picker):
		goal_picker.clear_story_late_route_guide()


# MIKA_CH06_CROSSROADS_GATE_V1: the native station is a story trigger, not a Hub.
func _ch06_start_gate_comic() -> void:
	_ch06_close_gate_rebus()
	_planet_landing_active = true
	_ch06_clear_nav_hint()
	if _autopilot_active:
		_stop_autopilot("ch06_gate_story")
	velocity = Vector2.ZERO
	current_input = Vector2.ZERO
	joystick.clear_input()
	ship.throttle = 0.0
	ship.scale = Vector2.ONE
	# NO native docking until the final puzzle and last panel have finished.
	if is_instance_valid(_planet_hub):
		_planet_hub.hide()
	_story_show_panels("m33_station_arrived", CH06_GATE_BEFORE_REBUS)

func _ch06_open_gate_rebus() -> void:
	if StoryProgress.read_mode() != "story" or is_instance_valid(_ch06_rebus_layer):
		return
	# A direct instance of the SAME educational scene, no simulator or Station Hub.
	var packed: PackedScene = load("res://planet_hub/games/space_rebus/scenes/SpaceRebusAdventures.tscn") as PackedScene
	var story_script: Script = load("res://planet_hub/games/space_rebus/scripts/MIKAStoryCrossroadsRebus.gd") as Script
	if packed == null or story_script == null:
		push_error("CH06: native Space Rebus is unavailable")
		return
	var game: Node = packed.instantiate()
	if game == null or not game is Control:
		if game != null:
			game.free()
		push_error("CH06: Space Rebus scene root is not Control")
		return
	game.set_script(story_script)
	if not game.has_signal("story_crossroads_solved"):
		game.free()
		push_error("CH06: Story Rebus adapter failed")
		return
	game.connect("story_crossroads_solved", Callable(self, "_ch06_gate_rebus_solved"), CONNECT_DEFERRED)
	_story_set_phase("m33_gate_rebus")
	if is_instance_valid(_comic_prologue):
		_comic_prologue.finish()
	_intro_comic_playing = false
	_intro_space_flying = false
	_planet_landing_active = true
	_gameplay_hud.hide()
	ship.visible = false
	get_tree().paused = true
	_set_music_context("calm")
	_ch06_rebus_layer = CanvasLayer.new()
	_ch06_rebus_layer.name = "CH06NativeSpaceRebusLayer"
	_ch06_rebus_layer.layer = 3
	_ch06_rebus_layer.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(_ch06_rebus_layer)
	_ch06_rebus_layer.add_child(game)

func _ch06_close_gate_rebus() -> void:
	if is_instance_valid(_ch06_rebus_layer):
		# Remove from tree immediately: the game's header has its own CanvasLayer.
		if _ch06_rebus_layer.get_parent() != null:
			_ch06_rebus_layer.get_parent().remove_child(_ch06_rebus_layer)
		_ch06_rebus_layer.queue_free()
	_ch06_rebus_layer = null

func _ch06_gate_rebus_solved() -> void:
	if _story_phase != "m33_gate_rebus" or StoryProgress.read_mode() != "story" or not is_instance_valid(_ch06_rebus_layer):
		return
	_ch06_close_gate_rebus()
	# Native game normally settles one earned crystal via its host. Here Main is the host.
	_story_show_panels("m33_gate_exit_panels", CH06_GATE_AFTER_REBUS)
	_on_educational_crystals_earned(1)

func _ch06_gate_transfer() -> void:
	_ch06_close_gate_rebus()
	if is_instance_valid(_comic_prologue):
		_comic_prologue.finish()
	_story_set_phase("m33_gate_transfer")
	_intro_comic_playing = false
	_intro_space_flying = false
	_planet_landing_active = true
	_gameplay_hud.hide()
	if is_instance_valid(_planet_hub):
		_planet_hub.hide()
	velocity = Vector2.ZERO
	current_input = Vector2.ZERO
	joystick.clear_input()
	ship.visible = true
	ship.scale = Vector2.ONE
	ship.modulate = Color.WHITE
	ship.throttle = 0.0
	_camera_following = true
	_camera_returning = false
	_map_camera_flying = false
	# Resume anchors are a little outside the arrival radius; use a real station approach.
	var station: Dictionary = solar_system.get_target_state(CH06_GATE)
	if solar_system.current_id == "m33" and bool(station.get("valid", false)):
		var target: Vector2 = station["world"]
		var offset: Vector2 = _ship_world() - target
		var radius: float = float(station.get("arrival_radius", 200.0))
		if offset.length() > radius or offset.length() < 1.0:
			var direction: Vector2 = offset.normalized() if offset.length() >= 1.0 else Vector2.RIGHT
			_story_move_to(target + direction * radius * 0.88)
		else:
			_story_move_to(_ship_world())
	get_tree().paused = false
	_set_music_context("calm")
	# Same native docking scale animation, now AFTER the Rebus. No Hub call.
	var docking: Tween = create_tween()
	docking.tween_property(ship, "scale", Vector2.ZERO, 0.42).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	await docking.finished
	if _story_phase == "m33_gate_transfer" and StoryProgress.read_mode() == "story":
		_ch06_enter_crossroads()

func _ch06_enter_crossroads() -> void:
	# Existing AtlasSystem/OtherSystem location, not a new scene or station.
	if solar_system.current_id != "crossroads":
		_arrive_new_region("crossroads", Vector2(-1600.0, -400.0))
	if solar_system.current_id != "crossroads":
		push_error("CH06: Crossroads region could not be loaded")
		return
	if not StoryProgress.unlock_region("crossroads"):
		push_warning("CH06: Crossroads discovery could not be written")
	_ch06_restore_flight("m33_crossroads_arrived")
	# Real flight resumes in the last region. No automatic Living World dialogue yet.
	diagnostics.write("story_ch06_crossroads_arrived", {"region": "crossroads", "via": CH06_GATE})


# MIKA_CH07_ENDING_CHOICE_V1 — final scene, no branch consequences yet.
func _ch07_can_begin() -> bool:
	return StoryProgress.read_mode() == "story" and _story_phase in ["m33_crossroads_arrived", "crossroads_ending1_returned", "crossroads_ending2_returned"] and is_instance_valid(solar_system) and solar_system.current_id == "crossroads"

func _ch07_start_finale() -> void:
	if not _ch07_can_begin() or _warp_active or _intro_comic_playing or get_tree().paused:
		return
	_ch07_play_panels()

func _ch07_play_panels() -> void:
	_ch07_close_choice()
	if _autopilot_active:
		_stop_autopilot("ch07_living_world")
	_ch06_clear_nav_hint()
	velocity = Vector2.ZERO
	current_input = Vector2.ZERO
	joystick.clear_input()
	ship.throttle = 0.0
	_planet_landing_active = true
	if is_instance_valid(_planet_hub):
		_planet_hub.hide()
	if is_instance_valid(_v104_crossroads_dialog):
		_v104_crossroads_dialog.hide()
	_story_show_panels("crossroads_finale_panels", CH07_PANELS)

func _ch07_open_choice() -> void:
	if StoryProgress.read_mode() != "story" or is_instance_valid(_ch07_choice_layer):
		return
	var native_scene: PackedScene = load("res://learning/scenes/features/matching_pairs/matching_pairs_game.tscn") as PackedScene
	var adapter: Script = load("res://learning/src/features/matching_pairs/MIKAStoryEndingChoice.gd") as Script
	if native_scene == null or adapter == null:
		push_error("CH07: native Matching Pairs ending assets unavailable")
		return
	var game: Node = native_scene.instantiate()
	if game == null or not game is Node2D:
		if game != null:
			game.free()
		push_error("CH07: unexpected Matching Pairs scene root")
		return
	game.set_script(adapter)
	if not game.has_signal("ending_selected"):
		game.free()
		push_error("CH07: ending adapter could not be loaded")
		return
	game.connect("ending_selected", Callable(self, "_ch07_ending_selected"))
	_story_set_phase("crossroads_finale_choice")
	if is_instance_valid(_comic_prologue):
		_comic_prologue.finish()
	_intro_comic_playing = false
	_intro_space_flying = false
	_planet_landing_active = true
	_gameplay_hud.hide()
	ship.visible = false
	get_tree().paused = true
	_set_music_context("calm")
	_ch07_choice_layer = CanvasLayer.new()
	_ch07_choice_layer.name = "CH07NativeEndingChoiceLayer"
	_ch07_choice_layer.layer = 3
	_ch07_choice_layer.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(_ch07_choice_layer)
	_ch07_choice_layer.add_child(game)

func _ch07_close_choice() -> void:
	if is_instance_valid(_ch07_choice_layer):
		if _ch07_choice_layer.get_parent() != null:
			_ch07_choice_layer.get_parent().remove_child(_ch07_choice_layer)
		_ch07_choice_layer.queue_free()
	_ch07_choice_layer = null

func _ch07_ending_selected(ending_id: String) -> void:
	if _story_phase != "crossroads_finale_choice" or ending_id not in ["ending_1", "ending_2"]:
		return
	if ending_id == "ending_1":
		# Defer removal of the matching scene until its button signal has returned.
		call_deferred("_ch08_begin_ending_one")
		return
	call_deferred("_ch08_begin_ending_two")


# MIKA_CH08_ENDING_ONE_V1 — left door, reunion, native return to M33.
func _ch08_begin_ending_one() -> void:
	if _story_phase != "crossroads_finale_choice" or StoryProgress.read_mode() != "story":
		return
	_ch08_play_ending_one()

func _ch08_play_ending_one() -> void:
	_ch07_close_choice()
	if _autopilot_active:
		_stop_autopilot("ch08_ending_one")
	velocity = Vector2.ZERO
	current_input = Vector2.ZERO
	joystick.clear_input()
	ship.throttle = 0.0
	ship.hide()
	_planet_landing_active = true
	_story_show_panels("crossroads_ending1_panels", CH08_ENDING_ONE_PANELS)

# MIKA_CH08_LENTIS_FREE_WORLD_V1: one native flight arrival for both endings.
func _ch08_place_at_lentis() -> bool:
	if _autopilot_active:
		_stop_autopilot("ch08_return_to_lentis")
	if solar_system.current_id != "m33":
		_arrive_new_region("m33", HyperjumpMotion.arrival_world(Vector2.RIGHT))
	if solar_system.current_id != "m33":
		push_error("CH08: could not load Triangulum")
		return false
	var planet: Dictionary = solar_system.get_target_state(CH06_LENTIS)
	if not bool(planet.get("valid", false)):
		push_error("CH08: Lentis target unavailable")
		return false
	# The existing safe-resume offset follows the real planet's current orbit.
	_camera_following = true
	_camera_returning = false
	_map_camera_flying = false
	velocity = Vector2.ZERO
	current_input = Vector2.ZERO
	joystick.clear_input()
	ship.throttle = 0.0
	_landing_target_id = ""
	_landing_target_name = ""
	action_button.set_action_mode("use")
	action_button.set_action_available(false)
	_story_move_to(planet["world"] + Vector2(float(planet.get("arrival_radius", 200.0)) + 155.0, 0.0))
	return true

func _ch08_return_to_lentis(without_mika: bool = false) -> void:
	if StoryProgress.read_mode() != "story":
		return
	_ch08_close_completion()
	if not _ch08_place_at_lentis():
		return
	if is_instance_valid(_comic_prologue):
		_comic_prologue.finish()
	if is_instance_valid(_planet_hub):
		_planet_hub.hide()
	if is_instance_valid(_v104_crossroads_dialog):
		_v104_crossroads_dialog.hide()
	_story_simulator_required = false
	var returned: String = "crossroads_ending2_returned" if without_mika else "crossroads_ending1_returned"
	# Save the selected branch and crew before leaving story mode.
	_ch06_restore_flight(returned)
	_ch08_apply_crew()
	if StoryProgress.completed_ending_beat() == returned:
		if StoryProgress.write_mode("free_world"):
			_story_phase = "inactive"
			_sync_bubble_story_access()
			_story_refresh_local_route()
			_story_refresh_galaxy_route()
	else:
		push_warning("CH08: ending checkpoint was not persisted; keeping Story mode")
	diagnostics.write("story_ch08_ending_returned", {"region": "m33", "planet": CH06_LENTIS, "mika_onboard": StoryProgress.mika_onboard(), "mode": StoryProgress.read_mode()})

# MIKA_CH08_ENDING_TWO_V1
func _ch08_begin_ending_two() -> void:
	if _story_phase != "crossroads_finale_choice" or StoryProgress.read_mode() != "story":
		return
	_ch08_play_ending_two()

func _ch08_play_ending_two() -> void:
	_ch07_close_choice()
	_ch08_close_draw()
	if _autopilot_active:
		_stop_autopilot("ch08_ending_two")
	velocity = Vector2.ZERO
	current_input = Vector2.ZERO
	joystick.clear_input()
	ship.throttle = 0.0
	ship.hide()
	_planet_landing_active = true
	_story_show_panels("crossroads_ending2_panels", CH08_ENDING_TWO_PANELS)

func _ch08_open_draw(show_note: bool) -> void:
	if StoryProgress.read_mode() != "story" or is_instance_valid(_ch08_draw_layer):
		return
	var native: PackedScene = load("res://learning/scenes/features/draw_this/draw_this_game.tscn") as PackedScene
	var adapter: Script = load("res://learning/src/features/draw_this/MIKAStoryFreeDraw.gd") as Script
	if native == null or adapter == null:
		push_error("CH08: Draw It resources unavailable")
		return
	var game: Node = native.instantiate()
	game.set_script(adapter)
	if not game.has_signal("finale_finished") or not game.has_signal("drawing_started"):
		game.free()
		push_error("CH08: Draw It adapter invalid")
		return
	game.set("start_with_intro", show_note)
	game.connect("drawing_started", Callable(self, "_ch08_drawing_started"))
	game.connect("finale_finished", Callable(self, "_ch08_drawing_finished"))
	_story_set_phase("crossroads_ending2_note" if show_note else "crossroads_ending2_draw")
	_ch07_close_choice()
	if is_instance_valid(_comic_prologue):
		_comic_prologue.finish()
	_intro_comic_playing = false
	_intro_space_flying = false
	_planet_landing_active = true
	_gameplay_hud.hide()
	ship.hide()
	get_tree().paused = true
	_set_music_context("calm")
	_ch08_draw_layer = CanvasLayer.new()
	_ch08_draw_layer.name = "CH08NativeFreeDrawLayer"
	_ch08_draw_layer.layer = 3
	_ch08_draw_layer.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(_ch08_draw_layer)
	_ch08_draw_layer.add_child(game)

func _ch08_drawing_started() -> void:
	if _story_phase == "crossroads_ending2_note":
		_story_set_phase("crossroads_ending2_draw")

func _ch08_drawing_finished(include_drawing: bool, drawing: Image) -> void:
	if _story_phase != "crossroads_ending2_draw":
		return
	diagnostics.write("story_ch08_drawing_finished", {"include_drawing": include_drawing, "export_available": true})
	_ch08_close_draw()
	call_deferred("_ch08_open_completion", drawing if include_drawing else null, true)

func _ch08_finish_ending_two() -> void:
	if _story_phase != "crossroads_ending2_draw":
		return
	_ch08_close_draw()
	_ch08_return_to_lentis(true)

func _ch08_open_completion(drawing: Image, ending_two: bool) -> void:
	if is_instance_valid(_ch08_completion_layer):
		return
	var screen_script: Script = load("res://mika_motion_comic/scripts/comic_completion_screen.gd") as Script
	if screen_script == null:
		push_error("CH08: comic completion screen unavailable")
		_ch08_return_to_lentis(ending_two)
		return
	if is_instance_valid(_comic_prologue):
		_comic_prologue.finish()
	_intro_comic_playing = false
	_intro_space_flying = false
	_planet_landing_active = true
	_gameplay_hud.hide()
	ship.hide()
	get_tree().paused = true
	_set_music_context("calm")
	var screen: Control = screen_script.new() as Control
	screen.call("setup", drawing)
	screen.connect("continue_pressed", Callable(self, "_ch08_completion_continue").bind(ending_two))
	_ch08_completion_layer = CanvasLayer.new()
	_ch08_completion_layer.name = "CH08ComicDownloadLayer"
	_ch08_completion_layer.layer = 4
	_ch08_completion_layer.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(_ch08_completion_layer)
	_ch08_completion_layer.add_child(screen)

func _ch08_completion_continue(ending_two: bool) -> void:
	_ch08_close_completion()
	call_deferred("_ch08_return_to_lentis", ending_two)

func _ch08_close_completion() -> void:
	if is_instance_valid(_ch08_completion_layer):
		if _ch08_completion_layer.get_parent() != null:
			_ch08_completion_layer.get_parent().remove_child(_ch08_completion_layer)
		_ch08_completion_layer.queue_free()
	_ch08_completion_layer = null

func _ch08_close_draw() -> void:
	if is_instance_valid(_ch08_draw_layer):
		if _ch08_draw_layer.get_parent() != null:
			_ch08_draw_layer.get_parent().remove_child(_ch08_draw_layer)
		_ch08_draw_layer.queue_free()
	_ch08_draw_layer = null

func _ch08_apply_crew() -> void:
	# Native flight has a ship sprite, not a rendered character roster.
	# Keep the explicit persisted crew state available to the ship and simulator.
	if is_instance_valid(ship):
		ship.set_meta("mika_onboard", StoryProgress.mika_onboard())
		ship.set_meta("crew_lead", StoryProgress.crew_lead())
	if is_instance_valid(main_menu):
		main_menu.set_meta("mika_onboard", StoryProgress.mika_onboard())
		main_menu.set_meta("crew_lead", StoryProgress.crew_lead())
