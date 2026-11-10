extends "res://planet_hub/games/ice_planet/IcePlanetMIKAUIV1.gd"
## MIKA Ice Planet v2 — two-joystick climate rescue.
## Builds on the exact approved native toolbar; preserves four missions, model and localization.
## Sun and globe use existing project textures/shaders, without duplicated art.

const BOARD := Vector2(1280.0, 710.0)
const SUN_TEXTURE: Texture2D = preload("res://solar/sun/sun_surface_1536x768.png")
const SUN_PLASMA: Texture2D = preload("res://solar/sun/sun_plasma_flow_512x256.png")
const SUN_SHADER: Shader = preload("res://solar/sun/sun_body.gdshader")
const SUN_CORONA_SHADER: Shader = preload("res://solar/sun/sun_corona.gdshader")
const EARTH_SHADER: Shader = preload("res://planet_hub/games/ice_planet/climate_earth_v2.gdshader")
const EARTH_TEXTURE: Texture2D = preload("res://planet2d/textures/earth_surface.jpg")
const MARS_TEXTURE: Texture2D = preload("res://planet2d/textures/mars_surface.jpg")
const NEPTUNE_TEXTURE: Texture2D = preload("res://planet2d/textures/neptune_surface.jpg")
const CLOUDS_TEXTURE: Texture2D = preload("res://planet2d/textures/earth_clouds_procedural.png")
const LIGHTS_TEXTURE: Texture2D = preload("res://planet2d/textures/earth_night_lights_procedural.png")
const LEFT_STICK := Vector2(196.0, 625.0)
const RIGHT_STICK := Vector2(1084.0, 625.0)
const STICK_RADIUS := 60.0
const SAFETY_BAR := Rect2(378.0, 531.0, 524.0, 28.0)

const LABELS := {
    "ru": {"title":"ЛЕДЯНАЯ ПЛАНЕТА", "subtitle":"Сохрани океан Земли", "climate":"КЛИМАТ ЗЕМЛИ", "avg":"СРЕДНЯЯ", "day":"ДЕНЬ", "night":"НОЧЬ", "ok":"БЕЗОПАСНО", "hot":"ЖАРКО", "cold":"ХОЛОДНО", "spin":"УСКОРЬ ВРАЩЕНИЕ", "flare":"ВСПЫШКА НА СОЛНЦЕ", "near":"БЛИЖЕ", "far":"ДАЛЬШЕ", "slow":"МЕДЛЕННЕЕ", "fast":"БЫСТРЕЕ", "distance":"РАССТОЯНИЕ", "rotation":"ВРАЩЕНИЕ", "safe":"ЗОНА ЖИЗНИ", "heat":"ЖАРА", "ice":"ЛЁД", "stable":"УДЕРЖИ КЛИМАТ", "hint":"Подсказка", "restart":"↻ Заново", "next":"Далее →"},
    "en": {"title":"ICE PLANET", "subtitle":"Keep Earth's ocean alive", "climate":"EARTH'S CLIMATE", "avg":"AVERAGE", "day":"DAY", "night":"NIGHT", "ok":"SAFE", "hot":"TOO HOT", "cold":"TOO COLD", "spin":"SPIN FASTER", "flare":"SOLAR FLARE", "near":"NEARER", "far":"FARTHER", "slow":"SLOWER", "fast":"FASTER", "distance":"DISTANCE", "rotation":"ROTATION", "safe":"HABITABLE ZONE", "heat":"HEAT", "ice":"ICE", "stable":"HOLD THE CLIMATE", "hint":"Hint", "restart":"↻ Restart", "next":"Next →"},
    "pt": {"title":"PLANETA GELADO", "subtitle":"Proteja o oceano da Terra", "climate":"CLIMA DA TERRA", "avg":"MÉDIA", "day":"DIA", "night":"NOITE", "ok":"SEGURO", "hot":"MUITO QUENTE", "cold":"MUITO FRIO", "spin":"GIRE MAIS RÁPIDO", "flare":"ERUPÇÃO SOLAR", "near":"MAIS PERTO", "far":"MAIS LONGE", "slow":"DEVAGAR", "fast":"RÁPIDO", "distance":"DISTÂNCIA", "rotation":"ROTAÇÃO", "safe":"ZONA HABITÁVEL", "heat":"CALOR", "ice":"GELO", "stable":"MANTENHA O CLIMA", "hint":"Dica", "restart":"↻ Reiniciar", "next":"Próximo →"},
    "es": {"title":"PLANETA HELADO", "subtitle":"Protege el océano terrestre", "climate":"CLIMA DE LA TIERRA", "avg":"MEDIA", "day":"DÍA", "night":"NOCHE", "ok":"SEGURO", "hot":"MUCHO CALOR", "cold":"MUCHO FRÍO", "spin":"GIRA MÁS RÁPIDO", "flare":"ERUPCIÓN SOLAR", "near":"MÁS CERCA", "far":"MÁS LEJOS", "slow":"MÁS LENTO", "fast":"MÁS RÁPIDO", "distance":"DISTANCIA", "rotation":"ROTACIÓN", "safe":"ZONA HABITABLE", "heat":"CALOR", "ice":"HIELO", "stable":"MANTÉN EL CLIMA", "hint":"Pista", "restart":"↻ Reiniciar", "next":"Siguiente →"},
    "de": {"title":"EISPLANET", "subtitle":"Rette den Ozean der Erde", "climate":"ERDKLIMA", "avg":"MITTEL", "day":"TAG", "night":"NACHT", "ok":"SICHER", "hot":"ZU HEISS", "cold":"ZU KALT", "spin":"SCHNELLER DREHEN", "flare":"SONNENERUPTION", "near":"NÄHER", "far":"WEITER", "slow":"LANGSAMER", "fast":"SCHNELLER", "distance":"ENTFERNUNG", "rotation":"ROTATION", "safe":"LEBENSZONE", "heat":"HITZE", "ice":"EIS", "stable":"KLIMA HALTEN", "hint":"Tipp", "restart":"↻ Neustart", "next":"Weiter →"},
    "fr": {"title":"PLANÈTE GELÉE", "subtitle":"Sauve l'océan terrestre", "climate":"CLIMAT TERRESTRE", "avg":"MOYENNE", "day":"JOUR", "night":"NUIT", "ok":"SÛR", "hot":"TROP CHAUD", "cold":"TROP FROID", "spin":"TOURNE PLUS VITE", "flare":"ÉRUPTION SOLAIRE", "near":"PLUS PRÈS", "far":"PLUS LOIN", "slow":"PLUS LENT", "fast":"PLUS VITE", "distance":"DISTANCE", "rotation":"ROTATION", "safe":"ZONE HABITABLE", "heat":"CHALEUR", "ice":"GLACE", "stable":"STABILISE LE CLIMAT", "hint":"Indice", "restart":"↻ Recommencer", "next":"Suivant →"}
}

var _sun_corona: ColorRect
var _sun_body: ColorRect
var _earth_body: ColorRect
var _sun_material: ShaderMaterial
var _corona_material: ShaderMaterial
var _earth_material: ShaderMaterial
var _climate_labels: Array[Label] = []
var _distance_title: Label
var _rotation_title: Label
var _mission_title: Label
var _climate_status: Label
var _hold_label: Label
var _left_action: String = ""
var _mouse_action: String = ""
var _mouse_start: Vector2 = Vector2.ZERO
var _mouse_distance_start: float = 0.0
var _mouse_spin_start: float = 0.0
var _touch_actions: Dictionary = {}
var _sun_center := Vector2(230.0, 332.0)
var _earth_center := Vector2(865.0, 337.0)
var _sun_radius := 115.0
var _world_radius := 115.0

func _ready() -> void:
    super._ready()
    _hide_old_elements()
    _make_celestial_bodies()
    _make_climate_labels()
    _layout()
    call_deferred("_layout")

func _hide_old_elements() -> void:
    for widget in [
        _mission_label, _phase_label, _panel_title, _state_label,
        _average_label, _warm_label, _cool_label, _stable_label,
        _distance_label, _rotation_label, _distance_near_label,
        _distance_far_label, _rotation_slow_label, _rotation_fast_label,
        _tip_label, _guide_label, _model_note, _instruction_label,
        _title, _subtitle, _round_label, _score_label, _language_picker
    ]:
        if widget != null:
            widget.hide()
            widget.mouse_filter = Control.MOUSE_FILTER_IGNORE

func _shader_rectangle(title: String, shader: Shader) -> ColorRect:
    var rect := ColorRect.new()
    rect.name = title
    rect.color = Color.WHITE
    rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
    var material := ShaderMaterial.new()
    material.shader = shader
    rect.material = material
    add_child(rect)
    return rect

func _make_celestial_bodies() -> void:
    _sun_corona = _shader_rectangle("SunCoronaOriginalShader", SUN_CORONA_SHADER)
    _corona_material = _sun_corona.material as ShaderMaterial
    _corona_material.set_shader_parameter("solar_radius", 0.641)
    _corona_material.set_shader_parameter("corona_strength", 1.45)
    _sun_body = _shader_rectangle("SunSurfaceOriginalShader", SUN_SHADER)
    _sun_material = _sun_body.material as ShaderMaterial
    _sun_material.set_shader_parameter("surface_tex", SUN_TEXTURE)
    _sun_material.set_shader_parameter("plasma_flow", SUN_PLASMA)
    _sun_material.set_shader_parameter("rotation_seconds", 21.0)
    _sun_material.set_shader_parameter("activity", 0.6)
    _earth_body = _shader_rectangle("EarthMarsNeptuneClimateGlobe", EARTH_SHADER)
    _earth_material = _earth_body.material as ShaderMaterial
    _earth_material.set_shader_parameter("earth_map", EARTH_TEXTURE)
    _earth_material.set_shader_parameter("mars_map", MARS_TEXTURE)
    _earth_material.set_shader_parameter("neptune_map", NEPTUNE_TEXTURE)
    _earth_material.set_shader_parameter("cloud_map", CLOUDS_TEXTURE)
    _earth_material.set_shader_parameter("night_map", LIGHTS_TEXTURE)
    # Controls must remain above the two planets in the same game SubViewport.
    for btn in [_hint_button, _restart_button, _next_button, _mika_back_button]:
        if btn != null:
            btn.move_to_front()
    if _mika_title_panel != null:
        _mika_title_panel.move_to_front()
    if _mika_hud != null:
        _mika_hud.move_to_front()

func _make_text(size_px: int, color: Color, align: HorizontalAlignment = HORIZONTAL_ALIGNMENT_CENTER) -> Label:
    var lbl := _make_label(size_px, color, align)
    lbl.add_theme_color_override("font_outline_color", Color("06152a"))
    lbl.add_theme_constant_override("outline_size", 2)
    return lbl

func _make_climate_labels() -> void:
    for i in range(5):
        _climate_labels.append(_make_text(20 if i > 0 else 16, Color("e7fbff")))
    _mission_title = _make_text(20, Color("ffe3a7"))
    _climate_status = _make_text(24, Color("bcffe5"))
    _hold_label = _make_text(16, Color("b0f8df"))
    _distance_title = _make_text(17, Color("e9faff"))
    _rotation_title = _make_text(17, Color("e9faff"))
    _refresh_climate_labels()

func _readable(key: String) -> String:
    var locale: Dictionary = LABELS.get(_interface_lang, LABELS["en"])
    return str(locale.get(key, LABELS["en"].get(key, key)))

func _refresh_climate_labels() -> void:
    if _climate_labels.size() != 5:
        return
    var flare: float = _flare_amount()
    _climate_labels[0].text = _readable("climate")
    _climate_labels[1].text = "%s: %+d°C" % [_readable("avg"), roundi(_mean_temp)]
    _climate_labels[2].text = "%s: %+d°C" % [_readable("day"), roundi(_warm_temp)]
    _climate_labels[3].text = "%s: %+d°C" % [_readable("night"), roundi(_cool_temp)]
    var state: String = "ok" if (_status == "good" or _mission_complete) else "spin" if _status == "spin" else "hot" if _status == "hot" else "cold"
    _climate_labels[4].text = _readable("flare") if flare > 0.42 else _readable(state)
    _climate_labels[4].add_theme_color_override("font_color", Color("ffb58d") if flare > 0.42 else Color("9ff1c3") if state == "ok" else Color("ffddba"))
    _mission_title.text = "%d / %d  ·  %s" % [mini(_mission_index+1, _missions.size()), _missions.size(), _learn("mission_" + _mission_id())]
    _climate_status.text = _learn(_status_key())
    _climate_status.add_theme_color_override("font_color", Color("a4ffcc") if (_status == "good" or _mission_complete) else Color("ffccaa"))
    _hold_label.text = "%s  %.1f / %.0f s" % [_readable("stable"), _stable_seconds, HOLD_TO_WIN]
    _distance_title.text = "◀  %s   ·   %s  ▶" % [_readable("near"), _readable("far")]
    _rotation_title.text = "◀  %s   ·   %s  ▶" % [_readable("slow"), _readable("fast")]
    _hint_button.text = _readable("hint")
    _restart_button.text = _readable("restart")
    _next_button.text = _readable("next") if not _game_complete else _tr("again") + " ↻"
    if _mika_header_title != null:
        _mika_header_title.text = _readable("title")
        _mika_header_subtitle.text = _readable("subtitle")

func _update_labels() -> void:
    super._update_labels()
    _refresh_climate_labels()

func _flare_amount() -> float:
    # Quiet interval followed by a brief, visible solar storm every ~15s.
    return pow(maxf(sin(_elapsed * 0.41 - 0.75), 0.0), 20.0)

func _update_temperatures() -> void:
    super._update_temperatures()
    var flare: float = _flare_amount()
    if flare > 0.01:
        var extra: float = flare * 11.5
        _mean_temp += extra
        _warm_temp += extra
        _cool_temp += extra
        if _warm_temp >= 100.0:
            _status = "hot"
        elif _cool_temp <= 2.0:
            _status = "cold"
        elif _spin < 0.55:
            _status = "spin"
        else:
            _status = "good"

func _process(delta: float) -> void:
    super._process(delta)
    if _earth_material != null:
        var hot: float = smoothstep(60.0, 101.0, _mean_temp)
        var cold: float = 1.0 - smoothstep(-22.0, 20.0, _mean_temp)
        _earth_material.set_shader_parameter("surface_phase", _planet_angle)
        _earth_material.set_shader_parameter("cloud_phase", _planet_angle * 1.13)
        _earth_material.set_shader_parameter("hot_factor", hot)
        _earth_material.set_shader_parameter("ice_factor", cold)
        _earth_material.set_shader_parameter("solar_flare", _flare_amount())
    if _sun_material != null:
        _sun_material.set_shader_parameter("activity", 0.40 + _flare_amount() * 0.60)
    if _corona_material != null:
        _corona_material.set_shader_parameter("corona_strength", 1.1 + _flare_amount() * 1.55)
    _position_bodies()

func _safe_region(view: Vector2) -> Rect2:
    return _safe_view_area(view)

func _layout() -> void:
    if _mika_title_panel == null or _mika_back_button == null or _mika_hud == null:
        super._layout()
        return
    var view: Vector2 = size
    if view.x <= 1.0 or view.y <= 1.0:
        view = get_viewport_rect().size
    if view.x <= 180.0 or view.y <= 180.0:
        return
    var safe: Rect2 = _safe_region(view)
    _header_bottom = MIKA_TOOLBAR.relayout(view, safe, _mika_back_button, _mika_hud, _mika_title_panel, _mika_header_title, _mika_header_subtitle)
    var pad_x: float = clampf(safe.size.x * 0.017, 7.0, 28.0)
    var pad_y: float = clampf(safe.size.y * 0.018, 5.0, 18.0)
    _stage_rect = Rect2(safe.position.x + pad_x, _header_bottom + pad_y,
            maxf(128.0, safe.size.x - pad_x * 2.0),
            maxf(130.0, safe.end.y - _header_bottom - pad_y * 2.0))
    _scale = maxf(0.05, minf(_stage_rect.size.x / BOARD.x, _stage_rect.size.y / BOARD.y))
    _origin = _stage_rect.position + (_stage_rect.size - BOARD * _scale) * 0.5
    if _sun_corona != null:
        _position_bodies()
    if _climate_labels.size() == 5:
        for index in range(5):
            var x: float = 30.0 + (float(index) * 244.0)
            _put(_climate_labels[index], Rect2(x, 33, 244, 55))
            _climate_labels[index].add_theme_font_size_override("font_size", 16 if index == 0 else 17)
        _put(_mission_title, Rect2(308, 125, 664, 38))
        _put(_climate_status, Rect2(435, 163, 410, 39))
        _put(_hold_label, Rect2(445, 200, 390, 26))
        _put(_distance_title, Rect2(40, 537, 330, 32))
        _put(_rotation_title, Rect2(922, 537, 322, 32))
        _put(_hint_button, Rect2(468, 598, 135, 55))
        _put(_restart_button, Rect2(625, 598, 154, 55))
        _put(_next_button, Rect2(479, 596, 311, 60))
        _hint_button.add_theme_font_size_override("font_size", 16)
        _restart_button.add_theme_font_size_override("font_size", 16)
        _next_button.add_theme_font_size_override("font_size", 18)
    queue_redraw()

func _sun_location() -> Vector2:
    return Vector2(221.0 + 36.0 * sin(_elapsed * 0.39), 327.0 + 12.0 * sin(_elapsed * 0.78 + 1.2))

func _planet_location() -> Vector2:
    return Vector2(595.0 + _distance * 409.0, 334.0)

func _position_bodies() -> void:
    if _sun_body == null or _earth_body == null or _sun_corona == null:
        return
    _sun_center = _sun_location()
    _earth_center = _planet_location()
    var approach: float = 1.0 + 0.15 * sin(_elapsed * 0.39 + 0.45)
    _sun_radius = 110.0 * approach
    _world_radius = 112.0
    _put(_sun_corona, Rect2(_sun_center - Vector2.ONE * _sun_radius * 1.57, Vector2.ONE * _sun_radius * 3.14))
    _put(_sun_body, Rect2(_sun_center - Vector2.ONE * _sun_radius, Vector2.ONE * _sun_radius * 2.0))
    _put(_earth_body, Rect2(_earth_center - Vector2.ONE * _world_radius * 1.16, Vector2.ONE * _world_radius * 2.32))

func _to_virtual(view_position: Vector2) -> Vector2:
    return (view_position - _origin) / maxf(_scale, 0.001)

func _input(event: InputEvent) -> void:
    if _mission_complete or _game_complete:
        return
    if event is InputEventMouseButton:
        var click: InputEventMouseButton = event as InputEventMouseButton
        if click.button_index == MOUSE_BUTTON_LEFT:
            if click.pressed:
                _mouse_start = _to_virtual(click.position)
                _mouse_action = _choose_action(_mouse_start)
                _mouse_distance_start = _distance
                _mouse_spin_start = _spin
                if not _mouse_action.is_empty():
                    _tap_action(_mouse_action, _mouse_start)
                    get_viewport().set_input_as_handled()
            else:
                _mouse_action = ""
    elif event is InputEventMouseMotion and not _mouse_action.is_empty():
        var motion: InputEventMouseMotion = event as InputEventMouseMotion
        _drag_action(_mouse_action, _mouse_start, _to_virtual(motion.position), _mouse_distance_start, _mouse_spin_start)
        get_viewport().set_input_as_handled()
    elif event is InputEventScreenTouch:
        var touch: InputEventScreenTouch = event as InputEventScreenTouch
        if touch.pressed:
            var start: Vector2 = _to_virtual(touch.position)
            var action: String = _choose_action(start)
            if not action.is_empty():
                _touch_actions[touch.index] = {"action":action, "point":start, "distance":_distance, "spin":_spin}
                _tap_action(action, start)
                get_viewport().set_input_as_handled()
        else:
            _touch_actions.erase(touch.index)
    elif event is InputEventScreenDrag:
        var drag: InputEventScreenDrag = event as InputEventScreenDrag
        if _touch_actions.has(drag.index):
            var info: Dictionary = _touch_actions[drag.index]
            _drag_action(str(info["action"]), info["point"], _to_virtual(drag.position), float(info["distance"]), float(info["spin"]))
            get_viewport().set_input_as_handled()

func _choose_action(point: Vector2) -> String:
    if point.distance_to(LEFT_STICK) <= 89.0:
        return "distance"
    if point.distance_to(RIGHT_STICK) <= 89.0:
        return "rotation"
    if point.distance_to(_earth_center) <= _world_radius * 1.1:
        return "planet"
    return ""

func _tap_action(action: String, point: Vector2) -> void:
    # Tapping either side works independently without requiring a drag.
    if action == "distance":
        _distance = clampf(_distance + (0.07 if point.x > LEFT_STICK.x else -0.07), 0.0, 1.0)
    elif action == "rotation":
        _spin = clampf(_spin + (0.11 if point.x > RIGHT_STICK.x else -0.11), 0.0, 1.0)
    _update_temperatures()
    _update_labels()
    queue_redraw()

func _drag_action(action: String, start: Vector2, now: Vector2, original_distance: float, original_spin: float) -> void:
    var move: Vector2 = now - start
    match action:
        "distance":
            _distance = clampf(original_distance + move.x / 310.0, 0.0, 1.0)
        "rotation":
            _spin = clampf(original_spin + move.x / 265.0, 0.0, 1.0)
        "planet":
            if absf(move.x) >= absf(move.y):
                _distance = clampf(original_distance + move.x / 420.0, 0.0, 1.0)
            else:
                _spin = clampf(original_spin - move.y / 295.0, 0.0, 1.0)
    _update_temperatures()
    _update_labels()
    _position_bodies()
    queue_redraw()

func _draw() -> void:
    var canvas: Rect2 = Rect2(Vector2.ZERO, size)
    draw_rect(canvas, Color("061225"), true)
    for k in range(105):
        var dot := Vector2(fmod(float(k * 201 + 41), maxf(size.x, 1.0)), fmod(float(k * 173 + 19), maxf(size.y, 1.0)))
        draw_circle(dot, 1.0 + float(k % 3) * 0.38, Color(0.51, 0.76, 1.0, 0.18 + 0.04 * float(k % 4)))
    if _stage_rect.size.x <= 0.0:
        return
    var skin := MIKA_UI.stage_style()
    skin.bg_color = Color(0.020, 0.070, 0.145, 0.88)
    draw_style_box(skin, _stage_rect)
    draw_set_transform(_origin, 0.0, Vector2.ONE * _scale)
    _draw_space_theatre()
    _draw_climate_bar()
    _draw_temperature_gauge()
    _draw_joystick(LEFT_STICK, (_distance - 0.50) * 2.0, Color("74ceff"))
    _draw_joystick(RIGHT_STICK, (_spin - 0.50) * 2.0, Color("86f1c7"))
    draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

func _draw_space_theatre() -> void:
    # Atmospheric depth is confined to the main stage, not to the toolbar.
    var flare: float = _flare_amount()
    draw_circle(_sun_center, 235.0, Color(1.0, 0.33, 0.04, 0.018 + flare * 0.07))
    draw_circle(_sun_center, 167.0, Color(1.0, 0.49, 0.07, 0.03 + flare * 0.10))
    draw_line(_sun_center + Vector2(135, 7), _earth_center - Vector2(105, 0), Color(0.36, 0.62, 0.82, 0.21), 3.0, true)
    var trajectory := PackedVector2Array()
    for t in range(45):
        var fraction: float = float(t) / 44.0
        trajectory.append(Vector2(112.0 + 274.0 * fraction, 401.0 + 12.0 * sin(fraction * 10.0 + _elapsed * 0.38)))
    draw_polyline(trajectory, Color(1.0, 0.61, 0.30, 0.23), 2.0, true)
    for k in range(12):
        var a: float = TAU * float(k) / 12.0 + _elapsed * 0.13
        var outward: float = _sun_radius * (1.04 + flare * 0.80 + 0.08 * sin(_elapsed * 1.4 + float(k)))
        var p0: Vector2 = _sun_center + Vector2.from_angle(a) * _sun_radius * 0.93
        var p1: Vector2 = _sun_center + Vector2.from_angle(a + 0.22 * sin(_elapsed + float(k))) * outward
        draw_line(p0, p1, Color(1.0, 0.56, 0.16, 0.13 + flare * 0.70), 2.0 + 4.0 * flare, true)
        if flare > 0.22 and k % 3 == 0:
            draw_arc(p1, 22.0 + 32.0 * flare, a - 0.76, a + 0.92, 24, Color(1.0, 0.62, 0.19, flare * 0.60), 3.0, true)
    var progress: float = clampf(_stable_seconds / HOLD_TO_WIN, 0.0, 1.0)
    draw_arc(_earth_center, 134.0, -PI * 0.5, -PI * 0.5 + TAU * maxf(progress, 0.002), 100, Color("8affcd", 0.8), 5.0, true)
    if _mission_complete:
        for j in range(12):
            var a: float = _elapsed * 0.24 + float(j) * TAU / 12.0
            draw_circle(_earth_center + Vector2.from_angle(a) * 149.0, 4.2, Color(0.56, 1.0, 0.81, 0.78))

func _draw_climate_bar() -> void:
    _panel(Rect2(28, 25, 1224, 68), Color("09253c", 0.94), Color("5be2ff", 0.82), 21, 2)
    for x in [273, 517, 761, 1005]:
        draw_line(Vector2(x, 37), Vector2(x, 82), Color("5dd3ef", 0.28), 1.0, true)
    _panel(Rect2(449, 124, 382, 6), Color("123752", 0.78), Color("123752"), 3, 0)

func _draw_temperature_gauge() -> void:
    _panel(Rect2(361, 517, 558, 71), Color("071b30", 0.83), Color("3e95b8", 0.62), 20, 2)
    var total: float = SAFETY_BAR.size.x
    var segments: int = 88
    for part in range(segments):
        var t: float = float(part) / float(segments)
        var tint: Color = Color("fa6d40") if t < 0.27 else Color("73e2ab") if t < 0.59 else Color("6bbaf7")
        var place: Rect2 = Rect2(SAFETY_BAR.position + Vector2(t * total, 0.0), Vector2(total / float(segments) + 1.0, SAFETY_BAR.size.y))
        draw_rect(place, tint.darkened(0.15) if part % 2 == 0 else tint, true)
    draw_rect(Rect2(SAFETY_BAR.position.x + total * 0.27, SAFETY_BAR.position.y - 6.0, total * 0.32, SAFETY_BAR.size.y + 12.0), Color("baffdc", 0.13), false, 3.0)
    var marker: Vector2 = Vector2(SAFETY_BAR.position.x + _distance * total, SAFETY_BAR.get_center().y)
    draw_line(marker - Vector2(0, 16), marker + Vector2(0, 19), Color("f5ffff"), 5.0, true)
    draw_circle(marker - Vector2(0, 21), 8.0, Color("e6ffff"))
    draw_string(ThemeDB.fallback_font, Vector2(388, 576), _readable("heat"), HORIZONTAL_ALIGNMENT_LEFT, 100, 15, Color("ffc9a5"))
    draw_string(ThemeDB.fallback_font, Vector2(554, 576), _readable("safe"), HORIZONTAL_ALIGNMENT_CENTER, 170, 15, Color("caffdc"))
    draw_string(ThemeDB.fallback_font, Vector2(812, 576), _readable("ice"), HORIZONTAL_ALIGNMENT_RIGHT, 70, 15, Color("b8e6ff"))

func _draw_joystick(center: Vector2, position_t: float, accent: Color) -> void:
    draw_circle(center, STICK_RADIUS + 7.0, Color("102f4a", 0.96))
    draw_arc(center, STICK_RADIUS + 7.0, 0.0, TAU, 64, accent.darkened(0.25), 3.0, true)
    draw_circle(center, 44.0, Color("0b263c", 0.96))
    draw_line(center - Vector2(47, 0), center + Vector2(47, 0), Color(accent.r, accent.g, accent.b, 0.30), 3.0, true)
    draw_circle(center + Vector2(clampf(position_t, -1.0, 1.0) * 40.0, -2.0), 22.0, accent)
    draw_circle(center + Vector2(clampf(position_t, -1.0, 1.0) * 40.0 - 6.0, -7.0), 7.0, Color(1.0, 1.0, 1.0, 0.61))
    draw_string(ThemeDB.fallback_font, center + Vector2(-74.0, 7.0), "‹", HORIZONTAL_ALIGNMENT_CENTER, 23, 33, Color("c9f5ff"))
    draw_string(ThemeDB.fallback_font, center + Vector2(59.0, 7.0), "›", HORIZONTAL_ALIGNMENT_CENTER, 23, 33, Color("c9f5ff"))
