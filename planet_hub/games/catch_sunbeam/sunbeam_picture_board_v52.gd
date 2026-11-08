extends Control
## MIKA Catch a Sunbeam v5.2 / clean vertical sunlight living technology.
## The supplied photo sky/soil fills the stage. The six rooted plants, the
## unchanged stems and the original eight-cell organic battery are a second
## layer. Only isolated transparent flower HEADS change during opening.
## Nothing in this drawing goes outside the game board.

signal bud_pressed(index: int)

const FLOWER_COUNT: int = 6
const ENERGY_CAPACITY: float = 50.0
const ART_DIR: String = "res://planet_hub/games/catch_sunbeam/art_v52/"
const REFERENCE_SIZE: Vector2 = Vector2(1672.0, 941.0)
const SHIFT_Y: float = 137.0
const BUD_TOP: float = 255.0
const BUD_SCALE: float = 0.89
const SOIL_LINE_Y: float = 588.0
const SHAFT_WIDTH: float = 242.0
const CENTERS: Array[float] = [164.0, 438.0, 706.0, 974.0, 1243.0, 1514.0]
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
    for key in ["landscape", "organism_body", "bud_open", "bud_closed", "sunlight_shaft", "sunlight_ground"]:
        var suffix: String = ".jpg" if key == "landscape" else ".png"
        var file_name: String = ART_DIR + key + suffix
        if ResourceLoader.exists(file_name):
            _assets[key] = load(file_name) as Texture2D
        else:
            _assets[key] = null
    queue_redraw()

func art_ready() -> bool:
    if _assets.size() != 6:
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
    # A soft vertical light beam behind the plants; no cloud or triangular rays.
    _draw_vertical_sunlight(0.70)
    # Liquid sits behind the original hollow eight-cell battery frame.
    _draw_liquid_in_original_battery()
    var body: Texture2D = _assets.get("organism_body") as Texture2D
    if body != null:
        # This supplied base is UN-SHIFTED: slide it down to sit its roots in soil.
        var offset_y: float = _ref(0.0, SHIFT_Y).y
        draw_texture_rect(body, Rect2(Vector2(0.0, offset_y), size), false)
    _draw_isolated_bud_heads()
    # Light scatters over petals and reaches the grass, visibly illuminating
    # the underlying plants rather than stopping at the bud silhouette.
    _draw_vertical_sunlight(0.45)
    _draw_soil_highlight()
    _draw_sunlit_petal_glow()
    _draw_energy_pulses()

func beam_ground_y() -> float:
    # Ends at the real supplied green ground line (~588 in 1672x941 art).
    return _ref(0.0, SOIL_LINE_Y).y

func beam_width() -> float:
    # Responsive width but no widening/narrowing along the vertical axis.
    return maxf(58.0, SHAFT_WIDTH * _petal_scale())

func _draw_vertical_sunlight(layer_opacity: float = 1.0) -> void:
    if sunlit_target < 0 or sunlit_target >= FLOWER_COUNT or light_level <= 0.005:
        return
    var shaft: Texture2D = _assets.get("sunlight_shaft") as Texture2D
    if shaft == null:
        return
    var x: float = flower_center(sunlit_target).x
    var width: float = beam_width()
    var ground_y: float = beam_ground_y()
    # A constant-width gradient texture from y=0 all the way down to the soil.
    # No polygons, wedges, squares, cloud icons or abrupt stop at flower height.
    draw_texture_rect(shaft, Rect2(x - width * 0.5, 0.0, width, ground_y), false,
            Color(1.0, 1.0, 1.0, light_level * layer_opacity))

func _draw_soil_highlight() -> void:
    if sunlit_target < 0 or sunlit_target >= FLOWER_COUNT or light_level <= 0.005:
        return
    var ground_glow: Texture2D = _assets.get("sunlight_ground") as Texture2D
    if ground_glow == null:
        return
    var width: float = beam_width() * 1.24
    var height: float = maxf(10.0, 74.0 * _petal_scale())
    var x: float = flower_center(sunlit_target).x
    draw_texture_rect(ground_glow, Rect2(x - width * 0.5, beam_ground_y() - height * 0.5,
            width, height), false, Color(1.0, 1.0, 1.0, light_level * 0.88))

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
    # Both supplied 292x250 PNGs have their stem bottom at source y=230.
    # Identical placement for all six flowers; do not crop them again.
    var sc: float = _petal_scale() * BUD_SCALE
    var width: float = 292.0 * sc
    var height: float = 250.0 * sc
    var top: float = _ref(0.0, BUD_TOP).y
    var closed: Texture2D = _assets.get("bud_closed") as Texture2D
    var opened: Texture2D = _assets.get("bud_open") as Texture2D
    for index in range(FLOWER_COUNT):
        var center_x: float = flower_center(index).x
        var target: Rect2 = Rect2(center_x - width * 0.5, top, width, height)
        var openness: float = clampf(opening[index], 0.0, 1.0)
        if closed != null:
            draw_texture_rect(closed, target, false, Color(1.0, 1.0, 1.0, 1.0 - openness))
        if opened != null and openness > 0.002:
            draw_texture_rect(opened, target, false, Color(1.0, 1.0, 1.0, openness))

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
