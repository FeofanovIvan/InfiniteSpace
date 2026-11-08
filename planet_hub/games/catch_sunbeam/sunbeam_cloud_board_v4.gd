extends Control
## Reusable, picture-ready board for MIKA Catch a Sunbeam / Cloudburst v4.
## Layers (optional SVG/PNG/WebP): background, clouds, soil, roots,
## bud_closed, bud_open, light_beam, battery.
## All art is local to this game; gameplay code never depends on the art assets.

signal bud_pressed(index: int)

const FLOWER_COUNT: int = 6
const ENERGY_CAPACITY: float = 50.0
const ART_DIR: String = "res://planet_hub/games/catch_sunbeam/art/"
const SKY: Color = Color("#10283b")
const CYAN: Color = Color("#72e8ff")

var opening: Array[float] = [0.0, 0.0, 0.0, 0.0, 0.0, 0.0]
var sunlit_target: int = -1
var light_level: float = 0.0
var energy: float = 0.0
var _assets: Dictionary = {}
var _pulses: Array[Dictionary] = []
var _time: float = 0.0

func _ready() -> void:
    mouse_filter = Control.MOUSE_FILTER_STOP
    process_mode = Node.PROCESS_MODE_ALWAYS
    for key in ["background", "clouds", "soil", "roots", "bud_closed", "bud_open", "light_beam", "battery"]:
        _assets[key] = _load_optional_art(key)
    queue_redraw()

func _load_optional_art(key: String) -> Texture2D:
    for extension in ["svg", "png", "webp"]:
        var path: String = ART_DIR + key + "." + extension
        if ResourceLoader.exists(path):
            var texture: Texture2D = load(path) as Texture2D
            if texture != null:
                return texture
    return null

func flower_uv(index: int) -> float:
    return 0.11 + 0.156 * float(index)

func flower_center(index: int) -> Vector2:
    return Vector2(size.x * flower_uv(index), size.y * 0.435)

func flower_radius() -> float:
    return clampf(minf(size.x / 13.5, size.y * 0.15), 16.0, 57.0)

func set_visual_state(bud_opening: Array[float], target_index: int, brightness: float, charge: float) -> void:
    opening = bud_opening.duplicate()
    sunlit_target = target_index
    light_level = clampf(brightness, 0.0, 1.0)
    energy = clampf(charge, 0.0, ENERGY_CAPACITY)
    queue_redraw()

func pulse_from(index: int) -> void:
    if index >= 0 and index < FLOWER_COUNT:
        _pulses.append({"index": index, "age": 0.0})
        queue_redraw()

func reset_fx() -> void:
    _pulses.clear()
    _time = 0.0
    queue_redraw()

func _process(delta: float) -> void:
    _time += delta
    var remaining: Array[Dictionary] = []
    for element in _pulses:
        var pulse: Dictionary = element
        pulse["age"] = float(pulse["age"]) + delta
        if float(pulse["age"]) < 1.1:
            remaining.append(pulse)
    _pulses = remaining
    if not _pulses.is_empty():
        queue_redraw()

func _gui_input(event: InputEvent) -> void:
    var p: Vector2 = Vector2.ZERO
    var tapped: bool = false
    if event is InputEventMouseButton:
        var mouse: InputEventMouseButton = event as InputEventMouseButton
        if mouse.button_index == MOUSE_BUTTON_LEFT and mouse.pressed:
            tapped = true
            p = mouse.position
    elif event is InputEventScreenTouch:
        var touch: InputEventScreenTouch = event as InputEventScreenTouch
        if touch.pressed:
            tapped = true
            p = touch.position
    if not tapped:
        return
    var radius: float = minf(maxf(flower_radius() * 1.32, 30.0), size.x * 0.073)
    for i in range(FLOWER_COUNT):
        if p.distance_to(flower_center(i)) <= radius:
            bud_pressed.emit(i)
            accept_event()
            return

func _draw() -> void:
    if size.x < 100.0 or size.y < 80.0:
        return
    _draw_sky()
    _draw_vertical_light()
    _draw_clouds()
    _draw_soil_and_roots()
    _draw_flowers()
    _draw_battery()
    _draw_energy_pulses()

func _draw_sky() -> void:
    draw_rect(Rect2(Vector2.ZERO, size), SKY)
    var picture: Texture2D = _assets.get("background") as Texture2D
    if picture != null:
        draw_texture_rect(picture, Rect2(Vector2.ZERO, size), false)
    else:
        # Faint sky: sun intentionally invisible behind clouds, no solar orb.
        for i in range(11):
            var y: float = size.y * float(i) * 0.055
            draw_rect(Rect2(0.0, y, size.x, size.y * 0.06), Color(0.10, 0.36, 0.43, 0.025 + float(i) * 0.002))
        for i in range(38):
            var x: float = fposmod(float(i * 193 + 17), size.x)
            var y: float = fposmod(float(i * 71 + 11), size.y * 0.56)
            draw_circle(Vector2(x, y), 0.9, Color(0.76, 0.97, 0.93, 0.12))
        var glow: Vector2 = Vector2(size.x * 0.48, size.y * 0.075)
        for ring in range(5, 0, -1):
            draw_circle(glow, size.y * (0.07 + float(ring) * 0.075), Color(1.0, 0.9, 0.5, 0.008))

func _draw_vertical_light() -> void:
    if sunlit_target < 0 or sunlit_target >= FLOWER_COUNT or light_level <= 0.001:
        return
    var flower: Vector2 = flower_center(sunlit_target)
    var source: Vector2 = Vector2(flower.x, size.y * 0.17)
    var radius: float = flower_radius()
    var art: Texture2D = _assets.get("light_beam") as Texture2D
    if art != null:
        var beam_rect: Rect2 = Rect2(source.x - radius * 1.5, source.y, radius * 3.0, flower.y - source.y + radius * 0.62)
        draw_texture_rect(art, beam_rect, false, Color(1.0, 1.0, 1.0, light_level))
    else:
        for layer in range(5):
            var upper_width: float = radius * (0.13 + float(layer) * 0.095)
            var lower_width: float = radius * (0.52 + float(layer) * 0.32)
            var light_poly: PackedVector2Array = PackedVector2Array([
                source + Vector2(-upper_width, 0.0),
                source + Vector2(upper_width, 0.0),
                flower + Vector2(lower_width, radius * 0.2),
                flower + Vector2(-lower_width, radius * 0.2)
            ])
            draw_colored_polygon(light_poly, Color(1.0, 0.93, 0.58, (0.072 - 0.009 * float(layer)) * light_level))
        draw_line(source, flower, Color(1.0, 0.95, 0.74, 0.30 * light_level), 2.1, true)
    draw_circle(flower, radius * 1.58, Color(1.0, 0.88, 0.42, 0.13 * light_level))
    draw_arc(flower, radius * 1.15, 0.0, TAU, 48, Color(1.0, 0.95, 0.63, 0.75 * light_level), 2.7, true)

func _draw_clouds() -> void:
    var art: Texture2D = _assets.get("clouds") as Texture2D
    if art != null:
        draw_texture_rect(art, Rect2(0.0, 0.0, size.x, size.y * 0.29), false)
        return
    # Sun stays *behind* this cloud bank. Light begins underneath it.
    var cloud_color: Color = Color("#536e7c")
    var highlight: Color = Color("#8599a2")
    draw_rect(Rect2(0.0, 0.0, size.x, size.y * 0.12), Color("#3c5365"))
    for i in range(12):
        var x: float = (float(i) - 0.2) * size.x / 11.0
        var y: float = size.y * (0.085 + 0.028 * sin(float(i) * 1.6))
        var radius: float = size.y * (0.085 + float(i % 3) * 0.018)
        draw_circle(Vector2(x, y), radius, cloud_color)
        draw_circle(Vector2(x - radius * 0.22, y - radius * 0.35), radius * 0.62, highlight)
        draw_circle(Vector2(x + radius * 0.22, y + radius * 0.37), radius * 0.79, cloud_color)
    for i in range(9):
        var x: float = float(i) * size.x / 8.0
        draw_circle(Vector2(x, size.y * 0.17), size.y * 0.055, Color(0.73, 0.86, 0.88, 0.09))

func _draw_soil_and_roots() -> void:
    var soil_y: float = size.y * 0.68
    var soil: Texture2D = _assets.get("soil") as Texture2D
    if soil != null:
        draw_texture_rect(soil, Rect2(0.0, soil_y, size.x, size.y - soil_y), false)
    else:
        draw_rect(Rect2(0.0, soil_y, size.x, size.y - soil_y), Color("#193e38"))
        draw_line(Vector2(0.0, soil_y), Vector2(size.x, soil_y), Color("#6ab395"), 3.5, true)
        for i in range(17):
            var x: float = float(i) * size.x / 16.0
            draw_circle(Vector2(x, soil_y + size.y * 0.027), size.y * (0.029 + float(i % 3) * 0.006), Color("#24584a"))
        for grain in range(55):
            var p: Vector2 = Vector2(fposmod(float(grain * 107 + 11), size.x), soil_y + size.y * (0.06 + 0.013 * float(grain % 14)))
            draw_circle(p, 1.5, Color(0.39, 0.86, 0.64, 0.17))
    var roots: Texture2D = _assets.get("roots") as Texture2D
    if roots != null:
        draw_texture_rect(roots, Rect2(0.0, soil_y, size.x, size.y - soil_y), false)
    else:
        for i in range(FLOWER_COUNT):
            var route: PackedVector2Array = _energy_route(i)
            draw_polyline(route, Color("#113c37"), 10.5, true)
            draw_polyline(route, Color("#56bf9f"), 4.4, true)
            draw_polyline(route, Color(0.63, 0.98, 0.75, 0.47), 1.5, true)
    for i in range(FLOWER_COUNT):
        var center: Vector2 = flower_center(i)
        var base: Vector2 = Vector2(center.x, soil_y + 8.0)
        var start: Vector2 = center + Vector2(0.0, flower_radius() * 0.70)
        draw_line(start, base, Color("#123f36"), 11.0, true)
        draw_line(start, base, Color("#54bc8b"), 5.8, true)
        draw_line(start, base, Color("#b1f9bf"), 1.5, true)

func _energy_route(index: int) -> PackedVector2Array:
    var start: Vector2 = Vector2(size.x * flower_uv(index), size.y * 0.688)
    var center: Vector2 = Vector2(size.x * 0.50, size.y * 0.895)
    var midpoint: Vector2 = Vector2(lerpf(start.x, center.x, 0.58), size.y * 0.802)
    return PackedVector2Array([start, Vector2(start.x, size.y * 0.74), midpoint, center])

func _draw_flowers() -> void:
    var radius: float = flower_radius()
    var closed_art: Texture2D = _assets.get("bud_closed") as Texture2D
    var opened_art: Texture2D = _assets.get("bud_open") as Texture2D
    for i in range(FLOWER_COUNT):
        var center: Vector2 = flower_center(i)
        var openness: float = clampf(opening[i], 0.0, 1.0)
        var lit: bool = sunlit_target == i and light_level > 0.15
        var shade: Color = Color("#ffe9a3") if lit else Color("#69e8bd")
        draw_circle(center, radius * 1.23, Color(shade.r, shade.g, shade.b, (0.15 if lit else 0.065) + openness * 0.09))
        if closed_art != null and opened_art != null:
            var tex_rect: Rect2 = Rect2(center - Vector2.ONE * radius, Vector2.ONE * radius * 2.0)
            draw_texture_rect(closed_art, tex_rect, false, Color(1.0, 1.0, 1.0, 1.0 - openness))
            draw_texture_rect(opened_art, tex_rect, false, Color(1.0, 1.0, 1.0, openness))
        else:
            _draw_two_petal_bud(center, radius, openness)

func _draw_two_petal_bud(center: Vector2, radius: float, openness: float) -> void:
    # Exactly TWO fleshy petal shells, opening sideways like fungal solar collectors.
    var swing: float = openness * radius * 0.62
    for direction in [-1.0, 1.0]:
        var tip: Vector2 = center + Vector2(direction * swing, -radius * (0.96 - 0.23 * openness))
        var outer: Vector2 = center + Vector2(direction * radius * (0.48 + openness * 0.20), -radius * 0.16)
        var bottom: Vector2 = center + Vector2(direction * radius * 0.16, radius * 0.82)
        var inner: Vector2 = center + Vector2(direction * radius * (0.05 + openness * 0.11), -radius * 0.45)
        draw_colored_polygon(PackedVector2Array([bottom, outer, tip, inner, center + Vector2(0.0, radius * 0.20)]), Color("#81e8a4") if direction < 0.0 else Color("#55c995"))
        draw_line(bottom, tip, Color("#b9f8a7"), maxf(1.2, radius * 0.042), true)
    if openness > 0.28:
        draw_circle(center + Vector2(0.0, radius * 0.05), radius * 0.14 * openness, Color("#e6ffc5"))

func _draw_battery() -> void:
    var center: Vector2 = Vector2(size.x * 0.50, size.y * 0.892)
    var width: float = clampf(size.x * 0.39, 156.0, 590.0)
    var height: float = clampf(size.y * 0.115, 19.0, 77.0)
    var frame: Rect2 = Rect2(center - Vector2(width * 0.50, height * 0.50), Vector2(width, height))
    var art: Texture2D = _assets.get("battery") as Texture2D
    if art != null:
        draw_texture_rect(art, frame.grow(height * 0.18), false)
    else:
        draw_rect(frame.grow(5.0), Color("#17414a"))
        draw_rect(frame, Color("#0b2833"))
        draw_rect(frame, CYAN, false, 2.5)
    var inner: Rect2 = frame.grow(-maxf(3.0, height * 0.13))
    var sections: int = 8
    var spacing: float = clampf(width * 0.010, 2.0, 7.0)
    var slot_width: float = (inner.size.x - spacing * float(sections - 1)) / float(sections)
    for i in range(sections):
        var x: float = inner.position.x + float(i) * (slot_width + spacing)
        var slot: Rect2 = Rect2(x, inner.position.y, slot_width, inner.size.y)
        var amount: float = clampf((energy / ENERGY_CAPACITY) * float(sections) - float(i), 0.0, 1.0)
        draw_rect(slot, Color("#244947"))
        if amount > 0.0:
            draw_rect(Rect2(x, inner.position.y, amount * slot_width, inner.size.y), Color("#b9fb93"))
    if energy >= 49.99:
        draw_rect(frame.grow(9.0), Color(0.7, 1.0, 0.6, 0.18 + 0.08 * sin(_time * 10.0)), false, 4.0)

func _draw_energy_pulses() -> void:
    for entry in _pulses:
        var index: int = int(entry["index"])
        var t: float = clampf(float(entry["age"]) / 1.1, 0.0, 1.0)
        var route: PackedVector2Array = _energy_route(index)
        var seg: float = t * float(route.size() - 1)
        var a: int = mini(int(floor(seg)), route.size() - 2)
        var pos: Vector2 = route[a].lerp(route[a + 1], seg - float(a))
        draw_circle(pos, 10.0, Color(0.92, 1.0, 0.66, 0.13 * (1.0 - t)))
        draw_circle(pos, 4.2, Color(1.0, 1.0, 0.73, 0.92 * (1.0 - t)))
