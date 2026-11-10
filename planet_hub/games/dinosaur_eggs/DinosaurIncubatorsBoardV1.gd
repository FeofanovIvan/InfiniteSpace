extends Control
## Incubator board. Uses the original DinosaurEggs.gd glossy shell silhouette.
## Six fixed destination colours in a 3x2 grid; 18 movable eggs; 4 slots each.
## No score/level/hint/restart UI. Use drag/drop or tap an egg then a bin.

signal crystals_changed(count: int)

const CAPACITY: int = 4
const INITIAL_COUNT: int = 3
const INCUBATOR_COUNT: int = 6
const PALETTE: Array[Color] = [
    Color("fa6c83"), Color("69baff"), Color("69dfa5"),
    Color("ffdb70"), Color("b699ff"), Color("ffab70")
]
const WORDS: Dictionary = {
    "ru": {"colors":["РОЗОВЫЙ", "ГОЛУБОЙ", "ЗЕЛЁНЫЙ", "ЖЁЛТЫЙ", "ФИОЛЕТОВЫЙ", "ОРАНЖЕВЫЙ"], "info":"Перетащи яйцо или выбери его и нажми на другой инкубатор", "win":"ВСЕ ЯЙЦА НА СВОИХ МЕСТАХ!", "ready":"Инкубаторы готовы к новой партии"},
    "en": {"colors":["PINK", "BLUE", "GREEN", "YELLOW", "PURPLE", "ORANGE"], "info":"Drag an egg, or tap an egg and then another incubator", "win":"ALL EGGS SORTED!", "ready":"Incubators are ready for the next batch"},
    "pt": {"colors":["ROSA", "AZUL", "VERDE", "AMARELO", "ROXO", "LARANJA"], "info":"Arraste um ovo ou toque no ovo e depois em outra incubadora", "win":"TODOS OS OVOS ORGANIZADOS!", "ready":"Incubadoras prontas para a próxima rodada"},
    "es": {"colors":["ROSA", "AZUL", "VERDE", "AMARILLO", "MORADO", "NARANJA"], "info":"Arrastra un huevo o toca el huevo y otra incubadora", "win":"¡TODOS LOS HUEVOS ORDENADOS!", "ready":"Incubadoras listas para otra ronda"},
    "fr": {"colors":["ROSE", "BLEU", "VERT", "JAUNE", "VIOLET", "ORANGE"], "info":"Glisse un œuf ou touche un œuf puis un autre incubateur", "win":"TOUS LES ŒUFS SONT TRIÉS !", "ready":"Les incubateurs sont prêts pour une nouvelle série"},
    "de": {"colors":["ROSA", "BLAU", "GRÜN", "GELB", "LILA", "ORANGE"], "info":"Ziehe ein Ei oder tippe erst aufs Ei und dann auf einen Inkubator", "win":"ALLE EIER SIND SORTIERT!", "ready":"Inkubatoren bereit für die nächste Runde"}
}
const INCUBATOR_IMAGE_PATH: String = "res://planet_hub/games/dinosaur_eggs/assets/incubator_user.png"
const SFX_OK: AudioStream = preload("res://education/playtown/audio/sfx/correct.ogg")

var locale: String = "en"
var _bins: Array = []
var _egg_counter: int = 0
var _held: Dictionary = {}
var _dragging: bool = false
var _pressed: bool = false
var _touch_id: int = -1
var _press_origin: Vector2 = Vector2.ZERO
var _drag_point: Vector2 = Vector2.ZERO
var _hover: int = -1
var _t: float = 0.0
var _won: bool = false
var _win_timer: float = -1.0
var _crystals: int = 0
var _credited: Dictionary = {}
var _sound: AudioStreamPlayer
var _incubator_image: Texture2D = null


func _ready() -> void:
    mouse_filter = Control.MOUSE_FILTER_IGNORE
    _sound = AudioStreamPlayer.new()
    _sound.name = "DinosaurEggsSortSound"
    _sound.volume_db = -8.0
    _sound.bus = "SFX" if AudioServer.get_bus_index("SFX") >= 0 else "Master"
    add_child(_sound)
    if ResourceLoader.exists(INCUBATOR_IMAGE_PATH):
        _incubator_image = load(INCUBATOR_IMAGE_PATH) as Texture2D
    resized.connect(queue_redraw)
    _start_round()


func _start_round() -> void:
    _bins.clear()
    _credited.clear()
    _held.clear()
    _hover = -1
    _pressed = false
    _touch_id = -1
    _dragging = false
    _won = false
    _win_timer = -1.0
    _crystals = 0
    _egg_counter = 0
    var all_eggs: Array = []
    for colour in range(INCUBATOR_COUNT):
        for _n in range(INITIAL_COUNT):
            all_eggs.append({"id": _egg_counter, "color": colour})
            _egg_counter += 1
    # Fixed shell counts, shuffled locations. Avoid any already solved bin.
    var attempts: int = 0
    while attempts < 150:
        attempts += 1
        all_eggs.shuffle()
        var good: bool = true
        var correctly_placed: int = 0
        for rack in range(INCUBATOR_COUNT):
            var rack_done: bool = true
            for slot in range(INITIAL_COUNT):
                if int(all_eggs[rack * INITIAL_COUNT + slot]["color"]) != rack:
                    rack_done = false
                else:
                    correctly_placed += 1
            if rack_done:
                good = false
                break
        if good and correctly_placed <= 7:
            break
    for rack in range(INCUBATOR_COUNT):
        var eggs: Array = []
        for slot in range(INITIAL_COUNT):
            eggs.append(all_eggs[rack * INITIAL_COUNT + slot])
        _bins.append(eggs)
    crystals_changed.emit(0)
    queue_redraw()


func _process(delta: float) -> void:
    _t += delta
    if _win_timer >= 0.0:
        _win_timer -= delta
        if _win_timer < 0.0 and _won:
            _start_round()
            return
    queue_redraw()


func _bin_rect(index: int) -> Rect2:
    # 3 incubators on the top shelf, 3 on the lower shelf.
    # All geometry follows the available viewport, not a fixed 1280x720 canvas.
    var outer_x: float = clampf(size.x * 0.018, 7.0, 26.0)
    var gap_x: float = clampf(size.x * 0.013, 5.0, 22.0)
    var gap_y: float = clampf(size.y * 0.022, 5.0, 18.0)
    var top: float = maxf(13.0, size.y * 0.065)
    var bottom: float = size.y * 0.915
    var width: float = maxf(45.0, (size.x - 2.0 * outer_x - 2.0 * gap_x) / 3.0)
    var height: float = maxf(40.0, (bottom - top - gap_y) / 2.0)
    var column: int = index % 3
    var row: int = index / 3
    return Rect2(outer_x + float(column) * (width + gap_x),
            top + float(row) * (height + gap_y), width, height)


func _egg_scale(index: int) -> float:
    var rack: Rect2 = _bin_rect(index)
    return clampf(minf(rack.size.x / 330.0, rack.size.y / 520.0), 0.09, 1.0)


func _egg_center(index: int, slot: int) -> Vector2:
    var rack: Rect2 = _bin_rect(index)
    var x: float = rack.position.x + rack.size.x * (0.34 if slot % 2 == 0 else 0.66)
    var y: float = rack.position.y + rack.size.y * (0.47 if slot < 2 else 0.80)
    return Vector2(x, y)


func _bin_at(point: Vector2) -> int:
    for index in range(INCUBATOR_COUNT):
        if _bin_rect(index).has_point(point):
            return index
    return -1


func _egg_at(point: Vector2) -> Dictionary:
    # Check the rendered egg positions, never a generic panel touch region.
    for rack in range(INCUBATOR_COUNT):
        var eggs: Array = _bins[rack]
        for slot in range(eggs.size() - 1, -1, -1):
            var center: Vector2 = _egg_center(rack, slot)
            var sc: float = _egg_scale(rack)
            var delta: Vector2 = point - center
            var horizontal: float = delta.x / maxf(6.0, 64.0 * sc)
            var vertical: float = delta.y / maxf(8.0, 94.0 * sc)
            if horizontal * horizontal + vertical * vertical <= 1.1:
                return {"rack": rack, "id": int(eggs[slot]["id"])}
    return {}


func _local_point(screen: Vector2) -> Vector2:
    return get_global_transform_with_canvas().affine_inverse() * screen


func _input(event: InputEvent) -> void:
    if not is_visible_in_tree() or _won:
        return
    if event is InputEventScreenTouch:
        if event.pressed and _touch_id < 0:
            var point: Vector2 = _local_point(event.position)
            if Rect2(Vector2.ZERO, size).has_point(point) and _press_at(point):
                _touch_id = event.index
                get_viewport().set_input_as_handled()
        elif not event.pressed and _touch_id == event.index:
            _release_at(_local_point(event.position))
            _touch_id = -1
            get_viewport().set_input_as_handled()
    elif event is InputEventScreenDrag:
        if _touch_id == event.index and _pressed:
            _move_to(_local_point(event.position))
            get_viewport().set_input_as_handled()
    elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
        var point: Vector2 = _local_point(event.position)
        if event.pressed and Rect2(Vector2.ZERO, size).has_point(point):
            if _press_at(point):
                get_viewport().set_input_as_handled()
        elif not event.pressed and _pressed:
            _release_at(point)
            get_viewport().set_input_as_handled()
    elif event is InputEventMouseMotion and _pressed:
        _move_to(_local_point(event.position))
        get_viewport().set_input_as_handled()


func _press_at(point: Vector2) -> bool:
    var target: int = _bin_at(point)
    if not _held.is_empty() and target >= 0 and target != int(_held["rack"]):
        _move_egg_to(target)
        _pressed = false
        queue_redraw()
        return true
    var found: Dictionary = _egg_at(point)
    if not found.is_empty():
        if _held == found:
            _held.clear()
            _pressed = false
        else:
            _held = found
            _pressed = true
            _press_origin = point
            _drag_point = point
            _dragging = false
        queue_redraw()
        return true
    if target >= 0:
        _held.clear()
        _pressed = false
        queue_redraw()
        return true
    return false


func _move_to(point: Vector2) -> void:
    if not _pressed or _held.is_empty():
        return
    _drag_point = point
    _dragging = _dragging or point.distance_to(_press_origin) > 10.0
    _hover = _bin_at(point)
    queue_redraw()


func _release_at(point: Vector2) -> void:
    if _dragging and not _held.is_empty():
        var rack: int = _bin_at(point)
        if rack >= 0 and rack != int(_held["rack"]):
            _move_egg_to(rack)
    _pressed = false
    _dragging = false
    _hover = -1
    queue_redraw()


func _move_egg_to(destination: int) -> void:
    if _held.is_empty() or destination < 0 or destination >= INCUBATOR_COUNT:
        return
    var origin: int = int(_held["rack"])
    if origin == destination or (_bins[destination] as Array).size() >= CAPACITY:
        return
    var egg_id: int = int(_held["id"])
    var source: Array = _bins[origin]
    var found_slot: int = -1
    for index in range(source.size()):
        if int(source[index]["id"]) == egg_id:
            found_slot = index
            break
    if found_slot < 0:
        _held.clear()
        return
    var egg: Dictionary = source[found_slot]
    source.remove_at(found_slot)
    var dest: Array = _bins[destination]
    dest.append(egg)
    _held.clear()
    _dragging = false
    if int(egg["color"]) == destination:
        _sound.stream = SFX_OK
        _sound.play()
    for rack in range(INCUBATOR_COUNT):
        if _is_finished_rack(rack) and not _credited.has(rack):
            _credited[rack] = true
            _crystals += 1
            crystals_changed.emit(_crystals)
    if _all_sorted():
        _won = true
        _win_timer = 3.0
    queue_redraw()


func _is_finished_rack(index: int) -> bool:
    var eggs: Array = _bins[index]
    if eggs.size() != INITIAL_COUNT:
        return false
    for egg in eggs:
        if int(egg["color"]) != index:
            return false
    return true


func _all_sorted() -> bool:
    for rack in range(INCUBATOR_COUNT):
        if not _is_finished_rack(rack):
            return false
    return true


func _text(value: String, at: Vector2, font_size: int, tint: Color, max_width: float, align: HorizontalAlignment = HORIZONTAL_ALIGNMENT_CENTER) -> void:
    draw_string(ThemeDB.fallback_font, at, value, align, max_width, font_size, tint)


func _panel(rect: Rect2, bg: Color, edge: Color, radius: int = 22, thickness: int = 2) -> void:
    var style: StyleBoxFlat = StyleBoxFlat.new()
    style.bg_color = bg
    style.border_color = edge
    style.set_border_width_all(thickness)
    style.set_corner_radius_all(radius)
    draw_style_box(style, rect)


func _draw() -> void:
    if size.x < 250.0 or size.y < 110.0 or _bins.size() != INCUBATOR_COUNT:
        return
    _draw_lab_background()
    for rack in range(INCUBATOR_COUNT):
        _draw_incubator(rack)
    var data: Dictionary = WORDS.get(locale, WORDS["en"])
    var instruction: String = str(data["win"] if _won else data["info"])
    var font_size: int = maxi(9, mini(17, roundi(size.x / maxf(48.0, float(instruction.length()) * 0.64))))
    _text(instruction, Vector2(size.x * 0.045, size.y * 0.973), font_size, Color("d7f3ff"), size.x * 0.91)
    if _dragging and not _held.is_empty():
        var egg: Dictionary = _lookup_held_egg()
        if not egg.is_empty():
            _draw_egg(_drag_point + Vector2(0, -9), maxf(0.22, _egg_scale(int(_held["rack"])) * 1.10), int(egg["color"]))
    if _won:
        _panel(Rect2(size.x * 0.22, size.y * 0.385, size.x * 0.56, size.y * 0.19), Color(0.04, 0.22, 0.27, 0.95), Color("95ffd8"), 24, 3)
        _text(str(data["win"]), Vector2(size.x * 0.235, size.y * 0.49), maxi(14, mini(28, roundi(size.x * 0.019))), Color("f4fff7"), size.x * 0.53)


func _draw_lab_background() -> void:
    for step in range(22):
        var ratio: float = float(step) / 22.0
        draw_rect(Rect2(0.0, size.y * ratio, size.x, size.y / 20.0), Color("06162e").lerp(Color("16415a"), ratio * 0.72))
    for col in range(27):
        var xx: float = fmod(float(col * 143 + 31), size.x)
        var yy: float = fmod(float(col * 79 + 23), size.y)
        draw_circle(Vector2(xx, yy), 1.2 + float(col % 3), Color(0.38, 0.80, 0.92, 0.16))
    var horizon: float = size.y * 0.88
    draw_line(Vector2(0, horizon), Vector2(size.x, horizon), Color("5de5fe", 0.32), 3.0, true)


func _draw_incubator(index: int) -> void:
    var rack: Rect2 = _bin_rect(index)
    var target: Color = PALETTE[index]
    var eggs: Array = _bins[index]
    var selected: bool = _held.has("rack") and int(_held["rack"]) == index
    var hovering: bool = _dragging and _hover == index and not selected
    var complete: bool = _is_finished_rack(index)
    var border: Color = Color("a1ffdb") if complete else (Color("a1f7ff") if selected or hovering else Color("58b9de"))
    # Four-place glass incubator: use the supplied art when available. The
    # frame is intentionally separate from the egg/hit-test coordinates.
    _panel(rack, Color(0.017, 0.085, 0.145, 0.97), border, 22, 3 if complete or selected or hovering else 2)
    var art: Rect2 = Rect2(rack.position.x + rack.size.x * 0.045,
            rack.position.y + rack.size.y * 0.215,
            rack.size.x * 0.91, rack.size.y * 0.735)
    if _incubator_image != null:
        var src: Vector2 = _incubator_image.get_size()
        var fit: float = minf(art.size.x / maxf(src.x, 1.0), art.size.y / maxf(src.y, 1.0))
        var texture_size: Vector2 = src * fit
        var destination: Rect2 = Rect2(art.get_center() - texture_size * 0.5, texture_size)
        draw_texture_rect(_incubator_image, destination, false, Color.WHITE)
    else:
        # Laboratory prototype fixture until the user's original PNG is saved.
        _panel(art, Color(0.075, 0.17, 0.24, 0.87), Color("60b8d2", 0.71), 18, 3)
        var glass: Rect2 = art.grow(-maxf(4.0, art.size.x * 0.024))
        _panel(glass, Color(0.052, 0.19, 0.28, 0.52), Color("b8ecff", 0.30), 14, 2)
        draw_line(Vector2(glass.position.x + glass.size.x * 0.50, glass.position.y + 7.0),
                Vector2(glass.position.x + glass.size.x * 0.50, glass.end.y - 7.0),
                Color("6dc9df", 0.17), 2.0, true)
        draw_line(Vector2(glass.position.x + 8.0, glass.position.y + glass.size.y * 0.53),
                Vector2(glass.end.x - 8.0, glass.position.y + glass.size.y * 0.53),
                Color("6dc9df", 0.17), 2.0, true)
    # Top light (coloured LED) and the counter. Both belong to this incubator.
    var head: Rect2 = Rect2(rack.position.x + 5.0, rack.position.y + 5.0,
            rack.size.x - 10.0, rack.size.y * 0.202)
    _panel(head, target.darkened(0.74), target.lightened(0.12), 15, 2)
    var lamp_mid: Vector2 = Vector2(rack.get_center().x, head.position.y + maxf(5.0, head.size.y * 0.12))
    draw_line(Vector2(head.position.x + head.size.x * 0.14, lamp_mid.y),
            Vector2(head.end.x - head.size.x * 0.14, lamp_mid.y),
            Color(target.r, target.g, target.b, 0.30), maxf(4.0, head.size.y * 0.25), true)
    draw_line(Vector2(head.position.x + head.size.x * 0.16, lamp_mid.y),
            Vector2(head.end.x - head.size.x * 0.16, lamp_mid.y),
            target.lightened(0.55), maxf(2.0, head.size.y * 0.075), true)
    var lang: Dictionary = WORDS.get(locale, WORDS["en"])
    var names: Array = lang["colors"]
    var name: String = str(names[index])
    var name_px: int = maxi(9, mini(20, roundi((head.size.x - 20.0) / maxf(4.5, float(name.length()) * 0.73))))
    _text(name, Vector2(head.position.x + 8.0, head.position.y + head.size.y * 0.85),
            name_px, Color("f4fcff"), head.size.x - 16.0)
    # The egg count always shows occupied slots / capacity (3/4 initially).
    var fill_px: int = maxi(11, mini(22, roundi(minf(rack.size.x * 0.12, rack.size.y * 0.092))))
    _text("%d / %d" % [eggs.size(), CAPACITY],
            Vector2(rack.position.x + 8.0, rack.position.y + rack.size.y * 0.290),
            fill_px, Color("e4faff"), rack.size.x - 16.0)
    # Four unmistakable landing pads: 2 at the back, 2 at the front.
    # Egg hit testing uses these exact same coordinates.
    for slot in range(CAPACITY):
        var pos: Vector2 = _egg_center(index, slot)
        var scale: float = _egg_scale(index)
        var glow: Color = target if slot < eggs.size() else Color("89c8d9")
        draw_ellipse_shadow(pos + Vector2(0.0, 32.0 * scale), 37.0 * scale, glow)
        if slot >= eggs.size():
            draw_arc(pos, 42.0 * scale, 0.0, TAU, 42, Color("9cddf0", 0.50), 2.0, true)
            draw_circle(pos + Vector2(0.0, 25.0 * scale), 4.0 * scale, Color("b8ecff", 0.36))
    for slot in range(eggs.size()):
        var egg: Dictionary = eggs[slot]
        var point: Vector2 = _egg_center(index, slot)
        var held_here: bool = _held.has("rack") and int(_held["rack"]) == index and int(_held["id"]) == int(egg["id"])
        if held_here:
            draw_arc(point, maxf(14.0, 69.0 * _egg_scale(index)), 0.0, TAU, 32,
                    Color("c9fff1", 0.70 + 0.12 * sin(_t * 5.0)), 2.0, true)
        if held_here and _dragging:
            continue
        _draw_egg(point, _egg_scale(index), int(egg["color"]))
    if complete:
        var check: Vector2 = rack.position + Vector2(rack.size.x - 16.0, rack.size.y - 15.0)
        draw_circle(check, 9.0, Color("8effcc"))
        _text("✓", check + Vector2(-10.0, 6.0), 14, Color("08334a"), 20.0)


func _lookup_held_egg() -> Dictionary:
    var rack: int = int(_held.get("rack", -1))
    if rack < 0 or rack >= _bins.size():
        return {}
    for egg in _bins[rack]:
        if int(egg["id"]) == int(_held["id"]):
            return egg
    return {}


func draw_ellipse_shadow(center: Vector2, radius: float, tone: Color) -> void:
    var pts: PackedVector2Array = PackedVector2Array()
    for i in range(25):
        var angle: float = TAU * float(i) / 24.0
        pts.append(center + Vector2(cos(angle) * radius, sin(angle) * radius * 0.30))
    draw_colored_polygon(pts, Color(tone.r, tone.g, tone.b, 0.17))


func _ellipse(rect: Rect2, fill: Color) -> void:
    var points: PackedVector2Array = PackedVector2Array()
    for i in range(33):
        var theta: float = TAU * float(i) / 32.0
        points.append(rect.get_center() + Vector2(cos(theta) * rect.size.x * 0.5, sin(theta) * rect.size.y * 0.5))
    draw_colored_polygon(points, fill)


func _draw_egg(center: Vector2, sc: float, color_idx: int) -> void:
    # Exact egg silhouette / gloss / shell spots from the old DinosaurEggs game.
    var base: Color = PALETTE[color_idx]
    var edge: PackedVector2Array = PackedVector2Array()
    for j in range(49):
        var a: float = TAU * float(j) / 48.0
        edge.append(center + Vector2(sin(a) * (63.0 - 12.0 * cos(a)), -88.0 * cos(a)) * sc)
    draw_colored_polygon(edge, base.darkened(0.20))
    var inner: PackedVector2Array = PackedVector2Array()
    for j in range(49):
        var a: float = TAU * float(j) / 48.0
        inner.append(center + Vector2(sin(a) * (59.0 - 11.0 * cos(a)), -83.0 * cos(a)) * sc)
    draw_colored_polygon(inner, base)
    draw_polyline(edge, Color("effbff", 0.83), 2.4 * sc, true)
    _ellipse(Rect2(center.x - 37.0 * sc, center.y - 57.0 * sc, 24.0 * sc, 77.0 * sc), Color(1, 1, 1, 0.20))
    draw_circle(center + Vector2(32.0, 26.0) * sc, 7.0 * sc, base.darkened(0.18))
    draw_circle(center + Vector2(-30.0, 31.0) * sc, 4.0 * sc, base.darkened(0.22))
    for k in range(5):
        var spot_x: float = sin(float(k) * 2.12) * 29.0
        var spot_y: float = cos(float(k) * 1.41) * 35.0
        draw_circle(center + Vector2(spot_x, spot_y) * sc, (6.0 + float(k % 3)) * sc, base.darkened(0.21))
