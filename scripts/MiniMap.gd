extends Control
## North-up Solar System map. Ships can leave the Solar System: the map
## smoothly follows the ship outside the outer orbit and returns to the
## Sun-centered overview on re-entry. The ship never teleports.
## All planet indicators use actual orbital coordinates (no backdrop dots).

signal map_navigate_requested(world_position: Vector2)
signal tracking_mode_changed(mode: String)

const WorldAddress = preload("res://scripts/WorldPosition.gd")
# The round chart almost completely fills this SQUARE panel. The sight button
# sits in the naturally unused lower-right corner, outside the chart circle.
const PANEL: Vector2 = Vector2(260.0, 260.0)
const MAP_CENTER: Vector2 = Vector2(130.0, 130.0)
const MAP_RADIUS: float = 126.0
const DEFAULT_UNITS_PER_PIXEL: float = 19.0
const MAP_FOLLOW_SMOOTHNESS: float = 5.5
const SHIP_INSIDE_RADIUS_RATIO: float = 0.54

var _ship_position = WorldAddress.new()
var _map_position = WorldAddress.new()
var _ship_heading: float = 0.0
var _camera_offset: Vector2 = Vector2.ZERO
# Exact visible world extent, as supplied by Main._layout when the viewport changes.
var _camera_view_world_size: Vector2 = Vector2(1280.0, 720.0)
var _units_per_pixel: float = DEFAULT_UNITS_PER_PIXEL
var _touch_index: int = -1
var _touch_origin: Vector2 = Vector2.ZERO
var _touch_final: Vector2 = Vector2.ZERO
var _touch_moved: bool = false
var _following_outside: bool = false
var _solar_bodies: Array[Dictionary] = []
var _outer_orbit_radius: float = 1950.0
var _panel_style: StyleBoxFlat
# Temporary development marker for the distant black hole. Disabling this
# restores the child's map without changing the secret object in the world.
var _debug_landmark_enabled: bool = false
var _debug_landmark_world: Vector2 = Vector2.ZERO


func _ready() -> void:
	custom_minimum_size = PANEL
	size = PANEL
	mouse_filter = Control.MOUSE_FILTER_STOP
	_panel_style = StyleBoxFlat.new()
	_panel_style.bg_color = Color(0.035, 0.16, 0.27, 0.87)
	_panel_style.border_color = Color(0.39, 0.79, 1.0, 0.64)
	_panel_style.set_border_width_all(2)
	_panel_style.set_corner_radius_all(24)
	_panel_style.shadow_color = Color(0.01, 0.04, 0.08, 0.28)
	_panel_style.shadow_size = 4
	queue_redraw()


func reset_for_region() -> void:
	_map_position = WorldAddress.new()
	_following_outside = false
	_units_per_pixel = DEFAULT_UNITS_PER_PIXEL
	_camera_offset = Vector2.ZERO
	queue_redraw()


func set_ship_location(world_sector: Vector2i, local: Vector2, heading: float) -> void:
	_ship_position.sector = world_sector
	_ship_position.local = local
	_ship_heading = heading
	queue_redraw()


func set_camera_offset(offset: Vector2) -> void:
	if _camera_offset.is_equal_approx(offset):
		return
	_camera_offset = offset
	queue_redraw()


func set_camera_view_size(view_world_size: Vector2) -> void:
	# Camera has unit zoom in this 2D prototype: screen pixels equal world units.
	_camera_view_world_size = Vector2(maxf(1.0, view_world_size.x), maxf(1.0, view_world_size.y))
	queue_redraw()


func set_solar_bodies(bodies: Array[Dictionary], outer_orbit_radius: float) -> void:
	_solar_bodies = bodies
	_outer_orbit_radius = outer_orbit_radius
	queue_redraw()


func set_debug_landmark(world_position: Vector2, enabled: bool) -> void:
	_debug_landmark_world = world_position
	_debug_landmark_enabled = enabled
	queue_redraw()


func _debug_landmark_map_point() -> Vector2:
	var actual: Vector2 = _world_to_map(_debug_landmark_world)
	var relative: Vector2 = actual - MAP_CENTER
	if relative.length() > MAP_RADIUS - 18.0:
		return MAP_CENTER + relative.normalized() * (MAP_RADIUS - 18.0)
	return actual


func _near_debug_landmark(point: Vector2) -> bool:
	return _debug_landmark_enabled and point.distance_to(_debug_landmark_map_point()) < 15.0


func _process(delta: float) -> void:
	var ship_world: Vector2 = Vector2(_ship_position.sector) * WorldAddress.SECTOR_SIZE + _ship_position.local
	var distance_from_sun: float = ship_world.length()
	# Hysteresis prevents flickering between modes near the last orbit.
	var enter_distance: float = maxf(_outer_orbit_radius + 120.0, MAP_RADIUS * _units_per_pixel * 0.89)
	var exit_distance: float = maxf(_outer_orbit_radius - 80.0, enter_distance * 0.78)
	var new_following: bool = _following_outside
	if _following_outside and distance_from_sun < exit_distance:
		new_following = false
	elif not _following_outside and distance_from_sun > enter_distance:
		new_following = true
	if new_following != _following_outside:
		_following_outside = new_following
		tracking_mode_changed.emit("outside_follow" if _following_outside else "solar_overview")

	var delta_to_target: Vector2
	if _following_outside:
		# Keep the ship a little ahead of the map center, while allowing the
		# Sun, orbits and other planets to drift behind the screen naturally.
		var direction: Vector2 = ship_world.normalized()
		var ship_relative: Vector2 = _ship_position.displacement_from(_map_position)
		var trailing_distance: float = MAP_RADIUS * _units_per_pixel * SHIP_INSIDE_RADIUS_RATIO
		delta_to_target = ship_relative - direction * trailing_distance
	else:
		# Return to true system origin; do not reparent objects or reset world.
		var map_world: Vector2 = Vector2(_map_position.sector) * WorldAddress.SECTOR_SIZE + _map_position.local
		delta_to_target = -map_world

	if delta_to_target.length_squared() > 0.005:
		var alpha: float = 1.0 - exp(-MAP_FOLLOW_SMOOTHNESS * delta)
		_map_position.advance(delta_to_target * alpha)
		queue_redraw()


func _gui_input(event: InputEvent) -> void:
	# One tap moves the main camera, never the ship. The purple development
	# landmark is allowed to point outside the current solar-map crop.
	if event is InputEventScreenTouch:
		if event.pressed and _touch_index == -1:
			_touch_index = event.index
			_touch_origin = event.position
			_touch_final = event.position
			_touch_moved = false
			accept_event()
		elif not event.pressed and event.index == _touch_index:
			if not _touch_moved:
				if _near_debug_landmark(_touch_final):
					map_navigate_requested.emit(_debug_landmark_world)
				elif _in_disc(_touch_final, 3.0):
					_request_view(_touch_final)
			_touch_index = -1
			accept_event()
	elif event is InputEventScreenDrag and event.index == _touch_index:
		_touch_final = event.position
		if _touch_origin.distance_to(event.position) > 16.0:
			_touch_moved = true
		accept_event()
	elif event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				if _near_debug_landmark(event.position):
					map_navigate_requested.emit(_debug_landmark_world)
				elif _in_disc(event.position, 3.0):
					_request_view(event.position)
			accept_event()


func _request_view(point: Vector2) -> void:
	var origin: Vector2 = Vector2(_map_position.sector) * WorldAddress.SECTOR_SIZE + _map_position.local
	var requested: Vector2 = origin + (point - MAP_CENTER) * _units_per_pixel
	map_navigate_requested.emit(requested)


func _draw() -> void:
	draw_style_box(_panel_style, Rect2(Vector2.ZERO, PANEL))
	draw_circle(MAP_CENTER, MAP_RADIUS, Color(0.012, 0.044, 0.092, 0.98))
	draw_arc(MAP_CENTER, MAP_RADIUS - 1.0, 0.0, TAU, 120, Color(0.39, 0.83, 1.0, 0.64), 1.5, true)
	_draw_orbits()
	_draw_planets()
	_draw_ship()
	_draw_camera_marker()
	_draw_debug_landmark()


func _draw_orbits() -> void:
	var sun_screen: Vector2 = _world_to_map(Vector2.ZERO)
	for body in _solar_bodies:
		var radius: float = float(body.get("orbit", 0.0))
		if radius <= 0.0:
			continue
		var screen_radius: float = radius / _units_per_pixel
		if sun_screen.distance_to(MAP_CENTER) + screen_radius < MAP_RADIUS - 3.0:
			draw_arc(sun_screen, screen_radius, 0.0, TAU, 128, Color(0.39, 0.65, 0.84, 0.20), 0.85, true)
			continue
		# We clip every line to the circular chart; no markers outside the circle.
		var previous: Vector2 = sun_screen + Vector2.RIGHT * screen_radius
		for k in range(1, 181):
			var angle: float = TAU * float(k) / 180.0
			var next_point: Vector2 = sun_screen + Vector2(cos(angle), sin(angle)) * screen_radius
			if _in_disc(previous, 3.0) and _in_disc(next_point, 3.0):
				draw_line(previous, next_point, Color(0.39, 0.65, 0.84, 0.20), 0.85, true)
			previous = next_point


func _draw_planets() -> void:
	for body in _solar_bodies:
		var world: Vector2 = body["world"]
		var point: Vector2 = _world_to_map(world)
		var name: String = str(body["name"])
		var col: Color = body["color"]
		if name == "EarthStation":
			if not _in_disc(point, 6.0):
				continue
			draw_rect(Rect2(point - Vector2(3.5, 3.5), Vector2(7.0, 7.0)), Color(0.99, 0.81, 0.40), true)
			draw_line(point + Vector2(-6.0, 0.0), point + Vector2(6.0, 0.0), Color(1.0, 0.95, 0.77), 1.2, true)
		elif name == "Sun":
			if not _in_disc(point, 10.0):
				continue
			draw_circle(point, 8.5, Color(1.0, 0.60, 0.10, 0.11))
			draw_circle(point, 5.0, Color(1.0, 0.68, 0.15, 1.0))
		elif name == "Moon":
			if not _in_disc(point, 3.0):
				continue
			draw_circle(point, 1.6, Color(0.84, 0.87, 0.95, 0.95))
		elif name == "Earth":
			if not _in_disc(point, 5.0):
				continue
			draw_circle(point, 3.2, Color(0.29, 0.70, 1.0, 1.0))
			draw_circle(point + Vector2(-0.8, -0.6), 0.8, Color(0.43, 0.88, 0.58, 0.92))
		else:
			if not _in_disc(point, 6.0):
				continue
			var dot_size: float = 3.3 if name == "Jupiter" or name == "Saturn" else 2.7
			draw_circle(point, dot_size, col)
			if name == "Saturn":
				draw_arc(point, 4.7, 0.15, PI * 1.30, 24, Color(0.98, 0.86, 0.55, 0.75), 1.0, true)


func _draw_ship() -> void:
	var offset: Vector2 = _ship_position.displacement_from(_map_position)
	var point: Vector2 = MAP_CENTER + offset / _units_per_pixel
	var direction: Vector2 = point - MAP_CENTER
	if direction.length() > MAP_RADIUS - 6.0:
		# Only while manually inspecting or during an eased map transition.
		point = MAP_CENTER + direction.normalized() * (MAP_RADIUS - 6.0)
	draw_circle(point, 5.3, Color(0.31, 0.89, 1.0, 0.12))
	draw_circle(point, 2.8, Color(0.64, 0.98, 1.0, 0.98))


func _draw_camera_marker() -> void:
	# Draw the ACTUAL visible viewport footprint: width/height preserve screen
	# aspect ratio. No tiny marker square or fake fixed-size camera box.
	# The outline is clipped at the circular mini-map boundary.
	var camera_center_world: Vector2 = _ship_position.displacement_from(_map_position) + _camera_offset
	var center: Vector2 = MAP_CENTER + camera_center_world / _units_per_pixel
	var half_size: Vector2 = _camera_view_world_size / (_units_per_pixel * 2.0)
	var top_left: Vector2 = center - half_size
	var top_right: Vector2 = center + Vector2(half_size.x, -half_size.y)
	var bottom_right: Vector2 = center + half_size
	var bottom_left: Vector2 = center + Vector2(-half_size.x, half_size.y)
	var border_color: Color = Color(1.0, 0.83, 0.33, 0.97)
	_draw_clipped_view_edge(top_left, top_right, border_color)
	_draw_clipped_view_edge(top_right, bottom_right, border_color)
	_draw_clipped_view_edge(bottom_right, bottom_left, border_color)
	_draw_clipped_view_edge(bottom_left, top_left, border_color)


func _draw_clipped_view_edge(start: Vector2, finish: Vector2, color: Color) -> void:
	# Exact segment/disk clipping. Unlike clamping the rectangle center,
	# this preserves the true camera footprint when it crosses the map edge.
	var direction: Vector2 = finish - start
	var a: float = direction.length_squared()
	if a < 0.000001:
		return
	var origin: Vector2 = start - MAP_CENTER
	var b: float = 2.0 * origin.dot(direction)
	var r: float = MAP_RADIUS - 3.5
	var c: float = origin.length_squared() - r * r
	var discr: float = b * b - 4.0 * a * c
	var intervals: Array[float] = [0.0, 1.0]
	if discr >= 0.0:
		var root: float = sqrt(discr)
		var cross_a: float = (-b - root) / (2.0 * a)
		var cross_b: float = (-b + root) / (2.0 * a)
		if cross_a > 0.0 and cross_a < 1.0:
			intervals.append(cross_a)
		if cross_b > 0.0 and cross_b < 1.0:
			intervals.append(cross_b)
	intervals.sort()
	for i in range(intervals.size() - 1):
		var lo: float = intervals[i]
		var hi: float = intervals[i + 1]
		if hi - lo < 0.00001:
			continue
		var midpoint: Vector2 = start + direction * ((lo + hi) * 0.5)
		if midpoint.distance_squared_to(MAP_CENTER) < r * r:
			draw_line(start + direction * lo, start + direction * hi, color, 1.9, true)


func _in_disc(point: Vector2, margin: float) -> bool:
	return point.distance_squared_to(MAP_CENTER) <= pow(MAP_RADIUS - margin, 2.0)


func _world_to_map(world: Vector2) -> Vector2:
	var origin: Vector2 = Vector2(_map_position.sector) * WorldAddress.SECTOR_SIZE + _map_position.local
	return MAP_CENTER + (world - origin) / _units_per_pixel


func _draw_debug_landmark() -> void:
	if not _debug_landmark_enabled:
		return
	var point: Vector2 = _debug_landmark_map_point()
	var tone: Color = Color(0.87, 0.44, 1.0, 0.96)
	var corners: PackedVector2Array = PackedVector2Array([
		point + Vector2(0.0, -7.0), point + Vector2(7.0, 0.0),
		point + Vector2(0.0, 7.0), point + Vector2(-7.0, 0.0)
	])
	draw_circle(point, 11.0, Color(0.53, 0.24, 0.89, 0.18))
	draw_colored_polygon(corners, tone)
	draw_circle(point, 2.7, Color(0.10, 0.04, 0.20, 1.0))
