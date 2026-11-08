extends Control
## MIKA / Catch a Sunbeam v2 — living fungal photovoltaic greenhouse.
## Purely procedural until optional, separately replaceable SVG/PNG art is supplied.
signal bud_pressed(index: int)

const FLOWER_COUNT: int = 6
const ENERGY_CAPACITY: float = 50.0
const ART_DIR: String = "res://planet_hub/games/catch_sunbeam/art/"
const SKY: Color = Color("#081f31")
const CYAN: Color = Color("#72e8ff")
const BIO: Color = Color("#7af0b4")

var opening: Array[float] = [0.0, 0.0, 0.0, 0.0, 0.0, 0.0]
var beam_position: float = 0.0
var energy: float = 0.0
var _assets: Dictionary = {}
var _pulses: Array[Dictionary] = []
var _time: float = 0.0
var _sunrise: float = 0.0

func _ready() -> void:
    mouse_filter = Control.MOUSE_FILTER_STOP
    process_mode = Node.PROCESS_MODE_ALWAYS
    for key in ["background", "soil", "roots", "bud_closed", "bud_open", "sun", "battery"]:
        _assets[key] = _load_optional_art(String(key))
    queue_redraw()

func _load_optional_art(key: String) -> Texture2D:
    for extension in ["svg", "png", "webp"]:
        var path: String = ART_DIR + key + "." + extension
        if ResourceLoader.exists(path):
            var found: Texture2D = load(path) as Texture2D
            if found != null:
                return found
    return null

func flower_uv(index: int) -> float:
    return 0.105 + 0.158 * float(index)

func flower_center(index: int) -> Vector2:
    return Vector2(size.x * flower_uv(index), size.y * 0.405)

func flower_radius() -> float:
    return clampf(minf(size.x / 13.0, size.y * 0.17), 15.0, 52.0)

func set_visual_state(bud_opening: Array[float], moving_beam: float, charge: float) -> void:
    opening = bud_opening.duplicate()
    beam_position = clampf(moving_beam, 0.0, 1.0)
    energy = clampf(charge, 0.0, ENERGY_CAPACITY)
    queue_redraw()

func pulse_from(index: int) -> void:
    if index < 0 or index >= FLOWER_COUNT:
        return
    _pulses.append({"index": index, "age": 0.0})
    queue_redraw()

func reset_fx() -> void:
    _pulses.clear()
    _time = 0.0
    queue_redraw()

func _process(delta: float) -> void:
    _time += delta
    var updated: Array[Dictionary] = []
    for element in _pulses:
        var pulse: Dictionary = element
        pulse["age"] = float(pulse["age"]) + delta
        if float(pulse["age"]) < 1.15:
            updated.append(pulse)
    _pulses = updated
    if not _pulses.is_empty():
        queue_redraw()

func _gui_input(event: InputEvent) -> void:
    var point: Vector2 = Vector2.ZERO
    var touched: bool = false
    if event is InputEventMouseButton:
        var click: InputEventMouseButton = event as InputEventMouseButton
        if click.button_index == MOUSE_BUTTON_LEFT and click.pressed:
            point = click.position
            touched = true
    elif event is InputEventScreenTouch:
        var tap: InputEventScreenTouch = event as InputEventScreenTouch
        if tap.pressed:
            point = tap.position
            touched = true
    if not touched:
        return
    var max_distance: float = minf(maxf(flower_radius() * 1.35, 28.0), size.x * 0.070)
    for index in range(FLOWER_COUNT):
        if point.distance_to(flower_center(index)) <= max_distance:
            bud_pressed.emit(index)
            accept_event()
            return

func _draw() -> void:
    if size.x < 100.0 or size.y < 80.0:
        return
    _draw_greenhouse()
    _draw_solar_beam()
    _draw_soil_and_roots()
    _draw_flowers()
    _draw_battery()
    _draw_energy_pulses()

func _draw_greenhouse() -> void:
    draw_rect(Rect2(Vector2.ZERO, size), SKY)
    var bg: Texture2D = _assets.get("background") as Texture2D
    if bg != null:
        draw_texture_rect(bg, Rect2(Vector2.ZERO, size), false)
    else:
        for line in range(9):
            var x: float = size.x * float(line + 1) / 10.0
            draw_line(Vector2(x, 0), Vector2(x, size.y * 0.72), Color(0.32, 0.67, 0.72, 0.1), 1.5, true)
        for ring in range(7):
            var r: float = size.y * (0.17 + 0.078 * float(ring))
            draw_arc(Vector2(size.x * 0.5, size.y * 0.83), r, PI, TAU, 44, Color(0.15, 0.83, 0.71, 0.06), 1.2, true)
        for star in range(37):
            var x: float = fposmod(float(star * 177 + 19), size.x)
            var y: float = fposmod(float(star * 91 + 27), size.y * 0.61)
            draw_circle(Vector2(x, y), 0.9, Color(0.72, 0.95, 0.89, 0.22))

func _draw_solar_beam() -> void:
    var sun: Vector2 = Vector2(size.x * 0.084, size.y * 0.12)
    var target: Vector2 = Vector2(size.x * beam_position, size.y * 0.405)
    var beam_radius: float = flower_radius() * 1.25
    for layer in range(4):
        var spread: float = beam_radius * (2.6 - float(layer) * 0.46)
        var transparency: float = 0.037 + float(layer) * 0.016
        var area: PackedVector2Array = PackedVector2Array([
            sun + Vector2(-9.0, -2.0), sun + Vector2(9.0, 2.0),
            target + Vector2(spread, 10.0), target - Vector2(spread, -10.0)
        ])
        draw_colored_polygon(area, Color(1.0, 0.89, 0.48, transparency))
    draw_circle(target, beam_radius * 1.4, Color(1.0, 0.92, 0.42, 0.12))
    draw_arc(target, beam_radius, 0, TAU, 44, Color(1.0, 0.95, 0.65, 0.45), 2.0, true)
    var sun_art: Texture2D = _assets.get("sun") as Texture2D
    var sr: float = clampf(size.y * 0.09, 17.0, 52.0)
    if sun_art != null:
        draw_texture_rect(sun_art, Rect2(sun - Vector2.ONE * sr, Vector2.ONE * sr * 2.0), false)
    else:
        for spoke in range(12):
            var angle: float = TAU * float(spoke) / 12.0 + _time * 0.075
            var axis: Vector2 = Vector2(cos(angle), sin(angle))
            draw_line(sun + axis * sr * 0.95, sun + axis * sr * 1.27, Color("#ffdea0"), maxf(1.0, sr * 0.06), true)
        draw_circle(sun, sr * 1.08, Color(1.0, 0.8, 0.34, 0.13))
        draw_circle(sun, sr * 0.86, Color("#ffd16c"))
        draw_circle(sun, sr * 0.63, Color("#fff6bd"))

func _draw_soil_and_roots() -> void:
    var soil_y: float = size.y * 0.67
    var soil_tex: Texture2D = _assets.get("soil") as Texture2D
    if soil_tex != null:
        draw_texture_rect(soil_tex, Rect2(0.0, soil_y, size.x, size.y - soil_y), false)
    else:
        draw_rect(Rect2(0.0, soil_y, size.x, size.y - soil_y), Color("#153d37"))
        draw_line(Vector2(0.0, soil_y), Vector2(size.x, soil_y), Color("#5ea985"), 3.0, true)
        for mound in range(17):
            var x: float = size.x * float(mound) / 16.0
            draw_circle(Vector2(x, soil_y + size.y * 0.025), size.y * (0.029 + 0.006 * float(mound % 4)), Color("#1d4b3e"))
        for grain in range(34):
            var g: Vector2 = Vector2(fposmod(float(grain * 91), size.x), soil_y + size.y * (0.08 + 0.018 * float(grain % 9)))
            draw_circle(g, 1.7, Color(0.3, 0.9, 0.69, 0.13))
    var roots_art: Texture2D = _assets.get("roots") as Texture2D
    if roots_art != null:
        draw_texture_rect(roots_art, Rect2(0.0, soil_y, size.x, size.y - soil_y), false)
    else:
        for bud in range(FLOWER_COUNT):
            var route: PackedVector2Array = _energy_route(bud)
            draw_polyline(route, Color("#134c44"), 11.0, true)
            draw_polyline(route, Color(0.21, 0.77, 0.63, 0.74), 5.0, true)
            draw_polyline(route, Color(0.59, 1.0, 0.75, 0.55), 1.8, true)
    # Stems are distinct from the root artwork, keeping bud positions editable.
    for bud in range(FLOWER_COUNT):
        var a: Vector2 = flower_center(bud)
        var ground: Vector2 = Vector2(a.x, soil_y + 8.0)
        draw_line(a + Vector2(0.0, flower_radius() * 0.7), ground, Color("#143e3d"), 12.0, true)
        draw_line(a + Vector2(0.0, flower_radius() * 0.7), ground, Color("#57bd91"), 6.0, true)
        draw_line(a + Vector2(0.0, flower_radius() * 0.7), ground, Color("#b5ffd0"), 1.6, true)

func _energy_route(index: int) -> PackedVector2Array:
    var start: Vector2 = Vector2(size.x * flower_uv(index), size.y * 0.68)
    var end: Vector2 = Vector2(size.x * 0.5, size.y * 0.90)
    var intermediate: Vector2 = Vector2(lerpf(start.x, end.x, 0.57), size.y * 0.805)
    return PackedVector2Array([start, Vector2(start.x, size.y * 0.737), intermediate, end])

func _draw_flowers() -> void:
    var radius: float = flower_radius()
    var closed_art: Texture2D = _assets.get("bud_closed") as Texture2D
    var opened_art: Texture2D = _assets.get("bud_open") as Texture2D
    for index in range(FLOWER_COUNT):
        var p: Vector2 = flower_center(index)
        var openness: float = clampf(opening[index], 0.0, 1.0)
        var is_lit: bool = absf(beam_position - flower_uv(index)) < 0.045
        var glow_color: Color = Color("#ffe593") if is_lit else Color("#5de5bf")
        draw_circle(p, radius * 1.28, Color(glow_color.r, glow_color.g, glow_color.b, 0.11 + 0.13 * openness))
        draw_arc(p, radius * 1.11, 0.0, TAU, 36, Color(glow_color.r, glow_color.g, glow_color.b, 0.32 + 0.31 * openness), 2.0, true)
        if closed_art != null and opened_art != null:
            var art_box: Rect2 = Rect2(p - Vector2.ONE * radius * 1.04, Vector2.ONE * radius * 2.08)
            draw_texture_rect(closed_art, art_box, false, Color(1.0, 1.0, 1.0, 1.0 - openness))
            draw_texture_rect(opened_art, art_box, false, Color(1.0, 1.0, 1.0, openness))
        elif openness >= 0.35:
            _draw_open_bud(p, radius, openness)
        else:
            _draw_closed_bud(p, radius)

func _draw_closed_bud(center: Vector2, radius: float) -> void:
    var points: PackedVector2Array = PackedVector2Array([
        center + Vector2(0, -radius), center + Vector2(radius * 0.62, -radius * 0.45),
        center + Vector2(radius * 0.48, radius * 0.35), center + Vector2(0, radius * 0.92),
        center + Vector2(-radius * 0.48, radius * 0.35), center + Vector2(-radius * 0.62, -radius * 0.45)
    ])
    draw_colored_polygon(points, Color("#3a8d72"))
    draw_polyline(PackedVector2Array([center + Vector2(0, radius * 0.6), center, center + Vector2(0, -radius * 0.7)]), Color("#a1f5a8"), 2.0, true)
    draw_circle(center + Vector2(-radius * 0.13, -radius * 0.23), radius * 0.08, Color("#c8ffd8"))

func _draw_open_bud(center: Vector2, radius: float, openness: float) -> void:
    var petal_size: float = radius * (0.48 + openness * 0.22)
    for n in range(6):
        var angle: float = TAU * float(n) / 6.0 + PI / 6.0
        var axis: Vector2 = Vector2(cos(angle), sin(angle))
        var sideways: Vector2 = Vector2(-axis.y, axis.x)
        var base: Vector2 = center + axis * radius * 0.18
        var tip: Vector2 = center + axis * radius * (0.75 + 0.3 * openness)
        var polygon: PackedVector2Array = PackedVector2Array([
            base - sideways * petal_size * 0.6, tip,
            base + sideways * petal_size * 0.6, center
        ])
        draw_colored_polygon(polygon, Color("#70db91") if n % 2 == 0 else Color("#a4f3b3"))
        draw_line(center, tip, Color(0.9, 1.0, 0.66, 0.62), 1.8, true)
    draw_circle(center, radius * 0.30, Color("#ffd985"))
    draw_circle(center, radius * 0.14, Color("#fff5be"))

func _draw_battery() -> void:
    var center: Vector2 = Vector2(size.x * 0.5, size.y * 0.894)
    var width: float = clampf(size.x * 0.39, 160.0, 590.0)
    var height: float = clampf(size.y * 0.115, 20.0, 77.0)
    var frame: Rect2 = Rect2(center - Vector2(width * 0.5, height * 0.5), Vector2(width, height))
    var bat_art: Texture2D = _assets.get("battery") as Texture2D
    if bat_art != null:
        draw_texture_rect(bat_art, frame.grow(height * 0.19), false)
    else:
        draw_rect(frame.grow(5.0), Color("#153b46"))
        draw_rect(frame, Color("#081f2d"))
        draw_rect(frame, CYAN, false, 2.5)
        draw_rect(Rect2(frame.end.x + 5.0, center.y - height * 0.18, 8.0, height * 0.36), Color("#77dbc9"))
    var padding: float = maxf(3.0, height * 0.14)
    var inner: Rect2 = frame.grow(-padding)
    var segments: int = 15
    var spacing: float = clampf(width * 0.008, 2.0, 6.0)
    var segment_w: float = (inner.size.x - spacing * float(segments - 1)) / float(segments)
    for i in range(segments):
        var left: float = inner.position.x + float(i) * (segment_w + spacing)
        var fill_fraction: float = clampf((energy / ENERGY_CAPACITY) * float(segments) - float(i), 0.0, 1.0)
        var slot: Rect2 = Rect2(left, inner.position.y, segment_w, inner.size.y)
        draw_rect(slot, Color("#1d4544"))
        if fill_fraction > 0.0:
            draw_rect(Rect2(left, inner.position.y + 1.0, segment_w * fill_fraction, inner.size.y - 2.0), Color("#b4ff8a"))
    if energy >= 49.99:
        draw_rect(frame.grow(9.0), Color(0.67, 1.0, 0.7, 0.2 + 0.12 * sin(_time * 8.0)), false, 5.0)

func _draw_energy_pulses() -> void:
    for element in _pulses:
        var pulse: Dictionary = element
        var index: int = int(pulse["index"])
        var fraction: float = clampf(float(pulse["age"]) / 1.15, 0.0, 1.0)
        var points: PackedVector2Array = _energy_route(index)
        var seg: float = fraction * float(points.size() - 1)
        var a: int = mini(int(floor(seg)), points.size() - 2)
        var position: Vector2 = points[a].lerp(points[a+1], seg - float(a))
        draw_circle(position, 11.0, Color(0.81, 1.0, 0.68, 0.16 * (1.0 - fraction)))
        draw_circle(position, 4.6, Color(0.95, 1.0, 0.74, 0.95 * (1.0 - fraction)))
