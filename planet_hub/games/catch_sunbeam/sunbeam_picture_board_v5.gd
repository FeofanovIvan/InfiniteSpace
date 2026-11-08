extends Control
## MIKA Catch a Sunbeam v5 / photo-composited living technology.
## The supplied photo sky/soil fills the stage. The six rooted plants, the
## unchanged stems and the original eight-cell organic battery are a second
## layer. Only isolated transparent flower HEADS change during opening.
## Nothing in this drawing goes outside the game board.

signal bud_pressed(index: int)

const FLOWER_COUNT: int = 6
const ENERGY_CAPACITY: float = 50.0
const ART_DIR: String = "res://planet_hub/games/catch_sunbeam/art_v5/"
const REFERENCE_SIZE: Vector2 = Vector2(1672.0, 941.0)
const SHIFT_Y: float = 137.0
const HEAD_BOTTOM: float = SHIFT_Y + 315.0
const CENTERS: Array[float] = [165.0, 431.0, 696.0, 961.0, 1226.0, 1492.0]
const LIQUID_SLOTS: Array[Vector2] = [
    Vector2(503.0, 572.0), Vector2(587.0, 657.0),
    Vector2(672.0, 744.0), Vector2(759.0, 831.0),
    Vector2(846.0, 916.0), Vector2(930.0, 1001.0),
    Vector2(1016.0, 1086.0), Vector2(1102.0, 1172.0)
]

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
    clip_contents = true
    for key in ["landscape", "organism_body", "bud_open", "bud_closed_1", "bud_closed_2", "bud_closed_3", "bud_closed_4", "bud_closed_5", "bud_closed_6"]:
        var suffix: String = ".jpg" if key == "landscape" else ".png"
        var file_name: String = ART_DIR + key + suffix
        if ResourceLoader.exists(file_name):
            _assets[key] = load(file_name) as Texture2D
        else:
            _assets[key] = null
    queue_redraw()

func art_ready() -> bool:
    if _assets.size() != 9:
        return false
    for tex in _assets.values():
        if tex == null:
            return false
    return true

func flower_uv(index: int) -> float:
    return CENTERS[index] / REFERENCE_SIZE.x

func _ref(x: float, y: float) -> Vector2:
    return Vector2(size.x * x / REFERENCE_SIZE.x, size.y * y / REFERENCE_SIZE.y)

func _petal_scale() -> float:
    # Heads retain their image aspect ratio, even when sky/soil are stretched.
    # Limit width for very narrow landscape screens so adjacent buds do not overlap.
    return minf(size.y / REFERENCE_SIZE.y, size.x / REFERENCE_SIZE.x * 1.10)

func flower_center(index: int) -> Vector2:
    return _ref(CENTERS[index], SHIFT_Y + 198.0)

func flower_radius() -> float:
    return maxf(22.0, 105.0 * _petal_scale())

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
    for item in _pulses:
        var pulse: Dictionary = item
        pulse["age"] = float(pulse["age"]) + delta
        if float(pulse["age"]) < 0.95:
            remaining.append(pulse)
    _pulses = remaining
    if not _pulses.is_empty() or energy > 0.0:
        queue_redraw()

func _gui_input(event: InputEvent) -> void:
    var pos: Vector2 = Vector2.ZERO
    var touched: bool = false
    if event is InputEventMouseButton:
        var mouse: InputEventMouseButton = event as InputEventMouseButton
        if mouse.button_index == MOUSE_BUTTON_LEFT and mouse.pressed:
            pos = mouse.position
            touched = true
    elif event is InputEventScreenTouch:
        var touch: InputEventScreenTouch = event as InputEventScreenTouch
        if touch.pressed:
            pos = touch.position
            touched = true
    if not touched:
        return
    var hit_width: float = maxf(25.0, 120.0 * _petal_scale())
    var hit_height: float = maxf(32.0, 130.0 * _petal_scale())
    for index in range(FLOWER_COUNT):
        var center: Vector2 = flower_center(index)
        var dx: float = (pos.x - center.x) / hit_width
        var dy: float = (pos.y - center.y) / hit_height
        if dx * dx + dy * dy <= 1.0:
            bud_pressed.emit(index)
            accept_event()
            return

func _draw() -> void:
    if size.x < 100.0 or size.y < 80.0:
        return
    # Background is the ONLY scalable photograph; it fills the entire board.
    var background: Texture2D = _assets.get("landscape") as Texture2D
    if background != null:
        draw_texture_rect(background, Rect2(Vector2.ZERO, size), false)
    else:
        draw_rect(Rect2(Vector2.ZERO, size), Color("#1d6583"))
    # Darken the sky AND soil modestly, but let the randomized beam bring light.
    draw_rect(Rect2(Vector2.ZERO, size), Color(0.015, 0.035, 0.10, 0.23))
    _draw_vertical_sunlight()
    # The dynamic liquid is drawn BEHIND the transparent holes in the supplied
    # battery art. The original frame overlays and masks the fluid's edges.
    _draw_liquid_in_original_battery()
    var body: Texture2D = _assets.get("organism_body") as Texture2D
    if body != null:
        draw_texture_rect(body, Rect2(Vector2.ZERO, size), false)
    _draw_isolated_bud_heads()
    _draw_sunlit_petal_glow()
    _draw_energy_pulses()

func _draw_vertical_sunlight() -> void:
    if sunlit_target < 0 or sunlit_target >= FLOWER_COUNT or light_level <= 0.005:
        return
    var target: Vector2 = flower_center(sunlit_target)
    var x: float = target.x
    var bottom: float = target.y + 45.0 * _petal_scale()
    var w: float = maxf(18.0, 117.0 * _petal_scale())
    # No clouds, sun disc or moving spotlight; a randomized vertical shaft
    # arrives straight from the top edge of the image.
    for layer in range(7, -1, -1):
        var k: float = float(layer) / 7.0
        var upper_width: float = w * (0.10 + k * 0.24)
        var lower_width: float = w * (0.57 + k * 0.73)
        var poly: PackedVector2Array = PackedVector2Array([
            Vector2(x - upper_width, 0.0), Vector2(x + upper_width, 0.0),
            Vector2(x + lower_width, bottom), Vector2(x - lower_width, bottom)
        ])
        draw_colored_polygon(poly, Color(1.0, 0.94, 0.64, (0.08 - 0.003 * k) * light_level))
    draw_line(Vector2(x, 0.0), Vector2(x, target.y), Color(1.0, 0.97, 0.75, 0.30 * light_level), maxf(1.0, 2.3 * _petal_scale()), true)
    for n in range(4):
        var radius: float = w * (1.03 + float(n) * 0.33)
        draw_circle(target, radius, Color(1.0, 0.92, 0.63, (0.095 - 0.014 * float(n)) * light_level))

func _draw_liquid_in_original_battery() -> void:
    var sections: float = energy / ENERGY_CAPACITY * 8.0
    for index in range(8):
        var amount: float = clampf(sections - float(index), 0.0, 1.0)
        if amount <= 0.001:
            continue
        var x0: float = LIQUID_SLOTS[index].x + 3.0
        var x1: float = LIQUID_SLOTS[index].y - 3.0
        var top: float = 651.0 + SHIFT_Y
        var bottom: float = 720.0 + SHIFT_Y
        var level: float = lerpf(bottom, top, amount)
        var wave: float = 1.8 * sin(_time * 3.3 + float(index) * 0.4)
        # Eight independent pools: liquid rises vertically, one transparent
        # compartment at a time, with a slight moving meniscus.
        var path: PackedVector2Array = PackedVector2Array([
            _ref(x0, level + wave),
            _ref(x0 + (x1 - x0) * 0.25, level - wave),
            _ref((x0 + x1) * 0.5, level + wave * 0.6),
            _ref(x0 + (x1 - x0) * 0.75, level - wave * 0.6),
            _ref(x1, level + wave),
            _ref(x1, bottom), _ref(x0, bottom)
        ])
        draw_colored_polygon(path, Color(0.57, 0.85, 1.0, 0.80))
        draw_polyline(PackedVector2Array([path[0], path[1], path[2], path[3], path[4]]), Color(0.88, 1.0, 0.95, 0.94), maxf(1.0, size.y / 600.0), true)
        var lip: float = maxf(0.5, size.y / 1000.0)
        for bubble in range(3):
            var bx: float = lerpf(x0 + 7.0, x1 - 7.0, float(bubble + 1) / 4.0)
            var rise: float = fposmod(_time * (11.0 + float(bubble) * 5.0) + float(index * 7 + bubble * 17), bottom - level + 2.0)
            var by: float = bottom - rise
            if by > level + 5.0:
                draw_circle(_ref(bx, by), lip * (1.4 + 0.4 * float(bubble)), Color(0.95, 1.0, 1.0, 0.67))

func _draw_isolated_bud_heads() -> void:
    var sc: float = _petal_scale()
    for index in range(FLOWER_COUNT):
        var closed: Texture2D = _assets.get("bud_closed_%d" % (index + 1)) as Texture2D
        var opened: Texture2D = _assets.get("bud_open") as Texture2D
        var center_x: float = size.x * flower_uv(index)
        var bottom: float = size.y * HEAD_BOTTOM / REFERENCE_SIZE.y
        var openness: float = clampf(opening[index], 0.0, 1.0)
        if closed != null:
            var w: float = 216.0 * sc
            var h: float = 224.0 * sc
            var target: Rect2 = Rect2(center_x - w * 0.5, bottom - h, w, h)
            draw_texture_rect(closed, target, false, Color(1.0, 1.0, 1.0, 1.0 - openness))
        if opened != null and openness > 0.002:
            var open_w: float = 238.0 * sc
            var open_h: float = 216.0 * sc
            var open_target: Rect2 = Rect2(center_x - open_w * 0.5, bottom - open_h, open_w, open_h)
            draw_texture_rect(opened, open_target, false, Color(1.0, 1.0, 1.0, openness))

func _draw_sunlit_petal_glow() -> void:
    if sunlit_target < 0 or light_level <= 0.01:
        return
    var p: Vector2 = flower_center(sunlit_target)
    var sc: float = _petal_scale()
    var bright: float = light_level * (0.14 + opening[sunlit_target] * 0.08)
    draw_circle(p + Vector2(0.0, -15.0 * sc), maxf(18.0, 59.0 * sc), Color(1.0, 0.94, 0.67, bright))

func _pulse_path(index: int) -> PackedVector2Array:
    # Centerline samples are aligned with the six supplied root tubes.
    var x: float = CENTERS[index]
    var join_x: float = 834.0
    return PackedVector2Array([
        _ref(x, 420.0 + SHIFT_Y),
        _ref(x, 480.0 + SHIFT_Y),
        _ref(lerpf(x, join_x, 0.22), 549.0 + SHIFT_Y),
        _ref(lerpf(x, join_x, 0.60), 582.0 + SHIFT_Y),
        _ref(lerpf(x, join_x, 0.89), 611.0 + SHIFT_Y),
        _ref(lerpf(x, join_x, 0.97), 640.0 + SHIFT_Y)
    ])

func _draw_energy_pulses() -> void:
    for entry in _pulses:
        var index: int = int(entry["index"])
        var t: float = clampf(float(entry["age"]) / 0.95, 0.0, 1.0)
        var route: PackedVector2Array = _pulse_path(index)
        var segment: float = t * float(route.size() - 1)
        var lower: int = mini(int(floor(segment)), route.size() - 2)
        var at: Vector2 = route[lower].lerp(route[lower + 1], segment - float(lower))
        var sc: float = _petal_scale()
        draw_circle(at, maxf(3.0, 13.0 * sc), Color(1.0, 0.98, 0.80, 0.13 * (1.0 - t)))
        draw_circle(at, maxf(2.0, 4.8 * sc), Color(1.0, 0.99, 0.69, 0.94 * (1.0 - t)))
