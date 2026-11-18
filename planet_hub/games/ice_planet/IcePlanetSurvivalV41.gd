extends "res://planet_hub/games/ice_planet/IcePlanetSurvivalV4.gd"
## MIKA Ice Planet v4.1 — easier entry, real spherical spin, X-only steering.
## Keeps endless survival, crystal rewards, solar escalation, flight HUD,
## host Back handling, stars and original segmented climate gauge.
## The old one-sided overheating death condition is intentionally disabled:
## rotation now gives visible motion and helpful cooling, not a sudden failure.

const OCEAN_V41: Script = preload("res://planet_hub/games/ice_planet/IcePlanetRotatingOceanV41.gd")
const FIRST_SAFE_HALF_WIDTH: float = 0.155
const MIN_SAFE_HALF_WIDTH: float = 0.072
const SHRINK_PER_CRYSTAL: float = 0.011
const SAFE_CENTER: float = 0.504
const TURN_STEER_RATE: float = 4.85
const TURN_DRIFT_RATE: float = 0.22
const DIRECTION_WORDS: Dictionary = {
    "ru": {"left":"ВЛЕВО", "right":"ВПРАВО"},
    "en": {"left":"TURN LEFT", "right":"TURN RIGHT"},
    "pt": {"left":"GIRE À ESQUERDA", "right":"GIRE À DIREITA"},
    "es": {"left":"GIRA A LA IZQUIERDA", "right":"GIRA A LA DERECHA"},
    "de": {"left":"NACH LINKS", "right":"NACH RECHTS"},
    "fr": {"left":"TOURNE À GAUCHE", "right":"TOURNE À DROITE"},
}

var _required_direction: int = 1
var _rotation_cooling: float = 0.0
var _rotation_help: float = 0.0
var _turn_velocity: float = 0.0

func _create_flight_controls() -> void:
    # BOTH controls use the real flight joystick, with an X-only movement
    # constraint and its approved dark horizontal guide. No 360-degree thumb.
    _flight_left = HORIZONTAL_STICK_V4.new() as Control
    _flight_left.name = "IcePlanetFlightMoveHorizontal"
    _flight_left.z_index = 50
    add_child(_flight_left)
    _flight_left.connect("direction_changed", Callable(self, "_on_left_stick"))
    _flight_right = HORIZONTAL_STICK_V4.new() as Control
    _flight_right.name = "IcePlanetFlightSpinHorizontal"
    _flight_right.z_index = 50
    add_child(_flight_right)
    _flight_right.connect("direction_changed", Callable(self, "_on_right_stick"))

func _ready() -> void:
    super._ready()
    # v3.1 created an animated striped disk. Switch it to an actual spherical
    # longitude map. Keep the old Control invisible until queue_free completes.
    if _ocean_sphere != null:
        _ocean_sphere.hide()
        _ocean_sphere.queue_free()
    _ocean_sphere = OCEAN_V41.new() as Control
    _ocean_sphere.name = "RotatingOceanGlobe_RealProjectedSurface_NoWhiteShader"
    _ocean_sphere.mouse_filter = Control.MOUSE_FILTER_IGNORE
    _ocean_sphere.z_index = 4
    add_child(_ocean_sphere)
    _reposition_ocean()
    _update_ocean()
    _refresh_climate_labels()
    queue_redraw()

func _green_bounds() -> Vector2:
    # Wide and forgiving at zero crystals; each next crystal contracts it.
    var half_width: float = maxf(MIN_SAFE_HALF_WIDTH, FIRST_SAFE_HALF_WIDTH - float(_earned_crystals) * SHRINK_PER_CRYSTAL)
    return Vector2(SAFE_CENTER - half_width, SAFE_CENTER + half_width)

func _difficulty_curve() -> float:
    # Solar difficulty still rises with EVERY crystal, but v4.1 has a softer
    # learning curve, especially while the player learns to turn the globe.
    return float(_earned_crystals) * 0.67

func _restart_survival() -> void:
    _required_direction = 1 if randi_range(0, 1) == 0 else -1
    _rotation_cooling = 0.0
    _rotation_help = 0.0
    _turn_velocity = TURN_DRIFT_RATE
    super._restart_survival()
    _rotate_warning = false
    _refresh_climate_labels()

func _spin_instruction() -> String:
    var trans: Dictionary = DIRECTION_WORDS.get(_interface_lang, DIRECTION_WORDS["en"])
    return ("↻  " + str(trans["right"])) if _required_direction > 0 else ("↺  " + str(trans["left"]))

func _update_temperatures() -> void:
    var gap: float = _planet_location().x - _sun_location().x
    _actual_distance = clampf((gap - 220.0) / 720.0, 0.0, 1.0)
    # Spinning the water in the indicated direction helps spread solar heat.
    # This is a child-friendly teaching game, not literal climate physics.
    _mean_temp = lerpf(115.0, -65.0, _actual_distance) + 11.0 * _flare_amount() - 6.0 * _rotation_cooling
    var difference: float = lerpf(33.0, 10.0, clampf(absf(_turn_velocity) / TURN_STEER_RATE, 0.0, 1.0))
    _warm_temp = _mean_temp + difference - 9.0 * _rotation_cooling
    _cool_temp = _mean_temp - difference + 2.0 * _rotation_cooling
    var bounds: Vector2 = _green_bounds()
    if _actual_distance < bounds.x:
        _status = "hot"
    elif _actual_distance > bounds.y:
        _status = "cold"
    else:
        _status = "good"
    _rotate_warning = false  # No rotation-induced death for the first version.

func _process(delta: float) -> void:
    # Base v4 stops for no reason after face-exposure timeout and interprets
    # right joystick Y as a turn. Override, but preserve continuous survival.
    var dt: float = clampf(delta, 0.0, 0.12)
    if dt <= 0.0 or _survival_lost:
        return
    _elapsed += dt
    _liquid_fx_time += dt
    _sun_primary_phase = wrapf(_sun_primary_phase + _sun_primary_rate() * dt, -TAU, TAU)
    _sun_secondary_phase = wrapf(_sun_secondary_phase + _sun_secondary_rate() * dt, -TAU, TAU)
    _sun_flare_phase = wrapf(_sun_flare_phase + _sun_flare_rate() * dt, -TAU, TAU)
    _sun_current_amplitude = move_toward(_sun_current_amplitude, _sun_target_amplitude(), SUN_AMPLITUDE_RESPONSE * dt)
    _hint_seconds = maxf(0.0, _hint_seconds - dt)

    # First stick: linear horizontal translation only, same as the flight HUD.
    _distance = clampf(_distance + _left_vector.x * 0.58 * dt, 0.0, 1.0)
    # Second stick: only horizontal deflection, clockwise OR anticlockwise.
    var x: float = clampf(_right_vector.x, -1.0, 1.0)
    _turn_velocity = TURN_DRIFT_RATE + TURN_STEER_RATE * x
    _planet_angle = wrapf(_planet_angle + _turn_velocity * dt, -TAU, TAU)
    _ocean_pitch = 0.0
    _rotation_sign = -1.0 if _turn_velocity < 0.0 else 1.0
    _spin = move_toward(_spin, clampf(0.15 + absf(_turn_velocity) / TURN_STEER_RATE * 0.85, 0.0, 1.0), 2.0 * dt)
    var correct_turn: bool = absf(x) > 0.16 and x * float(_required_direction) > 0.0
    _rotation_help = move_toward(_rotation_help, absf(x) if correct_turn else 0.0, 2.4 * dt)
    _rotation_cooling = move_toward(_rotation_cooling, _rotation_help, 1.4 * dt)

    _update_temperatures()
    _advance_survival(dt)
    if _sun_material != null:
        _sun_material.set_shader_parameter("activity", minf(1.0, 0.40 + _flare_amount() * 0.38))
        _sun_material.set_shader_parameter("rotation_seconds", maxf(12.0, 22.0 - 9.0 * (1.0 - exp(-0.14 * _difficulty_curve()))))
    if _corona_material != null:
        _corona_material.set_shader_parameter("corona_strength", 1.25 + _flare_amount() * 2.5)
    _position_bodies()
    _update_ocean()
    _update_labels()
    _refresh_action_visibility()
    queue_redraw()

func _danger_rate() -> float:
    var bounds: Vector2 = _green_bounds()
    var depth: float = 0.0
    if _actual_distance < bounds.x:
        depth = (bounds.x - _actual_distance) / maxf(bounds.x, 0.01)
    elif _actual_distance > bounds.y:
        depth = (_actual_distance - bounds.y) / maxf(1.0 - bounds.y, 0.01)
    else:
        return 0.0
    # Forgiving near the edge at first; deeper excursions remain dangerous.
    var learning: float = 0.75 + 0.25 * (1.0 - exp(-0.18 * float(_earned_crystals)))
    return (0.70 + 2.60 * pow(clampf(depth, 0.0, 1.0), 1.35)) * learning

func _advance_survival(delta: float) -> void:
    if _survival_lost:
        return
    var bounds: Vector2 = _green_bounds()
    var safe: bool = _actual_distance >= bounds.x and _actual_distance <= bounds.y
    if safe:
        _safe_tick_progress += delta
        _total_safe_seconds += delta
        _total_safe_ticks = floori(_total_safe_seconds)
        _danger_tick_progress = maxf(0.0, _danger_tick_progress - delta * 1.20)
        while _safe_tick_progress >= SAFE_TICKS_PER_CRYSTAL:
            _safe_tick_progress -= SAFE_TICKS_PER_CRYSTAL
            _award_crystal()
    else:
        _danger_tick_progress += _danger_rate() * delta
        if _danger_tick_progress >= DEATH_TICKS:
            _lose_planet()
    _stable_seconds = HOLD_TO_WIN * _safe_tick_progress / SAFE_TICKS_PER_CRYSTAL

func _award_crystal() -> void:
    super._award_crystal()
    # Signal a new side to turn toward after each crystal. Old overheating
    # loss is disabled; the direction is a friendly cooling instruction.
    _required_direction *= -1
    _rotation_help = 0.0
    _rotation_cooling = 0.0

func _refresh_climate_labels() -> void:
    super._refresh_climate_labels()
    if _climate_labels.size() != 5:
        return
    var message: String = _spin_instruction()
    var acting: bool = _rotation_help > 0.26
    var flashing: bool = sin(_elapsed * 8.5) > 0.0
    var color: Color = Color("74f3c0") if acting else Color("ff9a80") if flashing else Color("fce3bf")
    _climate_labels[3].text = message
    _climate_labels[3].add_theme_color_override("font_color", color)
    if _rotation_title != null:
        _rotation_title.text = message
        _rotation_title.add_theme_color_override("font_color", color)
    if _mika_header_subtitle != null:
        _mika_header_subtitle.text = _locale_text("subtitle")

func _draw_temperature_gauge() -> void:
    # Preserve the original 88 alternating heat/green/ice strips, now with a
    # wide green corridor initially and smaller bounds after each crystal.
    _panel(Rect2(361, 517, 558, 71), Color("071b30", 0.83), Color("3e95b8", 0.62), 20, 2)
    var length: float = SAFETY_BAR.size.x
    var bounds: Vector2 = _green_bounds()
    for i in range(88):
        var t: float = (float(i) + 0.5) / 88.0
        var fill: Color = Color("fa6d40") if t < bounds.x else Color("73e2ab") if t <= bounds.y else Color("6bbaf7")
        var rect: Rect2 = Rect2(SAFETY_BAR.position + Vector2(float(i) * length / 88.0, 0), Vector2(length / 88.0 + 1.0, SAFETY_BAR.size.y))
        draw_rect(rect, fill.darkened(0.14) if i % 2 == 0 else fill, true)
    var start_x: float = SAFETY_BAR.position.x + length * bounds.x
    draw_rect(Rect2(start_x, SAFETY_BAR.position.y - 6.0, length * (bounds.y - bounds.x), SAFETY_BAR.size.y + 12.0), Color("baffdc", 0.25), false, 3.0)
    var marker: Vector2 = Vector2(SAFETY_BAR.position.x + _actual_distance * length, SAFETY_BAR.get_center().y)
    draw_line(marker - Vector2(0.0, 16.0), marker + Vector2(0.0, 19.0), Color("f5ffff"), 5.0, true)
    draw_circle(marker - Vector2(0.0, 21.0), 8.0, Color("e6ffff"))
    draw_string(ThemeDB.fallback_font, Vector2(388.0, 576.0), _readable("heat"), HORIZONTAL_ALIGNMENT_LEFT, 100.0, 15, Color("ffc9a5"))
    draw_string(ThemeDB.fallback_font, Vector2(548.0, 576.0), _readable("safe"), HORIZONTAL_ALIGNMENT_CENTER, 184.0, 15, Color("caffdc"))
    draw_string(ThemeDB.fallback_font, Vector2(812.0, 576.0), _readable("ice"), HORIZONTAL_ALIGNMENT_RIGHT, 70.0, 15, Color("b8e6ff"))
    var progress: float = _safe_tick_progress / SAFE_TICKS_PER_CRYSTAL if _danger_rate() == 0.0 else _danger_tick_progress / DEATH_TICKS
    var good: bool = _danger_rate() == 0.0
    for cell in range(5):
        var block := Rect2(531.0 + 45.0 * float(cell), 503.0, 37.0, 6.0)
        var lit: bool = progress * 5.0 > float(cell)
        draw_rect(block, Color("70f4aa", 0.90) if good and lit else Color("ff786e", 0.93) if not good and lit else Color("35617a", 0.64), true)
