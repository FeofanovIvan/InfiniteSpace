extends Control
## MIKA_DINO_V24_VOICE_SFX_NO_MUSIC
## MIKA_DINO_V241_SHORT_INTRO
## Incubator board v2 — original console and shelf art; eggs placed in four photographed bowls.
## Six destination colours in a 3x2 grid; 18 to 23 eggs as difficulty increases; capacity 4.
## No score/level/hint/restart UI. Use drag/drop or tap an egg then a bin.

signal crystals_changed(count: int)

const CAPACITY: int = 4
const INITIAL_COUNT: int = 3
const MAX_EXTRA_EGGS: int = 5
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
const INCUBATOR_IMAGE_PATH: String = "res://planet_hub/games/dinosaur_eggs/assets/incubator_console_cropped_v22.png"
const LAB_WALL_PATH: String = "res://planet_hub/games/dinosaur_eggs/assets/lab_wall_v2.png"
const SHELF_TOP_PATH: String = "res://planet_hub/games/dinosaur_eggs/assets/lab_shelf_upper_v2.png"
const SHELF_LOWER_PATH: String = "res://planet_hub/games/dinosaur_eggs/assets/lab_shelf_lower_v2.png"
const SFX_OK: AudioStream = preload("res://education/playtown/audio/sfx/correct.ogg")
const SFX_PICKUP_V24: AudioStream = preload("res://planet_hub/games/dinosaur_eggs/audio/dino_pickup_v24.ogg")
const SFX_PLACE_V24: AudioStream = preload("res://planet_hub/games/dinosaur_eggs/audio/dino_place_v24.ogg")
const SFX_BLOCKED_V24: AudioStream = preload("res://planet_hub/games/dinosaur_eggs/audio/dino_blocked_v24.ogg")
const SFX_SUCCESS_V24: AudioStream = preload("res://planet_hub/games/dinosaur_eggs/audio/dino_success_v24.ogg")
const VOICE_INTRO: Dictionary = {
    "ru": "Разложи яйца по цветам!",
    "en": "Sort the eggs by color!",
    "pt": "Separe os ovos por cor!",
    "es": "¡Clasifica los huevos por color!",
    "fr": "Trie les œufs par couleur !",
    "de": "Sortiere die Eier nach Farben!"
}

var locale: String = "en"
var _bins: Array = []
var _egg_counter: int = 0
var _completed_rounds: int = 0
var _target_counts: Array[int] = []
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
var _lab_wall: Texture2D = null
var _shelf_top: Texture2D = null
var _shelf_lower: Texture2D = null


func _ready() -> void:
    mouse_filter = Control.MOUSE_FILTER_IGNORE
    _sound = AudioStreamPlayer.new()
    _sound.name = "DinosaurEggsSortSound"
    _sound.volume_db = -8.0
    _sound.bus = "SFX" if AudioServer.get_bus_index("SFX") >= 0 else "Master"
    add_child(_sound)
    if ResourceLoader.exists(INCUBATOR_IMAGE_PATH):
        _incubator_image = load(INCUBATOR_IMAGE_PATH) as Texture2D
    _lab_wall = load(LAB_WALL_PATH) as Texture2D
    _shelf_top = load(SHELF_TOP_PATH) as Texture2D
    _shelf_lower = load(SHELF_LOWER_PATH) as Texture2D
    resized.connect(queue_redraw)
    _start_round()
    call_deferred("_voice_intro")


func _start_round() -> void:
    # A win removes one free place until just one remains (18..23 eggs).
    # Difficulty is session-wide; no extra button or level counter is shown.
    if _won:
        _completed_rounds = mini(_completed_rounds + 1, MAX_EXTRA_EGGS)
    _bins.clear()
    _target_counts.clear()
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
        var wanted: int = INITIAL_COUNT + (1 if colour < _completed_rounds else 0)
        _target_counts.append(wanted)
        for _n in range(wanted):
            all_eggs.append({"id": _egg_counter, "color": colour})
            _egg_counter += 1
    # Preserve exact occupancy (3 or 4 per rack), while each rack starts mixed.
    # Since any egg may be moved and at least one bowl stays empty, every
    # generated position can be solved without needing an extra incubator.
    for _attempt in range(300):
        all_eggs.shuffle()
        var good: bool = true
        var correctly_placed: int = 0
        var attempt_offset: int = 0
        for rack in range(INCUBATOR_COUNT):
            var rack_done: bool = true
            for slot in range(_target_counts[rack]):
                if int(all_eggs[attempt_offset + slot]["color"]) != rack:
                    rack_done = false
                else:
                    correctly_placed += 1
            if rack_done:
                good = false
                break
            attempt_offset += _target_counts[rack]
        if good and correctly_placed <= 7:
            break
    var offset: int = 0
    for rack in range(INCUBATOR_COUNT):
        var eggs: Array = []
        for slot in range(_target_counts[rack]):
            eggs.append(all_eggs[offset + slot])
        offset += _target_counts[rack]
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
    # Minimal visible gaps, 3 x 2, no incubator stretching or distortion.
    # The source image is trimmed to its painted area (1254 x 1051 pixels).
    var x_margin: float = clampf(size.x * 0.004, 2.0, 7.0)
    var y_margin: float = clampf(size.y * 0.005, 2.0, 5.0)
    var gap_x: float = clampf(size.x * 0.004, 3.0, 8.0)
    var gap_y: float = clampf(size.y * 0.008, 3.0, 7.0)
    var image_ratio: float = 1254.0 / 1051.0
    var art_h: float = minf(
            (size.y - 2.0 * y_margin - gap_y) * 0.5,
            (size.x - 2.0 * x_margin - 2.0 * gap_x) / (3.0 * image_ratio))
    art_h = maxf(8.0, art_h)
    var art_w: float = art_h * image_ratio
    var start_x: float = (size.x - (3.0 * art_w + 2.0 * gap_x)) * 0.5
    var start_y: float = (size.y - (2.0 * art_h + gap_y)) * 0.5
    var column: int = index % 3
    var row: int = index / 3
    return Rect2(start_x + float(column) * (art_w + gap_x),
            start_y + float(row) * (art_h + gap_y), art_w, art_h)

func _art_rect(index: int) -> Rect2:
    # One canvas unit per rendered picture, without added inner padding.
    return _bin_rect(index)

func _egg_scale(index: int) -> float:
    var art: Rect2 = _art_rect(index)
    # Fits each complete egg within one of four original bowls.
    return clampf(minf(art.size.x / 700.0, art.size.y / 450.0), 0.12, 0.95)

func _egg_center(index: int, slot: int) -> Vector2:
    # Original x centers: 246/505/755/1011. Shells are centered above
    # the pictured bowl rim, so the front part of each egg stays visible.
    var art: Rect2 = _art_rect(index)
    var fractions: Array[float] = [0.196, 0.403, 0.602, 0.806]
    return Vector2(art.position.x + art.size.x * fractions[clampi(slot, 0, 3)],
            art.position.y + art.size.y * (640.0 / 1051.0))

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
            _play_feedback(SFX_PICKUP_V24)
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
    if origin == destination:
        return
    if (_bins[destination] as Array).size() >= CAPACITY:
        _play_feedback(SFX_BLOCKED_V24)
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
        _play_feedback(SFX_OK)
    else:
        _play_feedback(SFX_PLACE_V24)
    for rack in range(INCUBATOR_COUNT):
        if _is_finished_rack(rack) and not _credited.has(rack):
            _credited[rack] = true
            _crystals += 1
            crystals_changed.emit(_crystals)
    if _all_sorted():
        _won = true
        _win_timer = 3.0
        _play_feedback(SFX_SUCCESS_V24)
    queue_redraw()


func _play_feedback(sound: AudioStream) -> void:
    if _sound == null or sound == null:
        return
    _sound.stop()
    _sound.stream = sound
    _sound.play()


func _voice_intro() -> void:
    if not is_inside_tree() or not DisplayServer.has_feature(DisplayServer.FEATURE_TEXT_TO_SPEECH):
        return
    var voice: String = _preferred_voice()
    if voice.is_empty():
        # If this device has no voice for the chosen language, stay silent.
        return
    var line: String = str(VOICE_INTRO.get(locale, VOICE_INTRO["en"]))
    DisplayServer.tts_speak(line, voice, 78, 1.0, 0.94, 0, true)


func _preferred_voice() -> String:
    # Prefer localized higher-quality system voices, especially pt_BR.
    var best_id: String = ""
    var best_score: int = -100
    for entry in DisplayServer.tts_get_voices():
        var lang: String = str(entry.get("language", "")).to_lower().replace("-", "_")
        if not lang.begins_with(locale.to_lower()):
            continue
        var name: String = str(entry.get("name", "")).to_lower()
        var score: int = 0
        if locale == "pt" and (lang.find("br") >= 0 or name.find("brasil") >= 0):
            score += 12
        for quality in ["premium", "enhanced", "natural", "neural", "siri"]:
            if name.find(quality) >= 0:
                score += 10
        for undesirable in ["compact", "robot", "espeak"]:
            if name.find(undesirable) >= 0:
                score -= 8
        if score > best_score:
            best_score = score
            best_id = str(entry.get("id", ""))
    return best_id


func _exit_tree() -> void:
    if DisplayServer.has_feature(DisplayServer.FEATURE_TEXT_TO_SPEECH) and DisplayServer.tts_is_speaking():
        DisplayServer.tts_stop()


func _is_finished_rack(index: int) -> bool:
    var eggs: Array = _bins[index]
    if eggs.size() != _target_counts[index]:
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
    if _dragging and not _held.is_empty():
        var egg: Dictionary = _lookup_held_egg()
        if not egg.is_empty():
            _draw_egg(_drag_point + Vector2(0.0, -9.0),
                    maxf(0.18, _egg_scale(int(_held["rack"])) * 1.1), int(egg["color"]))
    if _won:
        var data: Dictionary = WORDS.get(locale, WORDS["en"])
        _panel(Rect2(size.x * 0.20, size.y * 0.39, size.x * 0.60, size.y * 0.17),
                Color(0.04, 0.22, 0.27, 0.96), Color("95ffd8"), 23, 3)
        _text(str(data["win"]), Vector2(size.x * 0.21, size.y * 0.485),
                maxi(12, mini(26, roundi(size.x * 0.017))), Color("f4fff7"), size.x * 0.58)

func _draw_lab_background() -> void:
    # Full-cover background is drawn by a separate rounded shader layer
    # below this board, preserving clean alpha corners of the MIKA frame.
    pass

func _draw_incubator(index: int) -> void:
    var art: Rect2 = _art_rect(index)
    var target: Color = PALETTE[index]
    var eggs: Array = _bins[index]
    var selected: bool = _held.has("rack") and int(_held["rack"]) == index
    var hovering: bool = _dragging and _hover == index and not selected
    var complete: bool = _is_finished_rack(index)
    # Actual photographed console, not a schematic frame.
    if _incubator_image != null:
        draw_texture_rect(_incubator_image, art, false, Color.WHITE)
    else:
        _panel(art, Color("173351"), Color("6fe7ff"), 25, 3)
    # Coloured lamp + localized colour label INSIDE its upper blue screen.
    # There is deliberately no 3/4 occupancy text: the four bowls show capacity.
    var dot: Vector2 = art.position + Vector2(art.size.x * 0.225, art.size.y * 0.223)
    draw_circle(dot, maxf(5.0, art.size.y * 0.040),
            Color(target.r, target.g, target.b, 0.18))
    draw_circle(dot, maxf(3.0, art.size.y * 0.020), target.lightened(0.22))
    var lang: Dictionary = WORDS.get(locale, WORDS["en"])
    var names: Array = lang["colors"]
    var name: String = str(names[index])
    var font_size: int = maxi(9, mini(26, roundi(minf(art.size.y * 0.10,
            art.size.x * 0.59 / maxf(3.2, float(name.length()) * 0.57)))))
    _text(name, art.position + Vector2(art.size.x * 0.28,
            art.size.y * 0.254), font_size, target.lightened(0.50), art.size.x * 0.56)
    if selected or hovering:
        _panel(Rect2(art.position.x + art.size.x * 0.13,
                art.position.y + art.size.y * 0.12,
                art.size.x * 0.74, art.size.y * 0.245),
                Color(target.r, target.g, target.b, 0.045),
                Color(target.r, target.g, target.b, 0.43), 12, 2)
    # Eggs occupy the FOUR ORIGINAL BOWLS, left to right.
    for slot in range(eggs.size()):
        var egg: Dictionary = eggs[slot]
        var point: Vector2 = _egg_center(index, slot)
        var held_here: bool = _held.has("rack") and int(_held["rack"]) == index and int(_held["id"]) == int(egg["id"])
        if held_here and _dragging:
            continue
        _draw_egg(point, _egg_scale(index), int(egg["color"]))
        if held_here:
            draw_arc(point, maxf(12.0, 72.0 * _egg_scale(index)),
                    0.0, TAU, 32, Color("e2ffef", 0.90), 2.0, true)
    # The front rim of the four pictured bowls passes IN FRONT of the egg
    # shell, giving it a genuine seated/partially-overlapped appearance.
    if _incubator_image != null:
        var from_y: float = 782.0
        var to_y: float = _incubator_image.get_size().y
        var denom: float = maxf(1.0, _incubator_image.get_size().y)
        var lower: Rect2 = Rect2(
                art.position.x, art.position.y + art.size.y * from_y / denom,
                art.size.x, art.size.y * (to_y - from_y) / denom)
        draw_texture_rect_region(_incubator_image, lower,
                Rect2(0.0, from_y, _incubator_image.get_size().x, to_y - from_y), Color.WHITE)
    if complete:
        var badge: Vector2 = art.position + Vector2(art.size.x * 0.84, art.size.y * 0.25)
        draw_circle(badge, maxf(7.0, art.size.y * 0.032), Color("8effcc"))
        _text("✓", badge + Vector2(-10.0, 6.0), 16, Color("08334a"), 20.0)

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
