extends "res://planet_hub/games/ice_planet/IcePlanetLivingOceanV31.gd"
## MIKA Ice Planet v4.0 — continuous living-ocean survival.
## All flight artwork, the shader-free globe, the native toolbar, and the
## host's Back button remain in their v3.1 implementations.
## No per-world win: survive for as many crystal cycles as possible.
## Each crystal raises solar speed, travel amplitude, and flare intensity.
## Sun phases are integrated over time so earning a crystal cannot teleport it.

const HORIZONTAL_STICK_V4: Script = preload("res://planet_hub/games/ice_planet/IcePlanetHorizontalStickV4.gd")
const GREEN_START: float = 0.445
const GREEN_END: float = 0.563
const SAFE_TICKS_PER_CRYSTAL: float = 5.0
const DEATH_TICKS: float = 5.0
const FACE_WARNING_SECONDS: float = 3.8
const SUN_BASE_AMPLITUDE: float = 218.0
const SUN_MAX_EXTRA_AMPLITUDE: float = 54.0
const SUN_AMPLITUDE_RESPONSE: float = 22.0
const LIVE_LABELS: Dictionary = {
    "ru": {"subtitle":"Удерживай океан живым", "crystals":"КРИСТАЛЛЫ", "temperature":"ТЕМПЕРАТУРА", "safe":"ЗЕЛЁНАЯ ЗОНА", "rotate":"ПОВЕРНИ!", "rotation":"ВРАЩЕНИЕ", "danger":"ОПАСНОСТЬ", "lost":"ПЛАНЕТА ПОГИБЛА", "again":"Ещё попытка", "cause_hot":"Океан испарился", "cause_cold":"Океан замёрз", "cause_face":"Одна сторона перегрелась"},
    "en": {"subtitle":"Keep the living ocean safe", "crystals":"CRYSTALS", "temperature":"TEMPERATURE", "safe":"SAFE TICKS", "rotate":"ROTATE!", "rotation":"ROTATION", "danger":"DANGER", "lost":"PLANET LOST", "again":"Try again", "cause_hot":"The ocean evaporated", "cause_cold":"The ocean froze", "cause_face":"One side overheated"},
    "pt": {"subtitle":"Proteja o oceano vivo", "crystals":"CRISTAIS", "temperature":"TEMPERATURA", "safe":"TIQUES SEGUROS", "rotate":"GIRE!", "rotation":"ROTAÇÃO", "danger":"PERIGO", "lost":"PLANETA PERDIDO", "again":"Tentar de novo", "cause_hot":"O oceano evaporou", "cause_cold":"O oceano congelou", "cause_face":"Um lado superaqueceu"},
    "es": {"subtitle":"Protege el océano vivo", "crystals":"CRISTALES", "temperature":"TEMPERATURA", "safe":"TICS SEGUROS", "rotate":"¡GIRA!", "rotation":"ROTACIÓN", "danger":"PELIGRO", "lost":"PLANETA PERDIDO", "again":"Intentar de nuevo", "cause_hot":"El océano se evaporó", "cause_cold":"El océano se congeló", "cause_face":"Un lado se recalentó"},
    "de": {"subtitle":"Bewahre den lebenden Ozean", "crystals":"KRISTALLE", "temperature":"TEMPERATUR", "safe":"SICHERE TAKTE", "rotate":"DREHEN!", "rotation":"ROTATION", "danger":"GEFAHR", "lost":"PLANET VERLOREN", "again":"Noch einmal", "cause_hot":"Der Ozean verdampfte", "cause_cold":"Der Ozean gefror", "cause_face":"Eine Seite überhitzte"},
    "fr": {"subtitle":"Protège l'océan vivant", "crystals":"CRISTAUX", "temperature":"TEMPÉRATURE", "safe":"TICS SÛRS", "rotate":"TOURNE !", "rotation":"ROTATION", "danger":"DANGER", "lost":"PLANÈTE PERDUE", "again":"Réessayer", "cause_hot":"L'océan s'est évaporé", "cause_cold":"L'océan a gelé", "cause_face":"Un côté a surchauffé"}
}

var _safe_tick_progress: float = 0.0
var _total_safe_ticks: int = 0
var _total_safe_seconds: float = 0.0
var _danger_tick_progress: float = 0.0
var _earned_crystals: int = 0
var _sun_primary_phase: float = -0.36
var _sun_secondary_phase: float = 0.0
var _sun_flare_phase: float = -0.93
var _sun_current_amplitude: float = SUN_BASE_AMPLITUDE
var _face_side: int = 1
var _face_exposure: float = 0.0
var _rotate_warning: bool = false
var _survival_lost: bool = false
var _death_cause: String = "cause_hot"
var _death_overlay: Panel
var _death_title: Label
var _death_detail: Label
var _death_retry: Button
var _test_no_persistent_awards: bool = false

func _locale_text(key: String) -> String:
    var locale: Dictionary = LIVE_LABELS.get(_interface_lang, LIVE_LABELS["en"])
    return str(locale.get(key, LIVE_LABELS["en"].get(key, key)))

func _create_flight_controls() -> void:
    _flight_left = HORIZONTAL_STICK_V4.new() as Control
    _flight_left.name = "IcePlanetHorizontalFlightStick_WithDarkTrack"
    _flight_left.z_index = 50
    add_child(_flight_left)
    _flight_left.connect("direction_changed", Callable(self, "_on_left_stick"))
    _flight_right = FLIGHT_STICK.new() as Control
    _flight_right.name = "IcePlanetFullRotationFlightStick"
    _flight_right.z_index = 50
    add_child(_flight_right)
    _flight_right.connect("direction_changed", Callable(self, "_on_right_stick"))

func _ready() -> void:
    super._ready()
    _build_death_overlay()
    _restart_survival()
    call_deferred("_layout")

func _restart_survival() -> void:
    # An after-death second chance, not a persistent Restart button.
    _mission_complete = false
    _game_complete = false
    _survival_lost = false
    _mission_index = 0
    _score = 0
    _earned_crystals = 0
    _sun_primary_phase = -0.36
    _sun_secondary_phase = 0.0
    _sun_flare_phase = -0.93
    _sun_current_amplitude = SUN_BASE_AMPLITUDE
    _total_safe_ticks = 0
    _total_safe_seconds = 0.0
    _safe_tick_progress = 0.0
    _danger_tick_progress = 0.0
    _stable_seconds = 0.0
    _face_exposure = 0.0
    _face_side = 1
    _rotate_warning = false
    _planet_angle = 0.0
    _ocean_pitch = 0.0
    _ocean_extra_yaw = 0.0
    _spin = 0.18
    _left_vector = Vector2.ZERO
    _right_vector = Vector2.ZERO
    _hint_seconds = 0.0
    _elapsed = 0.0
    _liquid_fx_time = 0.0
    # Start near the centre of the safe band; the moving Sun still forces
    # a response quickly. Planet translation is the only orbital control.
    var safe_separation: float = 220.0 + 720.0 * (GREEN_START + GREEN_END) * 0.5
    _distance = clampf((_sun_location().x + safe_separation - 600.0) / 550.0, 0.0, 1.0)
    if _flight_left != null:
        _flight_left.call("clear_input")
    if _flight_right != null:
        _flight_right.call("clear_input")
    _update_temperatures()
    _position_bodies()
    _update_ocean()
    if _death_overlay != null:
        _death_overlay.hide()
    _update_labels()
    _refresh_action_visibility()
    queue_redraw()

func _planet_location() -> Vector2:
    # The orbit corridor is wide enough even at the MAX solar amplitude.
    # The player still controls translation exclusively with the left stick.
    var x: float = 600.0 + 550.0 * _distance
    return Vector2(maxf(x, _sun_location().x + 285.0), 318.0 + 9.0 * sin(_elapsed * 0.51))

func _difficulty_curve() -> float:
    return float(_earned_crystals)

func _sun_target_amplitude() -> float:
    # Asymptotic growth preserves a reachable safe band at the far edges.
    return SUN_BASE_AMPLITUDE + SUN_MAX_EXTRA_AMPLITUDE * (1.0 - exp(-0.22 * _difficulty_curve()))

func _sun_primary_rate() -> float:
    # +speed after EACH crystal. Smooth saturation prevents unwinnable jumps.
    return 0.78 + 1.10 * (1.0 - exp(-0.115 * _difficulty_curve()))

func _sun_secondary_rate() -> float:
    return 1.31 + 1.00 * (1.0 - exp(-0.095 * _difficulty_curve()))

func _sun_flare_rate() -> float:
    # Flare cycles shorten from roughly 11 s toward 5.5 s.
    return 0.56 + 0.58 * (1.0 - exp(-0.14 * _difficulty_curve()))

func _sun_flare_power() -> float:
    # Taller plasma eruptions and a stronger heating pulse per crystal.
    return 1.0 + 1.35 * (1.0 - exp(-0.17 * _difficulty_curve()))

func _sun_location() -> Vector2:
    # Continuous phases: no jump when the difficulty changes. Left half only.
    return Vector2(
        291.0 + _sun_current_amplitude * sin(_sun_primary_phase) + 17.0 * sin(_sun_secondary_phase),
        299.0 + 23.0 * sin(_sun_secondary_phase * (1.28 / 1.31) + 0.3)
    )

func _flare_amount() -> float:
    return pow(maxf(sin(_sun_flare_phase), 0.0), 12.0) * _sun_flare_power()

func _update_temperatures() -> void:
    var separation: float = _planet_location().x - _sun_location().x
    _actual_distance = clampf((separation - 220.0) / 720.0, 0.0, 1.0)
    _mean_temp = lerpf(115.0, -65.0, _actual_distance) + 12.0 * _flare_amount()
    # A slowly rotating face develops a localized hot spot. Rotation brings a
    # different face to the star and relieves it. Fictional educational model.
    var facing_heating: float = maxf(0.0, _face_exposure - 2.0) * 5.5
    var contrast: float = lerpf(30.0, 8.0, _spin)
    _warm_temp = _mean_temp + contrast + facing_heating
    _cool_temp = _mean_temp - contrast
    if _actual_distance < GREEN_START:
        _status = "hot"
    elif _actual_distance > GREEN_END:
        _status = "cold"
    elif _rotate_warning:
        _status = "spin"
    else:
        _status = "good"

func _facing_half() -> int:
    return 1 if cos(_planet_angle) >= 0.0 else -1

func _process(delta: float) -> void:
    # Deliberately DO NOT call super._process(): v1-v3.1 finish after three
    # stable seconds and freeze input. This game is endless until planet death.
    var dt: float = clampf(delta, 0.0, 0.12)
    if dt <= 0.0 or _survival_lost:
        return
    _elapsed += dt
    _liquid_fx_time += dt
    # Increase frequency immediately, but ease the amplitude toward its new
    # value. Never calculate sin(elapsed * new_speed): that would teleport Sun.
    _sun_primary_phase = wrapf(_sun_primary_phase + _sun_primary_rate() * dt, -TAU, TAU)
    _sun_secondary_phase = wrapf(_sun_secondary_phase + _sun_secondary_rate() * dt, -TAU, TAU)
    _sun_flare_phase = wrapf(_sun_flare_phase + _sun_flare_rate() * dt, -TAU, TAU)
    _sun_current_amplitude = move_toward(_sun_current_amplitude, _sun_target_amplitude(), SUN_AMPLITUDE_RESPONSE * dt)
    if _hint_seconds > 0.0:
        _hint_seconds = maxf(0.0, _hint_seconds - dt)
    # Left: translation only. No vertical input and no direct heat changes.
    _distance = clampf(_distance + _left_vector.x * 0.64 * dt, 0.0, 1.0)
    # Right: yaw (X) and pitch (Y) in both directions. All four directions
    # affect rotation and can turn the sun-facing hemisphere away.
    var turn: float = 0.14 + _right_vector.x * 3.30 + _right_vector.y * 1.65
    _planet_angle = wrapf(_planet_angle + turn * dt, -TAU, TAU)
    _ocean_pitch = wrapf(_ocean_pitch + _right_vector.y * 2.70 * dt, -TAU, TAU)
    _rotation_sign = -1.0 if turn < 0.0 else 1.0
    _spin = move_toward(_spin, clampf(0.17 + _right_vector.length() * 0.78, 0.0, 1.0), 1.45 * dt)
    var side: int = _facing_half()
    if side != _face_side:
        _face_side = side
        _face_exposure = 0.0
    else:
        _face_exposure += dt
    _rotate_warning = _face_exposure >= FACE_WARNING_SECONDS
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
    # The deeper into either bad zone, the faster each dangerous tick arrives.
    if _actual_distance < GREEN_START:
        var depth: float = (GREEN_START - _actual_distance) / GREEN_START
        return 0.90 + 3.30 * pow(clampf(depth, 0.0, 1.0), 1.4)
    if _actual_distance > GREEN_END:
        var depth: float = (_actual_distance - GREEN_END) / (1.0 - GREEN_END)
        return 0.90 + 3.30 * pow(clampf(depth, 0.0, 1.0), 1.4)
    return 0.0

func _advance_survival(delta: float) -> void:
    if _survival_lost:
        return
    var in_green: bool = _actual_distance >= GREEN_START and _actual_distance <= GREEN_END
    if in_green and not _rotate_warning:
        _safe_tick_progress += delta
        _total_safe_seconds += delta
        _total_safe_ticks = floori(_total_safe_seconds)
        _danger_tick_progress = maxf(0.0, _danger_tick_progress - delta * 0.85)
        while _safe_tick_progress >= SAFE_TICKS_PER_CRYSTAL:
            _safe_tick_progress -= SAFE_TICKS_PER_CRYSTAL
            _award_crystal()
    else:
        var rate: float = _danger_rate()
        if _rotate_warning:
            rate = maxf(rate, 0.95 + 0.20 * minf(_face_exposure - FACE_WARNING_SECONDS, 4.0))
        _danger_tick_progress += rate * delta
        if _danger_tick_progress >= DEATH_TICKS:
            _lose_planet()
    # Retain v3.1's green ring as a visual indication of the 5-tick cycle.
    _stable_seconds = HOLD_TO_WIN * _safe_tick_progress / SAFE_TICKS_PER_CRYSTAL

func _award_crystal() -> void:
    _earned_crystals += 1
    _score = _earned_crystals * 100  # Existing HUD expects _score / 100.
    if _mika_hud != null:
        _mika_hud.set("crystal_count", _earned_crystals)
    # The next frame takes the stronger Sun parameters automatically.
    # No pause, reset, scene transition, or instant position jump.
    if not _test_no_persistent_awards:
        var wallet: Node = get_node_or_null("/root/GameState")
        if wallet != null and wallet.has_method("add_coins"):
            wallet.call("add_coins", 1)

func _lose_planet() -> void:
    _survival_lost = true
    _game_complete = true
    _mission_complete = false
    if _actual_distance < GREEN_START:
        _death_cause = "cause_hot"
    elif _actual_distance > GREEN_END:
        _death_cause = "cause_cold"
    else:
        _death_cause = "cause_face"
    _left_vector = Vector2.ZERO
    _right_vector = Vector2.ZERO
    if _flight_left != null:
        _flight_left.call("clear_input")
    if _flight_right != null:
        _flight_right.call("clear_input")
    _show_death_overlay()

func _refresh_action_visibility() -> void:
    # No Next World, Restart or old Hint during endless gameplay.
    for button in [_hint_button, _restart_button, _next_button]:
        if button != null:
            button.disabled = true
            button.hide()
            button.mouse_filter = Control.MOUSE_FILTER_IGNORE

func _refresh_climate_labels() -> void:
    if _climate_labels.size() != 5:
        return
    _climate_labels[0].text = "%s  %d" % [_locale_text("crystals"), _earned_crystals]
    _climate_labels[1].text = "%s  %+d°C" % [_locale_text("temperature"), roundi(_mean_temp)]
    _climate_labels[2].text = "%s  %d" % [_locale_text("safe"), _total_safe_ticks]
    _climate_labels[3].text = _locale_text("rotate") if _rotate_warning else _locale_text("rotation")
    _climate_labels[4].text = "%s  %.1f/5" % [_locale_text("danger"), minf(DEATH_TICKS, _danger_tick_progress)]
    var blink: bool = sin(_elapsed * 10.0) >= 0.0
    var rotate_color: Color = Color("ff4355") if blink else Color("ffd4d8")
    _climate_labels[3].add_theme_color_override("font_color", rotate_color if _rotate_warning else Color("d0f5ff"))
    _climate_labels[4].add_theme_color_override("font_color", Color("ff917e") if _danger_tick_progress > 1.0 else Color("cceeff"))
    if _rotation_title != null:
        _rotation_title.text = _locale_text("rotate") if _rotate_warning else _word("spin")
        _rotation_title.add_theme_color_override("font_color", rotate_color if _rotate_warning else Color("e9faff"))
    if _distance_title != null:
        _distance_title.text = _word("motion")
    if _mika_header_subtitle != null:
        _mika_header_subtitle.text = _locale_text("subtitle")
    if _mika_hud != null:
        _mika_hud.set("crystal_count", _earned_crystals)

func _draw_temperature_gauge() -> void:
    # v2/v3.1's 88 separate coloured strips, now with a deliberately NARROW
    # habitable zone. Heat/red & ice/blue each take almost half the track.
    _panel(Rect2(361, 517, 558, 71), Color("071b30", 0.83), Color("3e95b8", 0.62), 20, 2)
    var length: float = SAFETY_BAR.size.x
    for part in range(88):
        var t: float = (float(part) + 0.5) / 88.0
        var tone: Color = Color("fa6d40") if t < GREEN_START else Color("73e2ab") if t <= GREEN_END else Color("6bbaf7")
        var r: Rect2 = Rect2(SAFETY_BAR.position + Vector2(float(part) * length / 88.0, 0), Vector2(length / 88.0 + 1.0, SAFETY_BAR.size.y))
        draw_rect(r, tone.darkened(0.15) if part % 2 == 0 else tone, true)
    var green_start: float = SAFETY_BAR.position.x + length * GREEN_START
    draw_rect(Rect2(green_start, SAFETY_BAR.position.y - 6.0, length * (GREEN_END - GREEN_START), SAFETY_BAR.size.y + 12.0), Color("baffdc", 0.28), false, 3.0)
    var marker: Vector2 = Vector2(SAFETY_BAR.position.x + _actual_distance * length, SAFETY_BAR.get_center().y)
    draw_line(marker - Vector2(0, 16), marker + Vector2(0, 19), Color("f5ffff"), 5.0, true)
    draw_circle(marker - Vector2(0, 21), 8.0, Color("e6ffff"))
    draw_string(ThemeDB.fallback_font, Vector2(388, 576), _readable("heat"), HORIZONTAL_ALIGNMENT_LEFT, 100, 15, Color("ffc9a5"))
    draw_string(ThemeDB.fallback_font, Vector2(548, 576), _readable("safe"), HORIZONTAL_ALIGNMENT_CENTER, 184, 15, Color("caffdc"))
    draw_string(ThemeDB.fallback_font, Vector2(812, 576), _readable("ice"), HORIZONTAL_ALIGNMENT_RIGHT, 70, 15, Color("b8e6ff"))
    # Five small progress cells: green fills while surviving; red fills when
    # the planet is being lost. Visible even when climate text is abbreviated.
    var is_safe: bool = _actual_distance >= GREEN_START and _actual_distance <= GREEN_END and not _rotate_warning
    var ratio: float = _safe_tick_progress / SAFE_TICKS_PER_CRYSTAL if is_safe else _danger_tick_progress / DEATH_TICKS
    for i in range(5):
        var block: Rect2 = Rect2(531.0 + 45.0 * float(i), 503.0, 37.0, 6.0)
        draw_rect(block, Color("70f4aa", 0.90) if is_safe and ratio * 5.0 > float(i) else Color("ff786e", 0.93) if not is_safe and ratio * 5.0 > float(i) else Color("35617a", 0.64), true)

func _update_ocean() -> void:
    if _ocean_sphere == null:
        return
    var overheated: float = smoothstep(40.0, 102.0, _warm_temp)
    var frozen: float = 1.0 - smoothstep(-30.0, 24.0, _cool_temp)
    if _rotate_warning:
        overheated = maxf(overheated, clampf((_face_exposure - FACE_WARNING_SECONDS) * 0.18, 0.0, 0.85))
    _ocean_sphere.call("update_world", _planet_angle, _ocean_pitch, overheated, frozen, _flare_amount(), _liquid_fx_time)

func _build_death_overlay() -> void:
    _death_overlay = Panel.new()
    _death_overlay.name = "PlanetLostOnlyAfterFiveDangerTicks"
    _death_overlay.z_index = 110
    _death_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
    _death_overlay.add_theme_stylebox_override("panel", MIKA_UI.stage_style())
    add_child(_death_overlay)
    _death_title = Label.new()
    _death_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    _death_title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
    _death_title.add_theme_color_override("font_color", Color("ffb0a7"))
    _death_overlay.add_child(_death_title)
    _death_detail = Label.new()
    _death_detail.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    _death_detail.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
    _death_detail.add_theme_color_override("font_color", Color("e9f9ff"))
    _death_overlay.add_child(_death_detail)
    _death_retry = Button.new()
    _death_retry.name = "AfterDeathTryAgainOnly"
    _death_retry.add_theme_stylebox_override("normal", MIKA_UI.button_style())
    _death_retry.add_theme_stylebox_override("hover", MIKA_UI.button_style(true))
    _death_retry.add_theme_stylebox_override("pressed", MIKA_UI.button_style(true))
    _death_retry.pressed.connect(_restart_survival)
    _death_overlay.add_child(_death_retry)
    _death_overlay.hide()
    _layout_death_overlay()

func _layout() -> void:
    super._layout()
    _layout_death_overlay()

func _layout_death_overlay() -> void:
    if _death_overlay == null or _stage_rect.size.x < 100.0:
        return
    var w: float = minf(_stage_rect.size.x * 0.70, 500.0)
    var h: float = minf(_stage_rect.size.y * 0.60, 255.0)
    _death_overlay.position = _stage_rect.get_center() - Vector2(w, h) * 0.5
    _death_overlay.size = Vector2(w, h)
    _death_title.position = Vector2(12, h * 0.08)
    _death_title.size = Vector2(w - 24, h * 0.26)
    _death_title.add_theme_font_size_override("font_size", maxi(16, roundi(h * 0.105)))
    _death_detail.position = Vector2(12, h * 0.37)
    _death_detail.size = Vector2(w - 24, h * 0.19)
    _death_detail.add_theme_font_size_override("font_size", maxi(13, roundi(h * 0.071)))
    _death_retry.position = Vector2(w * 0.24, h * 0.66)
    _death_retry.size = Vector2(w * 0.52, h * 0.23)
    _death_retry.add_theme_font_size_override("font_size", maxi(13, roundi(h * 0.08)))

func _show_death_overlay() -> void:
    if _death_overlay == null:
        return
    _death_title.text = _locale_text("lost")
    _death_detail.text = _locale_text(_death_cause)
    _death_retry.text = _locale_text("again")
    _layout_death_overlay()
    _death_overlay.show()
