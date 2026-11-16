extends Node2D
signal exit_requested
# MIKA_STATION_RACING_NATIVE_V2
## Standalone MW racing prototype. No changes to Main.
const Generator = preload("res://space_racing/RaceRouteGenerator.gd")
const Solar = preload("res://scripts/SolarSystem.gd")
const Ship = preload("res://scripts/Ship.gd")
const Stick = preload("res://scripts/Joystick.gd")
const MiniMap = preload("res://scripts/MiniMap.gd")
const Stars = preload("res://scripts/Starfield.gd")
const WorldAddress = preload("res://scripts/WorldPosition.gd")
const MAX_SPEED := 890.0
const THRUST := 580.0
const BRAKE := 3200.0
const WALL_BOUNCE: float = 0.34
const WALL_SPEED_LOSS: float = 0.78
const CONTACT_RADIUS: float = 45.0
const RaceProgress = preload("res://space_racing/RaceProgress.gd")
const RaceSession = preload("res://space_racing/RaceSession.gd")
const Campaign = preload("res://space_racing/RaceCampaign.gd")
const RaceStartAudio = preload("res://space_racing/RaceStartAudio.gd")
# MIKA_RACE_START_MUSIC_AND_LIGHT_SFX_V1
# MIKA_STATION_RACING_CAMPAIGN_V3
var _solar: Node2D
var _stars: Node2D
var _ship: Node2D
var _stick: Control
var _map: Control
var _map_route: Control
var _route_layer: Node2D
var _hud: Control
var _info: Label
var _lights: Control
var _lap_display: Control
var _route: PackedVector2Array = PackedVector2Array()
var _navigator = WorldAddress.new()
var _velocity := Vector2.ZERO
var _input := Vector2.ZERO
var _heading := 0.0
var _clock := 0.0
var _seed := 0
var _variation := 0
var _countdown := 0.0
var _running := false
var _start_world := Vector2.ZERO
var _nearest_index := 0
var _progress_index := 0
var _half_lap_reached: bool = false
var _lap_complete := false
const TOTAL_LAPS: int = 3
var _laps_finished: int = 0
var _base_info: String = ""
var _length_options: Array[float] = [14000.0, 19000.0, 24000.0]
var _length_index: int = 1
var _track_width: float = 650.0
var _length_button: Button
var _rivals: Node2D
var _race_distance: float = 0.0
var _last_progress_index: int = 0
var _race_position: int = 1
var _lap_elapsed: float = 0.0
var _best_lap: float = 0.0
var _planet_id: String = "mw_station"
var _embedded_station_race: bool = false
var _system_id: String = "mw"
var _difficulty: String = "normal"
var _return_scene: String = "res://scenes/main.tscn"
var _scoreboard: Control
var _race_elapsed: float = 0.0
var _exit_button: Button
var _campaign_requested: String = "st_mw"
var _campaign_waiting: bool = false
var _campaign_modal: Control
var _race_audio: Node
var _race_red_pending: bool = false
var _race_green_hold: float = 0.0

func _ready() -> void:
	_race_audio = RaceStartAudio.new()
	_race_audio.name = "StationRaceMusicAndTrafficLights"
	add_child(_race_audio)
	_stars = Stars.new()
	add_child(_stars)
	var incoming_session: Dictionary = get_tree().root.get_meta("mika_race_session_v8", {})
	_campaign_requested = str(incoming_session.get("planet", "st_mw"))
	var target: String = Campaign.target_for(_campaign_requested)
	var locked: bool = target != _campaign_requested
	incoming_session["planet"] = target
	incoming_session["system"] = Campaign.system_for(target)
	incoming_session["difficulty"] = Campaign.difficulty_for(target)
	get_tree().root.set_meta("mika_race_session_v8", incoming_session)
	set_meta("campaign_locked", locked)
	var incoming_system: String = str(incoming_session.get("system", "mw"))
	if incoming_system != "mw":
		_solar = Node2D.new()
		_solar.set_script(preload("res://space_racing/RaceGalaxyBackdrop.gd"))
		_solar.set("system_id", incoming_system)
	else:
		_solar = Solar.new()
		_solar.set_process(false) # Fixed orbits during races.
	add_child(_solar)
	_route_layer = Node2D.new()
	_route_layer.set_script(preload("res://space_racing/RaceVisual.gd"))
	add_child(_route_layer)
	_rivals = Node2D.new()
	_rivals.set_script(preload("res://space_racing/RaceRivals.gd"))
	add_child(_rivals)
	_ship = Ship.new()
	add_child(_ship)
	var layer := CanvasLayer.new()
	add_child(layer)
	_hud = Control.new()
	_hud.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_hud.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(_hud)
	_map = MiniMap.new()
	_hud.add_child(_map)
	_map_route = Control.new()
	_map_route.set_script(preload("res://space_racing/RaceMapOverlay.gd"))
	_map_route.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_map_route.size = Vector2(260, 260)
	_hud.add_child(_map_route)
	_stick = Stick.new()
	_hud.add_child(_stick)
	_stick.direction_changed.connect(func(v: Vector2) -> void: _input = v)
	_info = Label.new()
	_info.add_theme_font_size_override("font_size", 19)
	_info.add_theme_color_override("font_color", Color(0.83, 0.94, 1.0))
	_hud.add_child(_info)
	_info.visible = false # Diagnostic text no longer overlays the game.
	_lights = Control.new()
	_lights.set_script(preload("res://space_racing/RaceLights.gd"))
	_lights.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_hud.add_child(_lights)
	_lap_display = Control.new()
	_lap_display.set_script(preload("res://space_racing/RaceLapHUD.gd"))
	_lap_display.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_hud.add_child(_lap_display)
	_scoreboard = Control.new()
	_scoreboard.set_script(preload("res://space_racing/RaceScoreboard.gd"))
	_scoreboard.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_hud.add_child(_scoreboard)
	_exit_button = Button.new()
	_exit_button.name = "RaceExitButton"
	_exit_button.text = "←"
	_exit_button.tooltip_text = "Return to station"
	_exit_button.add_theme_font_size_override("font_size", 28)
	_exit_button.add_theme_color_override("font_color", Color(0.80, 0.95, 1.0))
	var exit_style := StyleBoxFlat.new()
	exit_style.bg_color = Color(0.025, 0.075, 0.15, 0.92)
	exit_style.border_color = Color(0.24, 0.78, 0.96, 0.9)
	exit_style.set_border_width_all(2)
	exit_style.set_corner_radius_all(19)
	_exit_button.add_theme_stylebox_override("normal", exit_style)
	var exit_hover: StyleBoxFlat = exit_style.duplicate()
	exit_hover.bg_color = Color(0.08, 0.22, 0.34, 0.98)
	_exit_button.add_theme_stylebox_override("hover", exit_hover)
	_exit_button.add_theme_stylebox_override("focus", exit_hover)
	var exit_pressed: StyleBoxFlat = exit_style.duplicate()
	exit_pressed.bg_color = Color(0.12, 0.35, 0.48, 1.0)
	_exit_button.add_theme_stylebox_override("pressed", exit_pressed)
	_exit_button.focus_mode = Control.FOCUS_NONE
	_exit_button.mouse_filter = Control.MOUSE_FILTER_STOP
	_exit_button.pressed.connect(_leave_race)
	_hud.add_child(_exit_button)
	var session: Dictionary = RaceSession.take()
	_planet_id = str(session.get("planet", "mw_station"))
	_embedded_station_race = bool(session.get("embedded", false))
	_system_id = str(session.get("system", "mw"))
	_rivals.call("set_system_id", _system_id)
	_difficulty = str(session.get("difficulty", "normal"))
	_return_scene = str(session.get("return_scene", "res://scenes/main.tscn"))
	_best_lap = RaceProgress.best_lap(_planet_id, _difficulty)
	match _difficulty:
		"easy": _length_index = 0
		"hard": _length_index = 2
		_: _length_index = 1
	_seed = int(Time.get_unix_time_from_system())
	_layout()
	_apply_route()
	_rivals.set("active", false)
	if bool(get_meta("campaign_locked", false)):
		_campaign_waiting = true
		_mika_campaign_dialog("Сначала выиграйте гонку в %s.\nНачать её сейчас?\nПосле выхода вы вернётесь на исходную станцию." % Campaign.name_for(_planet_id), "Начать", _mika_campaign_confirm, "Отмена", _leave_race)
	get_viewport().size_changed.connect(_layout)

func _new_route() -> void:
	_seed += 137
	_variation = 0
	_apply_route()

func _apply_route() -> void:
	var result: Dictionary = Generator.generate(_seed + _variation * 104729, _length_options[_length_index], _track_width)
	_route = result["points"]
	if _route.size() < 4:
		return
	_start_world = _route[0]
	var direction: Vector2 = (_route[1] - _route[0]).normalized()
	var spawn: Vector2 = _start_world - direction * 70.0
	_navigator.sector = Vector2i(floori(spawn.x / 512.0), floori(spawn.y / 512.0))
	_navigator.local = spawn - Vector2(_navigator.sector) * 512.0
	_velocity = Vector2.ZERO
	_heading = direction.angle() + PI * 0.5
	_input = Vector2.ZERO
	_stick.call("clear_input")
	_clock = 0.0
	_countdown = 3.0
	_race_red_pending = true
	_race_green_hold = 0.0
	_race_audio.call("stop_all")
	_lights.visible = true
	_lights.set("remaining", 3.0)
	_running = false
	_lap_complete = false
	_laps_finished = 0
	_lap_elapsed = 0.0
	_race_elapsed = 0.0
	_race_distance = 0.0
	_last_progress_index = 0
	_race_position = 1
	_rivals.call("configure", _route, _track_width, _seed + _variation * 104729)
	# Increase rival speed slightly at each successive station.
	for racer in _rivals.get("racers"):
		racer["base_speed"] = float(racer["base_speed"]) * Campaign.speed_multiplier(_planet_id)
	_progress_index = 0
	_half_lap_reached = false
	_nearest_index = 0
	_route_layer.set("route", _route)
	_route_layer.set("track_width", _track_width)
	_route_layer.set("start_world", _start_world)
	_route_layer.set("animation_time", 0.0)
	_map_route.set("route", _route)
	_base_info = "TRACK %.0f / TARGET %.0f | WIDTH %.0f | VAR %d | %s" % [float(result["length"]), _length_options[_length_index], _track_width, _variation + 1, "CLEAR" if float(result["clearance"]) >= 0.0 and float(result["corridor_clearance"]) >= 0.0 else "CORRIDOR: REVIEW"]
	_info.text = "PLACE 1/5 | LAP 1/%d | %s" % [TOTAL_LAPS, _base_info]
	_update_camera()

func _layout() -> void:
	var s: Vector2 = get_viewport_rect().size
	if _stars != null:
		_stars.call("resize_field", s)
	if _solar != null:
		_solar.call("resize_view", s)
	if _ship != null:
		_ship.position = s * 0.5
	if _hud == null:
		return
	_hud.size = s
	# Use the same safe-area geometry as the main flight screen.
	var safe: Rect2 = MobileLocale.safe_rect(s)
	var scale_factor: float = clampf(minf(safe.size.x / 1280.0, safe.size.y / 720.0), 0.45, 1.25)
	# 230 scoreboard + 158 laps + 200 joystick + 3 x 12 clearance.
	scale_factor = minf(scale_factor, safe.size.y / 630.0)
	var gap: float = 12.0 * scale_factor
	var edge: float = 12.0 * scale_factor
	var map_scale: float = (0.74 if safe.size.x < 850.0 else 0.87) * scale_factor
	_map.scale = Vector2.ONE * map_scale
	_map.position = safe.position + Vector2(edge, edge)
	_map_route.scale = _map.scale
	_map_route.position = _map.position

	# The joystick is anchored to the lower-right SAFE corner.
	_stick.scale = Vector2.ONE * scale_factor
	_stick.position = Vector2(safe.end.x - 205.0 * scale_factor, safe.end.y - 200.0 * scale_factor - edge)
	var stick_axis_x: float = _stick.position.x + 100.0 * scale_factor
	_info.position = Vector2(safe.position.x + edge, safe.end.y - 44.0 * scale_factor)
	_info.size = Vector2(safe.size.x - 2.0 * edge, 36.0 * scale_factor)
	_lights.position = Vector2(s.x * 0.5 - 97.0 * scale_factor, safe.position.y + edge)
	_lights.size = Vector2(194.0, 70.0) * scale_factor

	# Align the standings, lap rail and joystick to ONE right-hand axis.
	_scoreboard.size = Vector2(320.0, 230.0) * scale_factor
	_scoreboard.position = Vector2(
		clampf(stick_axis_x - _scoreboard.size.x * 0.5, safe.position.x + edge, safe.end.x - edge - _scoreboard.size.x),
		safe.position.y + edge
	)
	_lap_display.size = Vector2(94.0, 158.0) * scale_factor
	var lap_top: float = _scoreboard.position.y + _scoreboard.size.y + gap
	_lap_display.position = Vector2(
		clampf(stick_axis_x - _lap_display.size.x * 0.5, safe.position.x + edge, safe.end.x - edge - _lap_display.size.x),
		lap_top
	)

	_exit_button.size = Vector2(68.0, 62.0) * scale_factor
	_exit_button.position = Vector2(safe.position.x + edge, safe.end.y - edge - _exit_button.size.y)
	_route_layer.set("viewport_size", s)
	if _rivals != null:
		_rivals.set("viewport_size", s)
	_map.call("set_camera_view_size", s)
	_update_camera()
func _physics_process(delta: float) -> void:
	if _campaign_waiting:
		return
	if _route.is_empty():
		return
	_clock += delta
	if _running and not _lap_complete:
		_lap_elapsed += delta
		_race_elapsed += delta
	# Keep green illuminated briefly after launch, without holding the ships.
	if _race_green_hold > 0.0:
		_race_green_hold = maxf(0.0, _race_green_hold - delta)
		if _race_green_hold <= 0.0:
			_lights.visible = false
	if _countdown > 0.0:
		# No countdown sounds while a locked-station confirmation is open.
		if _race_red_pending:
			_race_red_pending = false
			_race_audio.call("signal_light", 0)
		var previous_countdown: float = _countdown
		_countdown = maxf(0.0, _countdown - delta)
		_lights.set("remaining", _countdown)
		if previous_countdown > 2.0 and _countdown <= 2.0:
			_race_audio.call("signal_light", 1)
		if previous_countdown > 1.0 and _countdown <= 1.0:
			# Third sound = green light = movement and music start.
			_race_audio.call("signal_light", 2)
			_countdown = 0.0
			_lights.set("remaining", 0.0)
			_race_green_hold = 0.80
			_running = true
			_rivals.set("active", true)
			_race_audio.call("start_music")
	elif _race_green_hold <= 0.0:
		_lights.set("remaining", -1.0)
	var keyboard := Vector2(float(int(Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT))) - float(int(Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT))), float(int(Input.is_key_pressed(KEY_S) or Input.is_key_pressed(KEY_DOWN))) - float(int(Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP))))
	var steer: Vector2 = keyboard.normalized() if keyboard.length_squared() > 0.0 else _input
	if _running and not _lap_complete:
		if steer.length_squared() > 0.005:
			_velocity = (_velocity + steer.limit_length(1.0) * THRUST * delta).limit_length(MAX_SPEED)
		else:
			_velocity = _velocity.move_toward(Vector2.ZERO, BRAKE * delta)
		if Input.is_key_pressed(KEY_SPACE):
			_velocity = Vector2.ZERO
		# Hard track barriers: project the proposed ship position onto the closest
		# centerline segment, then clamp lateral displacement inside the corridor.
		var proposed: Vector2 = _world() + _velocity * delta
		var track: Dictionary = Generator.nearest_on_track(proposed, _route)
		var closest: Vector2 = track["point"]
		var lateral: Vector2 = proposed - closest
		var allowed: float = _track_width * 0.5 - Generator.SHIP_MARGIN
		if lateral.length() > allowed:
			var outward: Vector2 = lateral.normalized()
			proposed = closest + outward * allowed
			var speed_out: float = _velocity.dot(outward)
			if speed_out > 0.0:
				# Reflect outward motion and preserve some tangential momentum.
				_velocity = (_velocity - outward * speed_out * (1.0 + WALL_BOUNCE)) * WALL_SPEED_LOSS
		# Ship-to-ship interaction is resolved in world coordinates.
		var contact: Dictionary = _rivals.call("player_contact", proposed, _velocity)
		_velocity = contact["velocity"]
		proposed += Vector2(contact["push"])
		# A collision cannot push the player outside the physical corridor.
		var corrected: Dictionary = Generator.nearest_on_track(proposed, _route)
		var correction: Vector2 = proposed - Vector2(corrected["point"])
		if correction.length() > allowed:
			proposed = Vector2(corrected["point"]) + correction.normalized() * allowed
		_navigator.advance(proposed - _world())
	if _velocity.length_squared() > 4.0:
		_heading = lerp_angle(_heading, _velocity.angle() + PI * 0.5, minf(1.0, delta * 7.0))
	_ship.rotation = _heading
	_ship.set("throttle", clampf(_velocity.length() / MAX_SPEED, 0.0, 1.0))
	_update_camera()
	var position: Vector2 = _world()
	var nearest_distance: float = INF
	for i in range(_route.size()):
		var d: float = position.distance_squared_to(_route[i])
		if d < nearest_distance:
			nearest_distance = d
			_nearest_index = i
	# Count progress across the WHOLE corridor, not only within 160 px
	# of its centreline (the previous test missed wide-lane player laps).
	if _running and not _lap_complete:
		var previous_index: int = _progress_index
		var advance: int = (_nearest_index - previous_index + _route.size()) % _route.size()
		var forward_step: bool = advance > 0 and advance <= 14
		var crossed_start: bool = forward_step and previous_index >= int(_route.size() * 0.86) and _nearest_index < int(_route.size() * 0.14)
		if forward_step:
			_progress_index = _nearest_index
			if _progress_index >= int(_route.size() * 0.50) and _progress_index < int(_route.size() * 0.86):
				_half_lap_reached = true
		if crossed_start and _half_lap_reached and _lap_elapsed > 2.0:
			_laps_finished += 1
			if _lap_elapsed > 1.0:
				_best_lap = RaceProgress.record_lap(_planet_id, _difficulty, _lap_elapsed)
			_lap_elapsed = 0.0
			_progress_index = _nearest_index
			_half_lap_reached = false
			if _laps_finished >= TOTAL_LAPS:
				_lap_complete = true
				_running = false
				if not _embedded_station_race:
					RaceProgress.complete_race(_planet_id)
				_velocity = Vector2.ZERO
				_update_race_position()
				_mika_campaign_finish()
			else:
				_info.text = "PLACE %d/5 | LAP %d/%d | %s" % [_race_position, _laps_finished + 1, TOTAL_LAPS, _base_info]
	_rivals.set_meta("race_elapsed", _race_elapsed)
	_rivals.call("step", delta)
	_update_race_position()
	_route_layer.set("animation_time", _clock)
	_route_layer.set("next_index", (_progress_index + 8) % _route.size())
	_route_layer.queue_redraw()
	_map_route.queue_redraw()
	_lights.queue_redraw()
	_lap_display.set("completed", _laps_finished)
	_lap_display.set("place", _race_position)
	_lap_display.set("best_lap", _best_lap)
	_lap_display.set("current_time", _lap_elapsed)
	_lap_display.queue_redraw()
	var standings: Array[Dictionary] = []
	var route_length: float = float(_rivals.get_meta("route_length", 1.0))
	var player_progress: float = float(_laps_finished) * route_length
	for j in range(_progress_index):
		player_progress += _route[j].distance_to(_route[(j + 1) % _route.size()])
	standings.append({"name": "Мики", "progress": player_progress, "lap": mini(3, _laps_finished + 1), "time": _race_elapsed, "mika": true})
	for rival in _rivals.get("racers"):
		var distance: float = float(rival["distance"])
		standings.append({"name": "Игрок %d" % (int(rival["id"]) + 1), "progress": distance, "lap": mini(3, maxi(1, int(rival["lap"]) + 1)), "time": minf(_race_elapsed, float(rival.get("finish_time", _race_elapsed))), "mika": false})
	standings.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return float(a["progress"]) > float(b["progress"]))
	_scoreboard.set("elapsed", _race_elapsed)
	_scoreboard.set("standings", standings)
	_scoreboard.queue_redraw()
	if _lap_complete:
		_info.text = "FINISH! PLACE %d/5 | %d LAPS | Press NEW ROUTE to try again" % [_race_position, TOTAL_LAPS]

func _world() -> Vector2:
	return Vector2(_navigator.sector) * 512.0 + _navigator.local

func _update_camera() -> void:
	if _solar == null or _route_layer == null:
		return
	var s: Vector2 = get_viewport_rect().size
	_solar.call("set_camera_address", _navigator.sector, _navigator.local, Vector2.ZERO)
	_route_layer.set("camera_world", _world())
	if _rivals != null:
		_rivals.set("camera_world", _world())
	_route_layer.set("viewport_size", s)
	if _rivals != null:
		_rivals.set("viewport_size", s)
	if _map != null:
		_map.call("set_ship_location", _navigator.sector, _navigator.local, _heading)
		_map.call("set_solar_bodies", _solar.call("get_navigation_bodies"), Generator.RADAR_RADIUS)
		_map_route.set("map_source", _map)
		if _rivals != null:
			_map_route.set("rival_positions", _rivals.call("positions"))
	if _stars != null:
		_stars.call("set_camera_look", _world())

func _update_race_position() -> void:
	if _route.size() < 4 or _rivals == null:
		return
	var route_length: float = 0.0
	for i in range(_route.size()):
		route_length += _route[i].distance_to(_route[(i + 1) % _route.size()])
	var segment_length: float = 0.0
	for i in range(_progress_index):
		segment_length += _route[i].distance_to(_route[(i + 1) % _route.size()])
	var player_distance: float = float(_laps_finished) * route_length + segment_length
	var place: int = 1
	for rival_distance in _rivals.call("progress_values"):
		if float(rival_distance) > player_distance + 30.0:
			place += 1
	if place != _race_position:
		_race_position = place
	if not _lap_complete:
		_info.text = "PLACE %d/5 | LAP %d/%d | %s" % [_race_position, mini(TOTAL_LAPS, _laps_finished + 1), TOTAL_LAPS, _base_info]

func _leave_race() -> void:
	_race_audio.call("stop_all")
	if _embedded_station_race:
		_exit_button.disabled = true
		exit_requested.emit()
		return
	var destination: String = _return_scene
	if not ResourceLoader.exists(destination):
		destination = "res://scenes/main.tscn"
	_exit_button.disabled = true
	get_tree().call_deferred("change_scene_to_file", destination)


# Six-station racing campaign. No educational portal or crystal rewards.
func _mika_campaign_confirm() -> void:
	_mika_campaign_dismiss()
	_campaign_waiting = false
	_countdown = 3.0
	_lights.visible = true
	_lights.set("remaining", 3.0)

func _mika_campaign_finish() -> void:
	_race_audio.call("stop_all")
	_campaign_waiting = true
	_rivals.set("active", false)
	# Compare actual rival finish timestamps, not capped track distances.
	var earlier_finishers: int = 0
	for rival in _rivals.get("racers"):
		if rival.has("finish_time") and float(rival["finish_time"]) <= _race_elapsed:
			earlier_finishers += 1
	var final_place: int = 1 + earlier_finishers
	if final_place != 1:
		_mika_campaign_dialog("Финиш: место %d из 5.\nДля открытия следующей гонки нужно первое место." % final_place, "Повторить", _mika_campaign_retry, "Выход", _leave_race)
		return
	var result: Dictionary = Campaign.record_win(_planet_id, _race_elapsed)
	if not bool(result.get("saved", false)):
		_mika_campaign_dialog("Не удалось сохранить победу.", "Повторить", _mika_campaign_retry, "Выход", _leave_race)
		return
	var best: float = float(result.get("best", _race_elapsed))
	var next_station: String = str(result.get("next", ""))
	if next_station.is_empty():
		_mika_campaign_dialog("Все шесть гонок выиграны!\nНаграда: трофей чемпиона.\nЛучшее время победы: %.1f сек." % best, "Ещё раз", _mika_campaign_retry, "Выход", _leave_race)
	else:
		_mika_campaign_dialog("Победа в %s!\nЛучшее время: %.1f сек.\nОткрыта %s. Продолжить?" % [Campaign.name_for(_planet_id), best, Campaign.name_for(next_station)], "Следующая", _mika_campaign_next.bind(next_station), "Выход", _leave_race)

func _mika_campaign_retry() -> void:
	_mika_campaign_dismiss()
	_campaign_waiting = false
	_apply_route()
	_lights.visible = true
	_rivals.set("active", false)

func _mika_campaign_next(station: String) -> void:
	_mika_campaign_dismiss()
	_campaign_waiting = false
	_planet_id = station
	_system_id = Campaign.system_for(station)
	_difficulty = Campaign.difficulty_for(station)
	_best_lap = RaceProgress.best_lap(_planet_id, _difficulty)
	match _difficulty:
		"easy": _length_index = 0
		"hard": _length_index = 2
		_: _length_index = 1
	if is_instance_valid(_solar):
		remove_child(_solar)
		_solar.queue_free()
	if _system_id == "mw":
		_solar = Solar.new()
		_solar.set_process(false)
	else:
		_solar = Node2D.new()
		_solar.set_script(preload("res://space_racing/RaceGalaxyBackdrop.gd"))
		_solar.set("system_id", _system_id)
	add_child(_solar)
	move_child(_solar, 1)
	_rivals.call("set_system_id", _system_id)
	_apply_route()
	_lights.visible = true
	_rivals.set("active", false)

func _mika_campaign_dismiss() -> void:
	if is_instance_valid(_campaign_modal):
		_campaign_modal.queue_free()
	_campaign_modal = null

func _mika_campaign_dialog(message: String, yes_text: String, yes_action: Callable, no_text: String, no_action: Callable) -> void:
	_mika_campaign_dismiss()
	var cover := ColorRect.new()
	cover.name = "RaceCampaignDialog"
	cover.color = Color(0.015, 0.035, 0.085, 0.86)
	cover.mouse_filter = Control.MOUSE_FILTER_STOP
	_hud.add_child(cover)
	cover.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_campaign_modal = cover
	var center := CenterContainer.new()
	cover.add_child(center)
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(390, 0)
	var style := StyleBoxFlat.new()
	style.bg_color = Color("0c253e")
	style.border_color = Color("4bc7f5")
	style.set_border_width_all(3)
	style.set_corner_radius_all(18)
	style.content_margin_left = 20
	style.content_margin_right = 20
	style.content_margin_top = 20
	style.content_margin_bottom = 20
	panel.add_theme_stylebox_override("panel", style)
	center.add_child(panel)
	var stack := VBoxContainer.new()
	stack.add_theme_constant_override("separation", 18)
	panel.add_child(stack)
	var title := Label.new()
	title.text = "SPACE RACING"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 24)
	title.add_theme_color_override("font_color", Color("7ce5ff"))
	stack.add_child(title)
	var label := Label.new()
	label.text = message
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.custom_minimum_size = Vector2(340, 90)
	label.add_theme_font_size_override("font_size", 18)
	stack.add_child(label)
	var buttons := HBoxContainer.new()
	buttons.alignment = BoxContainer.ALIGNMENT_CENTER
	buttons.add_theme_constant_override("separation", 16)
	stack.add_child(buttons)
	for entry in [[yes_text, yes_action], [no_text, no_action]]:
		var button := Button.new()
		button.text = str(entry[0])
		button.custom_minimum_size = Vector2(138, 48)
		button.focus_mode = Control.FOCUS_NONE
		button.pressed.connect(entry[1])
		buttons.add_child(button)
