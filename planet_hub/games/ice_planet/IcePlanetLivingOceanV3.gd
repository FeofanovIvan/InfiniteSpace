extends "res://planet_hub/games/ice_planet/IcePlanetCosmicClimateV2.gd"
## Ice Planet v3 — living ocean / survival controls.
## The ORIGINAL scripts/Joystick.gd is instanced twice, untouched.
## Original IcePlanet.gd and the native MIKA toolbar remain unchanged.

const FLIGHT_STICK = preload("res://scripts/Joystick.gd")
const ORIGINAL_SPACE = preload("res://simulator_ui/scripts/real_space_background.gd")
const LIQUID_SURFACE: Shader = preload("res://planet_hub/games/ice_planet/liquid_ocean_v3.gdshader")
const CONTROL_MULTIPLIER: float = 1.10  # same value as Main.gd flight controls
const CORE_RISK_DISTANCE: float = 258.0
const MOTION_SPEED: float = 0.36
const OCEAN_TEXT: Dictionary = {
    "ru": {"subtitle":"Удержи океан жидким", "average":"СРЕДНЯЯ", "warm":"ДЕНЬ", "cool":"НОЧЬ", "motion":"ДВИЖЕНИЕ", "spin":"ВРАЩЕНИЕ", "water":"ЖИДКАЯ ВОДА", "ice":"ЗАМЕРЗАНИЕ", "boil":"ИСПАРЕНИЕ", "balance":"РАЗНИЦА ТЕМПЕРАТУР", "flare":"ВСПЫШКА", "hint":"?"},
    "en": {"subtitle":"Keep the ocean liquid", "average":"AVERAGE", "warm":"DAY", "cool":"NIGHT", "motion":"MOVE", "spin":"ROTATE", "water":"LIQUID WATER", "ice":"FREEZING", "boil":"EVAPORATING", "balance":"TEMPERATURE GAP", "flare":"SOLAR FLARE", "hint":"?"},
    "pt": {"subtitle":"Mantenha o oceano líquido", "average":"MÉDIA", "warm":"DIA", "cool":"NOITE", "motion":"MOVER", "spin":"GIRAR", "water":"ÁGUA LÍQUIDA", "ice":"CONGELANDO", "boil":"EVAPORANDO", "balance":"DIFERENÇA TÉRMICA", "flare":"ERUPÇÃO SOLAR", "hint":"?"},
    "es": {"subtitle":"Mantén líquido el océano", "average":"MEDIA", "warm":"DÍA", "cool":"NOCHE", "motion":"MOVER", "spin":"GIRAR", "water":"AGUA LÍQUIDA", "ice":"CONGELACIÓN", "boil":"EVAPORACIÓN", "balance":"DIFERENCIA TÉRMICA", "flare":"ERUPCIÓN SOLAR", "hint":"?"},
    "de": {"subtitle":"Halte den Ozean flüssig", "average":"MITTEL", "warm":"TAG", "cool":"NACHT", "motion":"BEWEGEN", "spin":"DREHEN", "water":"FLÜSSIGES WASSER", "ice":"GEFRIERT", "boil":"VERDAMPFT", "balance":"TEMPERATURGEFÄLLE", "flare":"SONNENERUPTION", "hint":"?"},
    "fr": {"subtitle":"Garde l'océan liquide", "average":"MOYENNE", "warm":"JOUR", "cool":"NUIT", "motion":"DÉPLACER", "spin":"TOURNER", "water":"EAU LIQUIDE", "ice":"GEL", "boil":"ÉVAPORATION", "balance":"ÉCART THERMIQUE", "flare":"ÉRUPTION SOLAIRE", "hint":"?"},
}

var _space_sky: Control
var _flight_left: Control
var _flight_right: Control
var _left_vector: Vector2 = Vector2.ZERO
var _right_vector: Vector2 = Vector2.ZERO
var _rotation_sign: float = 1.0
var _actual_distance: float = 0.50
var _liquid_fx_time: float = 0.0
var _host_is_closing: bool = false

func _ready() -> void:
    super._ready()
    _create_live_space()
    _create_flight_controls()
    _activate_ocean_shader()
    _suppress_extra_labels()
    _layout()
    call_deferred("_layout")

func _create_live_space() -> void:
    _space_sky = ORIGINAL_SPACE.new() as Control
    _space_sky.name = "RealFlightSkyInsideClimatePanel"
    _space_sky.mouse_filter = Control.MOUSE_FILTER_IGNORE
    _space_sky.z_index = -5
    add_child(_space_sky)
    _space_sky.move_to_front() # z_index remains negative; controls stay above sky

func _create_flight_controls() -> void:
    _flight_left = FLIGHT_STICK.new() as Control
    _flight_left.name = "FlightJoystick_MoveCloserFarther"
    _flight_left.z_index = 50
    add_child(_flight_left)
    _flight_left.connect("direction_changed", Callable(self, "_on_left_stick"))
    _flight_right = FLIGHT_STICK.new() as Control
    _flight_right.name = "FlightJoystick_RotateClockwiseCounterclockwise"
    _flight_right.z_index = 50
    add_child(_flight_right)
    _flight_right.connect("direction_changed", Callable(self, "_on_right_stick"))

func _activate_ocean_shader() -> void:
    if _earth_body == null:
        return
    _earth_body.name = "LiquidOcean_FreezeBoilTwoHemispheres"
    var liquid: ShaderMaterial = ShaderMaterial.new()
    liquid.shader = LIQUID_SURFACE
    liquid.set_shader_parameter("earth_map", EARTH_TEXTURE)
    liquid.set_shader_parameter("mars_map", MARS_TEXTURE)
    liquid.set_shader_parameter("neptune_map", NEPTUNE_TEXTURE)
    liquid.set_shader_parameter("cloud_map", CLOUDS_TEXTURE)
    _earth_body.material = liquid
    _earth_material = liquid

func _suppress_extra_labels() -> void:
    # Disable the old duplicated phase / state / tutorial lines, and Restart.
    for label in [
        _title, _subtitle, _phase_label, _guide_label, _model_note,
        _instruction_label, _mission_title, _climate_status, _hold_label,
        _round_label, _score_label, _distance_near_label, _distance_far_label,
        _rotation_fast_label, _rotation_slow_label, _language_picker
    ]:
        if label != null:
            label.hide()
    if _restart_button != null:
        _restart_button.disabled = true
        _restart_button.hide()
        _restart_button.mouse_filter = Control.MOUSE_FILTER_IGNORE
    if _hint_button != null:
        _hint_button.text = "?"
    if _mika_header_subtitle != null:
        _mika_header_subtitle.text = _word("subtitle")

func _word(id: String) -> String:
    var locale: Dictionary = OCEAN_TEXT.get(_interface_lang, OCEAN_TEXT["en"])
    return str(locale.get(id, OCEAN_TEXT["en"].get(id, id)))

func _on_left_stick(value: Vector2) -> void:
    if _mission_complete or _game_complete:
        return
    # Tap works, too. The continuous press then continues to manoeuvre.
    if absf(value.x) > 0.12 and absf(_left_vector.x) < 0.12:
        _distance = clampf(_distance + signf(value.x) * 0.024, 0.0, 1.0)
    _left_vector = value

func _on_right_stick(value: Vector2) -> void:
    if _mission_complete or _game_complete:
        return
    _right_vector = value
    if absf(value.x) > 0.12:
        _rotation_sign = signf(value.x)

func _input(_event: InputEvent) -> void:
    # ALL pointer input belongs to the two original flight joysticks,
    # not to the legacy transparent orbital slider hot-spots.
    pass

func _choose_action(_point: Vector2) -> String:
    return ""

func _tap_action(_action: String, _point: Vector2) -> void:
    pass

func _drag_action(_action: String, _start: Vector2, _now: Vector2, _distance_at_start: float, _spin_at_start: float) -> void:
    pass

func _refresh_action_visibility() -> void:
    if _restart_button != null:
        _restart_button.disabled = true
        _restart_button.hide()
    if _hint_button != null:
        _hint_button.visible = not _mission_complete and not _game_complete

func _refresh_climate_labels() -> void:
    if _climate_labels.size() != 5:
        return
    _climate_labels[0].text = "%s  %+d°C" % [_word("average"), roundi(_mean_temp)]
    _climate_labels[1].text = "%s  %+d°C" % [_word("warm"), roundi(_warm_temp)]
    _climate_labels[2].text = "%s  %+d°C" % [_word("cool"), roundi(_cool_temp)]
    _climate_labels[3].text = "%s  %s" % [_word("spin"), "↶" if _rotation_sign < 0.0 else "↷"]
    var state: String = "boil" if _status == "hot" else "ice" if _status == "cold" else "balance" if _status == "spin" else "water"
    _climate_labels[4].text = _word("flare") if _flare_amount() > 0.60 else _word(state)
    _climate_labels[4].add_theme_color_override("font_color", Color("ffb8a3") if state == "boil" else Color("b9eaff") if state == "ice" else Color("9ef3bc"))
    if _mika_header_subtitle != null:
        _mika_header_subtitle.text = _word("subtitle")
    if _hint_button != null:
        _hint_button.text = _word("hint")
    if _next_button != null:
        _next_button.text = _readable("next") if not _game_complete else _tr("again") + " ↻"

func _sun_location() -> Vector2:
    # Runs from the extreme left towards the board midpoint, at greater speed.
    return Vector2(
        291.0 + 218.0 * sin(_elapsed * 0.78 - 0.36) + 17.0 * sin(_elapsed * 1.31),
        299.0 + 23.0 * sin(_elapsed * 1.28 + 0.3)
    )

func _planet_location() -> Vector2:
    # Earth/ocean moves in the opposite half of the stage with a hard clearance.
    var raw_x: float = 704.0 + _distance * 393.0
    return Vector2(maxf(raw_x, _sun_location().x + CORE_RISK_DISTANCE), 318.0 + 9.0 * sin(_elapsed * 0.51))

func _flare_amount() -> float:
    # A brief solar storm every ~11 seconds, with noticeable stronger eruption.
    return pow(maxf(sin(_elapsed * 0.56 - 0.93), 0.0), 12.0)

func _update_temperatures() -> void:
    # Educational toy, NOT astronomical or climate-forecast physics.
    # Actual on-screen Sun-to-ocean distance drives the thermometer, so a
    # stationary joystick will NOT keep the world safe as the sun oscillates.
    _actual_distance = clampf((_planet_location().x - _sun_location().x - 270.0) / 755.0, 0.0, 1.0)
    _mean_temp = lerpf(117.0, -48.0, _actual_distance) + 19.0 * _flare_amount()
    var contrast: float = lerpf(42.0, 10.0, _spin)
    _warm_temp = _mean_temp + contrast
    _cool_temp = _mean_temp - contrast
    if _warm_temp >= 100.0:
        _status = "hot"
    elif _cool_temp <= 2.0:
        _status = "cold"
    elif _spin < 0.53:
        _status = "spin"
    else:
        _status = "good"

func _process(delta: float) -> void:
    _elapsed += delta
    _liquid_fx_time += delta
    # Left stick exclusively changes orbit/translation. Nothing else does.
    if not _mission_complete and not _game_complete:
        _distance = clampf(_distance + _left_vector.x * MOTION_SPEED * delta, 0.0, 1.0)
    # Right stick exclusively controls signed rotation and rotation speed.
    var right_x: float = _right_vector.x
    var active: bool = absf(right_x) > 0.13
    var desired_spin: float = 0.63 + 0.37 * absf(right_x) if active else 0.63
    _spin = move_toward(_spin, desired_spin, 1.5 * delta)
    var angular_speed: float = 0.38 + 3.5 * absf(right_x)
    _planet_angle = wrapf(_planet_angle + angular_speed * _rotation_sign * delta, -TAU, TAU)
    if _hint_seconds > 0.0:
        _hint_seconds = maxf(0.0, _hint_seconds - delta)
        if _hint_seconds <= 0.0:
            _hint_key = ""
    if not _mission_complete and not _game_complete:
        _update_temperatures()
        if _status == "good":
            _stable_seconds += delta
            if _stable_seconds >= HOLD_TO_WIN:
                _stable_seconds = HOLD_TO_WIN
                _mission_complete = true
                _score += 100
                if _mission_index == _missions.size() - 1:
                    _game_complete = true
                _next_button.visible = true
                _left_vector = Vector2.ZERO
                _right_vector = Vector2.ZERO
                if _flight_left != null:
                    _flight_left.call("clear_input")
                if _flight_right != null:
                    _flight_right.call("clear_input")
        else:
            _stable_seconds = maxf(0.0, _stable_seconds - 2.0 * delta)
    if _earth_material != null:
        # Extreme left hemisphere bubbles/steams, extreme cool side crystallizes.
        var hot: float = smoothstep(42.0, 103.0, _warm_temp)
        var frozen: float = 1.0 - smoothstep(-25.0, 26.0, _cool_temp)
        _earth_material.set_shader_parameter("surface_phase", _planet_angle)
        _earth_material.set_shader_parameter("hot_factor", hot)
        _earth_material.set_shader_parameter("ice_factor", frozen)
        _earth_material.set_shader_parameter("solar_flare", _flare_amount())
    if _sun_material != null:
        _sun_material.set_shader_parameter("activity", 0.55 + _flare_amount() * 0.45)
    if _corona_material != null:
        _corona_material.set_shader_parameter("corona_strength", 1.25 + _flare_amount() * 2.0)
    _position_bodies()
    _update_labels()
    _refresh_action_visibility()
    queue_redraw()

func _layout() -> void:
    super._layout()
    if _mika_title_panel == null or _stage_rect.size.x < 250.0:
        return
    if _space_sky != null:
        _space_sky.position = _stage_rect.position + Vector2(5.0, 5.0)
        _space_sky.size = _stage_rect.size - Vector2(10.0, 10.0)
    # Exact Main.gd responsive control logic, scoped to the stage's safe rect.
    var base_scale: float = clampf(minf(_stage_rect.size.x / 520.0, _stage_rect.size.y / 340.0), 0.55, 1.0)
    var control_scale: float = base_scale * CONTROL_MULTIPLIER
    var visual_size: float = 184.0 * control_scale
    var margin: float = 18.0 * base_scale
    var bottom: float = maxf(_stage_rect.position.y + margin, _stage_rect.end.y - visual_size - margin)
    if _flight_left != null:
        _flight_left.scale = Vector2.ONE * control_scale
        _flight_left.position = Vector2(_stage_rect.position.x + margin, bottom)
    if _flight_right != null:
        _flight_right.scale = Vector2.ONE * control_scale
        _flight_right.position = Vector2(_stage_rect.end.x - visual_size - margin, bottom)
    for label in [_mission_title, _climate_status, _hold_label]:
        if label != null:
            label.hide()
    if _climate_labels.size() == 5:
        for i in range(5):
            _put(_climate_labels[i], Rect2(34.0 + float(i) * 244.0, 32.0, 239.0, 51.0))
            _climate_labels[i].add_theme_font_size_override("font_size", 17 if i != 4 else 16)
    if _distance_title != null:
        _put(_distance_title, Rect2(31.0, 489.0, 290.0, 32.0))
        _distance_title.text = _word("motion")
    if _rotation_title != null:
        _put(_rotation_title, Rect2(960.0, 489.0, 290.0, 32.0))
        _rotation_title.text = _word("spin")
    if _hint_button != null:
        _put(_hint_button, Rect2(595, 632, 90, 47))
        _hint_button.add_theme_font_size_override("font_size", 19)
    if _next_button != null:
        _put(_next_button, Rect2(480, 623, 320, 55))
        _next_button.add_theme_font_size_override("font_size", 19)
    _suppress_extra_labels()
    _position_bodies()
    queue_redraw()

func _position_bodies() -> void:
    if _sun_body == null or _earth_body == null or _sun_corona == null:
        return
    _sun_center = _sun_location()
    _earth_center = _planet_location()
    var pulse: float = 1.0 + 0.25 * sin(_elapsed * 0.86 + 0.31)
    _sun_radius = 112.0 * pulse
    _world_radius = 108.0
    _put(_sun_corona, Rect2(_sun_center - Vector2.ONE * _sun_radius * 1.57, Vector2.ONE * _sun_radius * 3.14))
    _put(_sun_body, Rect2(_sun_center - Vector2.ONE * _sun_radius, Vector2.ONE * _sun_radius * 2.0))
    _put(_earth_body, Rect2(_earth_center - Vector2.ONE * _world_radius * 1.20, Vector2.ONE * _world_radius * 2.40))
    _sun_corona.z_index = 2
    _sun_body.z_index = 3
    _earth_body.z_index = 4

func _draw() -> void:
    # The sky is the existing real flying-space node behind this transparent ink.
    if _stage_rect.size.x <= 0.0:
        return
    var frame: StyleBoxFlat = MIKA_UI.stage_style()
    frame.bg_color = Color(0.015, 0.065, 0.15, 0.09)
    frame.border_color = Color("5cdfff", 0.94)
    draw_style_box(frame, _stage_rect)
    draw_set_transform(_origin, 0.0, Vector2.ONE * _scale)
    _draw_climate_bar()
    _draw_ocean_vapor_and_ice()
    _draw_sun_flare_trails()
    _draw_temperature_gauge()
    draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

func _draw_sun_flare_trails() -> void:
    var activity: float = _flare_amount()
    draw_circle(_sun_center, _sun_radius * 1.55, Color(1.0, 0.42, 0.12, 0.040 + activity * 0.085))
    var track: PackedVector2Array = PackedVector2Array()
    for i in range(65):
        var t: float = float(i) / 64.0 * 14.0
        track.append(Vector2(291.0 + 218.0 * sin(t * 0.78 - 0.36), 299.0 + 23.0 * sin(t * 1.28 + 0.30)))
    draw_polyline(track, Color(1.0, 0.53, 0.21, 0.11), 1.8, true)
    for k in range(22):
        var angle: float = TAU * float(k) / 22.0 + _elapsed * 0.16
        var start: Vector2 = _sun_center + Vector2.from_angle(angle) * _sun_radius * 0.91
        var end: Vector2 = _sun_center + Vector2.from_angle(angle + 0.30 * sin(_elapsed * 2.1 + k)) * _sun_radius * (1.09 + activity * (0.55 + 0.18 * sin(float(k))))
        draw_line(start, end, Color(1.0, 0.53, 0.13, 0.12 + 0.75 * activity), 2.0 + activity * 4.0, true)

func _draw_ocean_vapor_and_ice() -> void:
    var hot: float = smoothstep(42.0, 103.0, _warm_temp)
    var cold: float = 1.0 - smoothstep(-25.0, 26.0, _cool_temp)
    # Steam leaves the sun-facing edge; little gas bubbles rise and fade.
    if hot > 0.04:
        for i in range(20):
            var t: float = fposmod(_liquid_fx_time * (0.19 + float(i % 4) * 0.025) + float(i) * 0.147, 1.0)
            var a: float = -2.7 + float(i % 8) * 0.47
            var pos: Vector2 = _earth_center + Vector2.from_angle(a) * (_world_radius * (0.82 + t * 0.66)) + Vector2(-22.0 * t, -28.0 * t)
            draw_circle(pos, 3.0 + t * 4.0, Color(1.0, 0.78, 0.65, hot * (1.0 - t) * 0.48))
            draw_arc(pos, 5.0 + t * 5.0, 0, TAU, 22, Color(1.0, 0.87, 0.74, hot * (1.0 - t) * 0.52), 1.5, true)
    # Frost on the cold hemisphere rim; snow-white particles imply hardening.
    if cold > 0.04:
        draw_arc(_earth_center, _world_radius * 1.12, -1.1, 1.1, 35, Color(0.78, 0.96, 1.0, cold * 0.64), 6.0, true)
        for j in range(17):
            var a: float = -1.06 + float(j) * 2.12 / 16.0
            var r: float = _world_radius * (1.08 + 0.12 * sin(_liquid_fx_time * 0.8 + j))
            draw_circle(_earth_center + Vector2.from_angle(a) * r, 2.0 + float(j % 3) * 1.4, Color(0.93, 1.0, 1.0, cold * 0.70))
    var progress: float = clampf(_stable_seconds / HOLD_TO_WIN, 0.0, 1.0)
    draw_arc(_earth_center, _world_radius * 1.23, -PI * 0.5, -PI * 0.5 + TAU * maxf(0.001, progress), 80, Color(0.46, 1.0, 0.77, 0.8), 5.0, true)

func _draw_temperature_gauge() -> void:
    # Marker shows ACTUAL moving solar separation, not raw joystick input.
    var rail: Rect2 = Rect2(385.0, 537.0, 510.0, 24.0)
    _panel(Rect2(364.0, 520.0, 552.0, 67.0), Color(0.025, 0.09, 0.19, 0.86), Color("53d7ff", 0.77), 18, 2)
    var total: float = rail.size.x
    for i in range(90):
        var t: float = float(i) / 90.0
        var tint: Color = Color("f77949") if t < 0.24 else Color("7de5b0") if t < 0.60 else Color("77beff")
        draw_rect(Rect2(rail.position.x + t * total, rail.position.y, total / 90.0 + 1.0, rail.size.y), tint, true)
    var indicator_x: float = rail.position.x + clampf(_actual_distance, 0.0, 1.0) * total
    draw_line(Vector2(indicator_x, rail.position.y - 9.0), Vector2(indicator_x, rail.end.y + 9.0), Color.WHITE, 4.0, true)
    draw_circle(Vector2(indicator_x, rail.position.y - 7.0), 7.0, Color("efffff"))
    draw_string(ThemeDB.fallback_font, Vector2(395, 580), _readable("heat"), HORIZONTAL_ALIGNMENT_LEFT, 100, 14, Color("ffd0b2"))
    draw_string(ThemeDB.fallback_font, Vector2(548, 580), _readable("safe"), HORIZONTAL_ALIGNMENT_CENTER, 184, 14, Color("d0ffe6"))
    draw_string(ThemeDB.fallback_font, Vector2(825, 580), _readable("ice"), HORIZONTAL_ALIGNMENT_RIGHT, 66, 14, Color("b7e9ff"))
