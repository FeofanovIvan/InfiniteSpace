extends Node2D
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
const MikoMainMenuScene = preload("res://scripts/MikoMainMenu.gd")
const ComicPrologueScene = preload("res://scripts/ComicPrologue.gd")
const StoryLandingSmokeScene = preload("res://scripts/StoryLandingSmoke.gd")
const LandingMotion = preload("res://scripts/LandingMotion.gd")
const HyperjumpMotion = preload("res://scripts/HyperjumpMotion.gd")

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
# The intro flies to Earth, then uses EXACTLY the NPC anchored landing
# stages: approach, hover, scale-down. No crash or impact smoke.
const STORY_CRUISE_END: float = 9.7
const STORY_APPROACH_END: float = STORY_CRUISE_END + NpcTrafficScene.APPROACH_TIME
const STORY_HOVER_END: float = STORY_APPROACH_END + NpcTrafficScene.HOVER_TIME
const STORY_LANDING_END: float = STORY_HOVER_END + NpcTrafficScene.LANDING_TIME
const STORY_EJECTION_START: Vector2 = Vector2(6320.0, -2865.0)
const STORY_CONTROL_ONE: Vector2 = Vector2(4780.0, -2450.0)
const STORY_CONTROL_TWO: Vector2 = Vector2(2320.0, -550.0)
const STORY_APPROACH_OFFSET: Vector2 = Vector2(-177.0, -103.0)


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
var _gameplay_hud: Control
var _comic_prologue
var _story_smoke
var _intro_comic_playing: bool = false
var _intro_space_flying: bool = false
var _intro_time: float = 0.0
var _intro_landing_offset: Vector2 = Vector2.ZERO
var _intro_landing_direction: Vector2 = Vector2.UP
var _intro_approach_started: bool = false
# v57: tuneable normal-flight fuel. Hyperjumps and story flights remain free.
const FUEL_CAPACITY: float = 50.0
const FUEL_MAX_DRAIN_PER_SECOND: float = 1.8
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


func _ready() -> void:
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
	_story_smoke = StoryLandingSmokeScene.new()
	_story_smoke.name = "EarthLandingSmoke_FromPrologue"
	_story_smoke.z_index = 12
	_story_smoke.visible = false
	add_child(_story_smoke)

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
	_start_story_comic()


func _physics_process(delta: float) -> void:
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
		if Input.is_key_pressed(KEY_SPACE):
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
	if velocity.length_squared() > 1.0 and _fuel_units > 0.0:
		_fuel_units = maxf(0.0, _fuel_units - FUEL_MAX_DRAIN_PER_SECOND * clampf(velocity.length() / MAX_SPEED, 0.0, 1.0) * delta)
		_refresh_fuel_hud()
	if _fuel_units <= 0.0:
		if _autopilot_active:
			_stop_autopilot("fuel_empty")
		velocity = Vector2.ZERO
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

	status_hud = ResourceHudScene.new()
	status_hud.name = "Fuel_Crystals_Galaxy_MikoMenu"
	root.add_child(status_hud)
	status_hud.set_fuel_segments(INITIAL_FUEL_SEGMENTS)
	status_hud.set_crystals(INITIAL_CRYSTALS)
	status_hud.galaxy_requested.connect(_on_galaxy_requested)
	status_hud.main_menu_requested.connect(_on_main_menu_requested)

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

	# v38: empty, localized landing-preview screen (no surface gameplay yet).
	landing_preview = LandingPreviewScene.new()
	landing_preview.name = "LandingPreview_EmptyScreen"
	root.add_child(landing_preview)
	landing_preview.closed.connect(_on_landing_preview_closed)

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
	var desired_content_height: float = NavigationMenuScene.TRIGGER_SIZE * goals_scale + 34.0 * hud_scale + 2.0 * lower_button_local_size * hud_scale
	var usable_content_height: float = joystick.position.y - safe.position.y - 12.0 - 8.0 - rail_gap * 3.0
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
	var button_local_x: float = lower_button_center_local - lower_button_local_size * 0.5
	var local_gap: float = rail_gap / hud_scale
	var first_button_y: float = 34.0 + local_gap
	var second_button_y: float = first_button_y + lower_button_local_size + local_gap
	galaxy_button.scale = Vector2.ONE * lower_button_extra
	galaxy_button.position = Vector2(button_local_x, first_button_y)
	ship_menu_button.scale = Vector2.ONE * lower_button_extra
	ship_menu_button.position = Vector2(button_local_x, second_button_y)
	status_hud.size = Vector2(ResourceHudScene.HUD_WIDTH, second_button_y + lower_button_local_size)
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


func _refresh_fuel_hud() -> void:
	status_hud.set_fuel_segments(ceili((_fuel_units / FUEL_CAPACITY) * 7.0))
	status_hud.set_crystals(floori(_fuel_units + 0.001))


func _on_fuel_collected(units: int) -> void:
	if units <= 0:
		return
	var previous: float = _fuel_units
	_fuel_units = minf(FUEL_CAPACITY, _fuel_units + float(units))
	_refresh_fuel_hud()
	diagnostics.write("fuel_collected", {"received": units, "added": snappedf(_fuel_units - previous, 0.01), "fuel": snappedf(_fuel_units, 0.01)})


func _on_asteroid_impact(asteroid_type: int, target_name: String, world_position: Vector2) -> void:
	# Contact is visual for now; no fuel penalty or automatic crystal pickup.
	if target_name == "Player":
		var ship_world: Vector2 = Vector2(navigator.sector) * WorldAddress.SECTOR_SIZE + navigator.local
		var knock: Vector2 = ship_world - world_position
		if knock.length_squared() > 1.0:
			velocity += knock.normalized() * 135.0
	diagnostics.write("asteroid_impact", {"type": asteroid_type, "target": target_name, "x": snappedf(world_position.x, 1.0), "y": snappedf(world_position.y, 1.0)})


func _on_joystick_changed(direction: Vector2) -> void:
	if not _autopilot_active and not _warp_active:
		current_input = direction


func _on_galaxy_requested() -> void:
	if _warp_active or _intro_comic_playing or _intro_space_flying:
		return
	if main_menu.visible:
		return
	galactic_map.open_map(get_viewport_rect().size, solar_system.current_id)
	get_tree().paused = true
	diagnostics.write("galactic_map_opened", {"current": solar_system.current_id, "destinations": 7})


func _on_main_menu_requested() -> void:
	if _warp_active or _intro_comic_playing or _intro_space_flying:
		return
	if galactic_map.visible:
		return
	main_menu.set_stats(status_hud.crystal_count, 0, 0.0)
	main_menu.open_menu(get_viewport_rect().size)
	get_tree().paused = true
	diagnostics.write("miko_main_menu_opened", {"screen": "bridge", "flight_crystals": status_hud.crystal_count, "crystal_capacity": 0, "ship_speed": 0})


func _on_educational_crystals_earned(units: int) -> void:
	# Correct answers in locally copied Play Town games refill the fuel tank.
	_on_fuel_collected(units)


func _on_modal_closed() -> void:
	if _planet_landing_active and is_instance_valid(_planet_hub):
		_planet_hub.visible = true
		get_tree().paused = true
		return
	get_tree().paused = false
	diagnostics.write("flight_overlay_closed", {})


func _on_galaxy_travel_requested(region_id: String, direction: Vector2) -> void:
	if _intro_comic_playing or _intro_space_flying or _warp_active:
		return
	if solar_system.get_system(region_id).is_empty():
		return
	get_tree().paused = false
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
				_warp_phase = "transit"
				_warp_time = 0.0
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
				_gameplay_hud.visible = true
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
	# Destination counts change the menu's actual width. Re-anchor the preview
	# immediately after every inter-system arrival, not only on window resize.
	_layout()
	goal_picker.visible = region_id != "crossroads"
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
	if _warp_active:
		return
	var state: Dictionary = solar_system.get_target_state(target_id)
	if not bool(state.get("valid", false)):
		diagnostics.write("autopilot_invalid_target", {"target": target_id})
		return
	_autopilot_target = target_id
	_autopilot_active = true
	current_input = Vector2.ZERO
	joystick.clear_input()
	joystick.visible = false
	auto_stop_button.visible = true
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
		_stop_autopilot("arrived")
		return
	# Predict the moving body's future location. Lead time diminishes near it.
	var lead_seconds: float = clampf((distance - arrival_radius) / AUTO_CRUISE_SPEED, 0.0, 1.25)
	var intercept: Vector2 = destination + target_velocity * lead_seconds
	var aim: Vector2 = (intercept - ship_world).normalized()
	var remaining: float = maxf(0.0, distance - arrival_radius)
	var desired_speed: float = minf(AUTO_CRUISE_SPEED, sqrt(2.0 * AUTO_BRAKE_ACCEL * remaining))
	var desired_velocity: Vector2 = aim * desired_speed + target_velocity
	velocity = velocity.move_toward(desired_velocity.limit_length(MAX_SPEED), AUTO_STEERING_ACCEL * delta)


func _on_auto_stop_pressed() -> void:
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
	diagnostics.write("autopilot_stopped", {"reason": reason, "target": previous_target, "ship": navigator.as_dictionary()})


func _update_landing_offer() -> void:
	# Planetary landings only on explicitly inhabited worlds; stations are ports.
	if _warp_active or _intro_comic_playing or _intro_space_flying or get_tree().paused:
		return
	var ship_world: Vector2 = _ship_world()
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


func _start_story_comic() -> void:
	# Full-screen comic is a one-time intro; children can skip without reading.
	if _comic_prologue == null:
		_comic_prologue = ComicPrologueScene.new()
		_comic_prologue.name = "MikoComicPage1CameraStory"
		add_child(_comic_prologue)
		_comic_prologue.comic_completed.connect(_begin_story_space_flight)
		_comic_prologue.skipped.connect(_skip_story)
	_intro_comic_playing = true
	_intro_space_flying = false
	_intro_time = 0.0
	_intro_approach_started = false
	velocity = Vector2.ZERO
	current_input = Vector2.ZERO
	joystick.clear_input()
	if _autopilot_active:
		_stop_autopilot("intro_replayed")
	_gameplay_hud.visible = false
	ship.visible = true
	ship.scale = Vector2.ONE
	ship.modulate = Color.WHITE
	_story_smoke.visible = false
	_comic_prologue.begin()
	get_tree().paused = true
	diagnostics.write("prologue_comic_started", {"panels": 9, "source": "nine_full_originals_with_two_added_disaster_scenes"})


func _begin_story_space_flight() -> void:
	get_tree().paused = false
	_intro_comic_playing = false
	_intro_space_flying = true
	_intro_time = 0.0
	_comic_prologue.begin_space_sequence()
	_camera_following = true
	_camera_returning = false
	_map_camera_flying = false
	_camera_offset = Vector2.ZERO
	_story_move_to(_story_position(0.0))
	_ship_heading = -0.7
	ship.rotation = _ship_heading
	diagnostics.write("prologue_space_started", {"origin": "black_hole", "mode": "continuous_uncontrolled_direct_earth_fall"})


func _skip_story() -> void:
	get_tree().paused = false
	_intro_comic_playing = false
	_intro_space_flying = false
	_story_smoke.visible = false
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
	_story_move_to(solar_system.earth_world_position() + Vector2(170.0, -80.0))
	_gameplay_hud.visible = true
	diagnostics.write("prologue_skipped", {})


func _story_position(t: float) -> Vector2:
	# Cubic Bezier ejection: one continuous curve, no per-waypoint braking.
	# The ship points away from its velocity during initial tumble, then
	# follows the accelerating descent into the CURRENT position of Earth.
	var u: float = clampf(t / STORY_CRUISE_END, 0.0, 1.0)
	var accelerated: float = 0.84 * u + 0.16 * u * u
	var v: float = 1.0 - accelerated
	var earth: Vector2 = solar_system.earth_world_position() + STORY_APPROACH_OFFSET
	return v * v * v * STORY_EJECTION_START + 3.0 * v * v * accelerated * STORY_CONTROL_ONE + 3.0 * v * accelerated * accelerated * STORY_CONTROL_TWO + accelerated * accelerated * accelerated * earth

func _advance_story_flight(delta: float) -> void:
	_intro_time += delta
	var previous_world: Vector2 = _ship_world()
	var earth_world: Vector2 = solar_system.earth_world_position()
	var target_world: Vector2
	var landing_scale: float = 1.0
	var settling: bool = _intro_time >= STORY_CRUISE_END
	if not settling:
		# The original continuous journey is preserved until the NPC approach gate.
		target_world = _story_position(_intro_time)
	elif _intro_time < STORY_APPROACH_END:
		if not _intro_approach_started:
			_intro_approach_started = true
			_intro_landing_offset = previous_world - earth_world
			_intro_landing_direction = _intro_landing_offset.normalized() if _intro_landing_offset.length_squared() > 0.001 else Vector2.UP
		var approach_progress: float = clampf((_intro_time - STORY_CRUISE_END) / NpcTrafficScene.APPROACH_TIME, 0.0, 1.0)
		var end_offset: Vector2 = _intro_landing_direction * NpcTrafficScene.PLANET_LANDING_OFFSET
		target_world = LandingMotion.anchored_approach(earth_world, _intro_landing_offset, end_offset, approach_progress)
		landing_scale = 1.0 - 0.18 * LandingMotion.smooth_step(approach_progress)
	elif _intro_time < STORY_HOVER_END:
		target_world = earth_world + _intro_landing_direction * NpcTrafficScene.PLANET_LANDING_OFFSET
		landing_scale = 0.82
	else:
		# NPC "landing" mode: the ship stays BODY-ANCHORED as Earth moves,
		# scaling to zero over precisely the same 1.12-second interval.
		var landing_progress: float = clampf((_intro_time - STORY_HOVER_END) / NpcTrafficScene.LANDING_TIME, 0.0, 1.0)
		target_world = earth_world + _intro_landing_direction * NpcTrafficScene.PLANET_LANDING_OFFSET
		landing_scale = 0.82 * (1.0 - LandingMotion.smooth_step(landing_progress))

	var displacement: Vector2 = target_world - previous_world
	_story_move_to(target_world)
	ship.throttle = 0.0 if settling else 1.0
	if not settling and displacement.length_squared() > 0.000001:
		var desired: float = displacement.angle() + PI * 0.5
		var wobble: float = 0.115 * sin(_intro_time * 7.6) + 0.058 * sin(_intro_time * 3.1 + 0.4)
		var unstable: float = pow(1.0 - clampf(_intro_time / 2.9, 0.0, 1.0), 2.0)
		var heading_error: float = wrapf(desired + wobble - _ship_heading, -PI, PI)
		_ship_heading += 17.0 * unstable * delta + heading_error * (1.0 - unstable) * minf(1.0, delta * 5.0)
	elif settling:
		# During the Earth descent the nose must point TOWARD the planet, not away from it.
		_ship_heading = lerp_angle(_ship_heading, (-_intro_landing_direction).angle() + PI * 0.5, minf(1.0, delta * 2.6))
	ship.rotation = _ship_heading
	ship.scale = Vector2.ONE * maxf(0.0, landing_scale)
	ship.modulate.a = clampf(landing_scale, 0.0, 1.0)
	var shake: Vector2 = Vector2.ZERO
	if _intro_time < 3.0:
		var strength: float = pow(1.0 - _intro_time / 3.0, 1.5) * 13.0
		shake = Vector2(sin(_intro_time * 31.0), cos(_intro_time * 26.0)) * strength
	ship.position = get_viewport_rect().size * 0.5 - _camera_offset + shake
	_story_smoke.visible = false
	if _intro_time >= STORY_LANDING_END:
		diagnostics.write("story_player_landed", {"planet": "Earth", "npc_landing_logic": true,
			"anchor_distance": NpcTrafficScene.PLANET_LANDING_OFFSET})
		_finish_story_flight()


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


func _finish_story_flight() -> void:
	_intro_space_flying = false
	_comic_prologue.finish()
	_story_smoke.visible = false
	ship.visible = true
	ship.scale = Vector2.ONE
	ship.modulate = Color.WHITE
	ship.throttle = 0.0
	velocity = Vector2.ZERO
	_ship_heading = 0.0
	ship.rotation = 0.0
	_story_move_to(solar_system.earth_world_position() + Vector2(160.0, -80.0))
	_gameplay_hud.visible = true
	diagnostics.write("prologue_complete", {"landing": "Earth", "playable": true, "flight": "npc_style_hover_and_landing"})
	call_deferred("_open_initial_earth_hub")


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
	if _planet_landing_active:
		return
	var hub: Control = _ensure_planet_hub()
	if hub == null:
		return
	_planet_landing_active = true
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
	hub.size = get_viewport_rect().size
	hub.call("show_for_planet", planet_id, display_name, floori(_fuel_units + 0.001))
	get_tree().paused = true
	diagnostics.write("planet_hub_opened", {"planet": planet_id, "inhabited": true})


func _on_planet_hub_flight_requested() -> void:
	if not _planet_landing_active:
		return
	_planet_hub.visible = false
	_planet_landing_active = false
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


func _on_planet_hub_simulator_requested() -> void:
	if not _planet_landing_active:
		return
	_planet_hub.visible = false
	main_menu.set_stats(status_hud.crystal_count, 0, 0.0)
	main_menu.open_menu(get_viewport_rect().size)
	# The normal ship simulator is unchanged; returning opens the planet hub.
	get_tree().paused = true
	diagnostics.write("planet_hub_simulator_opened", {})


func _open_initial_earth_hub() -> void:
	_begin_planet_landing("mw_p01", "Земля", false)

