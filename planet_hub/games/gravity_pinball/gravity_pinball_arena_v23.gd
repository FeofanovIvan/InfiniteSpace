extends Control
## MIKA Gravity Pinball v2.3 — original orbit gameplay and moving spring under launch button.
## Constant-speed asteroid bends around REAL Andromeda planets without hitting them.

signal crystals_changed(count: int)
signal round_finished(count: int)

const PLANET_PATHS: Array[String] = [
    "res://assets/atlas/planets/m31_p01.png",
    "res://assets/atlas/planets/m31_p02.png",
    "res://assets/atlas/planets/m31_p03.png",
    "res://assets/atlas/planets/m31_p05.png",
    "res://assets/atlas/planets/m31_p06.png",
    "res://assets/atlas/planets/m31_p07.png",
    "res://assets/atlas/planets/m31_p08.png",
    "res://assets/atlas/planets/m31_p04.png"
]
const ASTEROID_PATH: String = "res://asteroid_assets/original/01_gray_cratered.png"
const SFX_PATH: String = "res://planet_hub/games/gravity_pinball/audio/"
const PALETTE: Array[Color] = [Color("8deaff"), Color("ffa963"), Color("b9a5ff"), Color("a6fcd5"), Color("ffe38b")]
const STARS: int = 145
const HIT_COUNT: int = 5

var locale: String = "en"
var _planet_textures: Array[Texture2D] = []
var _asteroid_texture: Texture2D
var _sfx_launch: AudioStreamPlayer
var _sfx_hit: AudioStreamPlayer
var _sfx_win: AudioStreamPlayer
var _sfx_spring: AudioStreamPlayer
var _player_side_clearance: float = 130.0
var _shot_active: bool = false
var _power_pull: bool = false
var _ready_for_launch: bool = true
var _power: float = 0.56
var _charge_phase: float = 0.0
var _angle: float = -0.22
var _flight_speed: float = 370.0
var _asteroid: Vector2 = Vector2.ZERO
var _velocity: Vector2 = Vector2.ZERO
var _flight_time: float = 0.0
var _reload_timer: float = 0.0
var _crystals: int = 0
var _trail: Array[Vector2] = []
var _targets: Array[Dictionary] = []
var _target_cooldown: float = 0.0
var _round_over: bool = false
var _planets_layout: Array[Dictionary] = []
var _rng: RandomNumberGenerator = RandomNumberGenerator.new()
var _success_flash: float = 0.0
var _pulse: float = 0.0


func _ready() -> void:
    mouse_filter = Control.MOUSE_FILTER_IGNORE
    for path in PLANET_PATHS:
        _planet_textures.append(load(path) as Texture2D)
    _asteroid_texture = load(ASTEROID_PATH) as Texture2D
    _sfx_launch = _create_audio("pinball_launch_v2.wav", -9.0)
    _sfx_hit = _create_audio("pinball_chime_v2.wav", -10.0)
    _sfx_win = _create_audio("pinball_victory_v2.wav", -11.0)
    _sfx_spring = _create_audio("pinball_spring_v2.wav", -12.0)
    _rng.randomize()
    start_new_game()
    resized.connect(_on_resized)
    set_process(true)


func _create_audio(filename: String, gain_db: float) -> AudioStreamPlayer:
    var player := AudioStreamPlayer.new()
    player.name = filename.get_basename()
    player.volume_db = gain_db
    var path: String = SFX_PATH + filename
    if ResourceLoader.exists(path):
        player.stream = load(path) as AudioStream
    add_child(player)
    return player


func _play(player: AudioStreamPlayer) -> void:
    if is_instance_valid(player) and player.stream != null:
        player.play()


func set_control_clearance(px: float) -> void:
    _player_side_clearance = px


func _play_rect() -> Rect2:
    var pad: float = clampf(minf(size.x, size.y) * 0.022, 7.0, 17.0)
    return Rect2(pad, pad, maxf(100.0, size.x - pad * 2.0), maxf(80.0, size.y - pad * 2.0))


func _launch_anchor() -> Vector2:
    var field: Rect2 = _play_rect()
    var offset: float = clampf(field.size.x * 0.058, 31.0, 71.0)
    return Vector2(field.position.x + offset, field.position.y + field.size.y * 0.52)


func _planet_data() -> Array[Dictionary]:
    var field: Rect2 = _play_rect()
    var unit: float = maxf(0.47, minf(field.size.x / 1180.0, field.size.y / 550.0))
    var result: Array[Dictionary] = []
    for layout in _planets_layout:
        var i: int = int(layout["image"])
        result.append({
            "center": field.position + (layout["uv"] as Vector2) * field.size,
            "radius": float(layout["r"]) * unit,
            "texture": _planet_textures[i] if i < _planet_textures.size() else null,
            "index": i
        })
    return result

func _generate_planets() -> void:
    # Four separated regions prevent random planet piles, even on short screens.
    var quadrants: Array[Rect2] = [
        Rect2(0.32, 0.17, 0.15, 0.20),
        Rect2(0.49, 0.58, 0.15, 0.19),
        Rect2(0.72, 0.18, 0.13, 0.18),
        Rect2(0.76, 0.61, 0.12, 0.18)
    ]
    var ids: Array[int] = []
    for i in range(_planet_textures.size()):
        ids.append(i)
    ids.shuffle()
    var sizes: Array[float] = [37.0, 45.0, 32.0, 39.0]
    sizes.shuffle()
    _planets_layout.clear()
    var field: Rect2 = _play_rect()
    var unit: float = maxf(0.47, minf(field.size.x / 1180.0, field.size.y / 550.0))
    for i in range(4):
        var box: Rect2 = quadrants[i]
        var uv: Vector2 = box.position + box.size * 0.5
        for _attempt in range(160):
            var candidate: Vector2 = box.position + Vector2(_rng.randf(), _rng.randf()) * box.size
            var world: Vector2 = field.position + candidate * field.size
            var acceptable: bool = true
            for old in _planets_layout:
                var old_world: Vector2 = field.position + (old["uv"] as Vector2) * field.size
                var distance: float = (float(old["r"]) + sizes[i]) * unit + 24.0 * unit
                if world.distance_to(old_world) < distance:
                    acceptable = false
                    break
            if acceptable and world.distance_to(_launch_anchor()) > (sizes[i] + 65.0) * unit:
                uv = candidate
                break
        _planets_layout.append({"uv": uv, "image": ids[i], "r": sizes[i]})


func _rebuild_targets() -> void:
    # Five collectible bumpers; avoid planets, spring, rims and each other.
    _targets.clear()
    var field: Rect2 = _play_rect()
    var unit: float = maxf(0.47, minf(field.size.x / 1180.0, field.size.y / 550.0))
    var planets: Array[Dictionary] = _planet_data()
    var anchors: Array[Rect2] = [
        Rect2(0.30, 0.37, 0.16, 0.17),
        Rect2(0.48, 0.13, 0.16, 0.22),
        Rect2(0.65, 0.38, 0.15, 0.18),
        Rect2(0.36, 0.76, 0.22, 0.10),
        Rect2(0.84, 0.43, 0.09, 0.17)
    ]
    anchors.shuffle()
    for i in range(HIT_COUNT):
        var area: Rect2 = anchors[i]
        var uv: Vector2 = area.position + area.size * 0.5
        var found: bool = false
        for _attempt in range(200):
            var sample: Vector2 = Vector2(_rng.randf_range(0.21, 0.92), _rng.randf_range(0.12, 0.87))
            if _attempt < 70:
                sample = area.position + area.size * Vector2(_rng.randf(), _rng.randf())
            var point: Vector2 = field.position + sample * field.size
            var acceptable: bool = point.distance_to(_launch_anchor()) >= 85.0 * unit
            for planet in planets:
                if point.distance_to(planet["center"] as Vector2) < float(planet["radius"]) + _target_radius() + 18.0 * unit:
                    acceptable = false
            for other in _targets:
                if point.distance_to(other["pos"] as Vector2) < _target_radius() * 2.0 + 33.0 * unit:
                    acceptable = false
            if acceptable:
                uv = sample
                found = true
                break
        if not found:
            # Safe deterministic candidates for very small landscape aspect ratios.
            for sample in [Vector2(0.28, 0.56), Vector2(0.51, 0.46), Vector2(0.66, 0.86), Vector2(0.89, 0.49), Vector2(0.39, 0.12)]:
                var point: Vector2 = field.position + sample * field.size
                var ok: bool = true
                for planet in planets:
                    if point.distance_to(planet["center"] as Vector2) < float(planet["radius"]) + _target_radius() + 10.0 * unit:
                        ok = false
                for other in _targets:
                    if point.distance_to(other["pos"] as Vector2) < _target_radius() * 2.0 + 17.0 * unit:
                        ok = false
                if ok:
                    uv = sample
                    break
        _targets.append({"uv": uv, "pos": field.position + uv * field.size, "taken": false, "idx": i})

func _on_resized() -> void:
    if not _shot_active:
        _asteroid = _launch_anchor()
    var field: Rect2 = _play_rect()
    for target in _targets:
        target["pos"] = field.position + (target["uv"] as Vector2) * field.size
    queue_redraw()

func set_aim_amount(value: float) -> void:
    if _shot_active or _round_over:
        return
    _angle = lerpf(-1.08, 1.08, clampf(value, 0.0, 1.0))
    queue_redraw()


func begin_spring_charge() -> void:
    if _shot_active or _round_over or not _ready_for_launch or _power_pull:
        return
    _power_pull = true
    _charge_phase = 0.0
    _power = 0.56
    queue_redraw()


func release_spring_charge() -> void:
    if not _power_pull:
        return
    _power_pull = false
    _launch()


func cancel_spring_charge() -> void:
    _power_pull = false
    if not _shot_active:
        _power = 0.56
    queue_redraw()


func start_new_game() -> void:
    _shot_active = false
    _round_over = false
    _ready_for_launch = true
    _power_pull = false
    _power = 0.56
    _charge_phase = 0.0
    _flight_time = 0.0
    _reload_timer = 0.0
    _success_flash = 0.0
    _target_cooldown = 0.0
    _crystals = 0
    _trail.clear()
    _generate_planets()
    _rebuild_targets()
    _asteroid = _launch_anchor()
    _velocity = Vector2.ZERO
    crystals_changed.emit(_crystals)
    queue_redraw()

func _launch() -> void:
    if _shot_active or _round_over or not _ready_for_launch:
        return
    _flight_speed = lerpf(250.0, 695.0, _power)
    _asteroid = _launch_anchor()
    _velocity = Vector2.RIGHT.rotated(_angle) * _flight_speed
    _trail.clear()
    _flight_time = 0.0
    _shot_active = true
    _ready_for_launch = false
    _play(_sfx_launch)
    queue_redraw()


func _unhandled_input(event: InputEvent) -> void:
    if not (event is InputEventKey):
        return
    var key: InputEventKey = event as InputEventKey
    if key.keycode == KEY_SPACE:
        if key.pressed and not key.echo:
            begin_spring_charge()
        elif not key.pressed:
            release_spring_charge()
        get_viewport().set_input_as_handled()
        return
    if not key.pressed or key.echo:
        return
    if key.keycode == KEY_UP and not _shot_active:
        _angle = clampf(_angle - 0.12, -1.02, 1.02)
    elif key.keycode == KEY_DOWN and not _shot_active:
        _angle = clampf(_angle + 0.12, -1.02, 1.02)
    queue_redraw()


func _process(delta: float) -> void:
    if size.x < 160.0 or size.y < 100.0:
        return
    _pulse += delta
    if _power_pull and _ready_for_launch and not _shot_active and not _round_over:
        # Speed modulates subtly: the child must time the RELEASE, not set a fixed value.
        _charge_phase += delta * (7.2 + 1.10 * sin(_pulse * 1.65))
        _power = 0.56 + 0.41 * sin(_charge_phase)
    _success_flash = maxf(0.0, _success_flash - delta)
    if _target_cooldown > 0.0 and not _round_over:
        _target_cooldown -= delta
        if _target_cooldown <= 0.0:
            _rebuild_targets()
    if _shot_active:
        var steps: int = maxi(1, ceili(minf(delta, 0.09) / 0.010))
        var step: float = minf(delta, 0.09) / float(steps)
        for _index in range(steps):
            if not _shot_active:
                break
            _advance_asteroid(step)
        _flight_time += delta
    queue_redraw()

func _advance_asteroid(step: float) -> void:
    var direction: Vector2 = _velocity.normalized()
    if direction.length_squared() < 0.5:
        direction = Vector2.RIGHT
    var r_asteroid: float = _asteroid_radius()
    for planet in _planet_data():
        var center: Vector2 = planet["center"] as Vector2
        var radius: float = float(planet["radius"])
        var toward: Vector2 = center - _asteroid
        var distance: float = toward.length()
        var safety: float = radius + r_asteroid + 11.0
        var influence: float = safety + 150.0 * maxf(0.55, minf(size.x / 1180.0, size.y / 550.0))
        if distance < influence and distance > 0.001:
            var proximity: float = 1.0 - clampf((distance - safety) / maxf(1.0, influence - safety), 0.0, 1.0)
            var outward: Vector2 = -toward / distance
            # Approach is bent into a tangent; never reflect on a planet.
            var spin: float = 1.0 if outward.cross(direction) >= 0.0 else -1.0
            var tangent: Vector2 = Vector2(-outward.y, outward.x) * spin
            if distance <= safety + 29.0:
                var desired: Vector2 = (tangent * 0.94 + outward * 0.43).normalized()
                direction = direction.lerp(desired, minf(0.90, step * (4.0 + proximity * 8.0))).normalized()
                if distance < safety:
                    _asteroid = center + outward * safety
            else:
                var bend: Vector2 = toward.normalized() * (0.20 * proximity * proximity)
                direction = (direction + bend * step * 4.0).normalized()
    _velocity = direction * _flight_speed
    _asteroid += _velocity * step
    var bounds: Rect2 = _play_rect()
    var minimum: Vector2 = bounds.position + Vector2.ONE * r_asteroid
    var maximum: Vector2 = bounds.end - Vector2.ONE * r_asteroid
    if _asteroid.x < minimum.x:
        if _is_pocket("left", _asteroid.y):
            _finish_in_pocket()
            return
        _asteroid.x = minimum.x
        _velocity.x = absf(_velocity.x)
    elif _asteroid.x > maximum.x:
        if _is_pocket("right", _asteroid.y):
            _finish_in_pocket()
            return
        _asteroid.x = maximum.x
        _velocity.x = -absf(_velocity.x)
    if _asteroid.y < minimum.y:
        if _is_pocket("top", _asteroid.x):
            _finish_in_pocket()
            return
        _asteroid.y = minimum.y
        _velocity.y = absf(_velocity.y)
    elif _asteroid.y > maximum.y:
        if _is_pocket("bottom", _asteroid.x):
            _finish_in_pocket()
            return
        _asteroid.y = maximum.y
        _velocity.y = -absf(_velocity.y)
    _velocity = _velocity.normalized() * _flight_speed
    _trail.push_back(_asteroid)
    if _trail.size() > 36:
        _trail.pop_front()
    for hit in _targets:
        if not bool(hit["taken"]) and _asteroid.distance_to(hit["pos"] as Vector2) < _target_radius() + r_asteroid:
            hit["taken"] = true
            _crystals = mini(50, _crystals + 1)
            crystals_changed.emit(_crystals)
            _play(_sfx_hit)
            _success_flash = 0.18
            if _all_targets_taken():
                _target_cooldown = 1.5
                _success_flash = 1.5
                _play(_sfx_win)


func _pocket_specs() -> Array[Dictionary]:
    # Opening fractions along all four wall edges; keep left spring centered clear.
    return [
        {"side": "left", "at": 0.20}, {"side": "left", "at": 0.81},
        {"side": "right", "at": 0.20}, {"side": "right", "at": 0.79},
        {"side": "top", "at": 0.27}, {"side": "top", "at": 0.55}, {"side": "top", "at": 0.83},
        {"side": "bottom", "at": 0.30}, {"side": "bottom", "at": 0.57}, {"side": "bottom", "at": 0.85}
    ]


func _pocket_center(spec: Dictionary) -> Vector2:
    var bounds: Rect2 = _play_rect()
    var at: float = float(spec["at"])
    match str(spec["side"]):
        "left": return Vector2(bounds.position.x, bounds.position.y + bounds.size.y * at)
        "right": return Vector2(bounds.end.x, bounds.position.y + bounds.size.y * at)
        "top": return Vector2(bounds.position.x + bounds.size.x * at, bounds.position.y)
        _: return Vector2(bounds.position.x + bounds.size.x * at, bounds.end.y)


func _pocket_halfwidth() -> float:
    var bounds: Rect2 = _play_rect()
    return clampf(minf(bounds.size.x, bounds.size.y) * 0.058, 15.0, 36.0)


func _is_pocket(side: String, coordinate: float) -> bool:
    var half: float = _pocket_halfwidth()
    for spec in _pocket_specs():
        if str(spec["side"]) != side:
            continue
        var center: Vector2 = _pocket_center(spec)
        var at: float = center.y if side in ["left", "right"] else center.x
        if absf(coordinate - at) <= half:
            return true
    return false


func _finish_in_pocket() -> void:
    _shot_active = false
    _round_over = true
    _ready_for_launch = false
    _velocity = Vector2.ZERO
    _power_pull = false
    _play(_sfx_spring)
    round_finished.emit(_crystals)
    queue_redraw()


func _all_targets_taken() -> bool:
    for target in _targets:
        if not bool(target["taken"]):
            return false
    return true


func _asteroid_radius() -> float:
    return clampf(minf(size.x / 1200.0, size.y / 580.0) * 13.0, 6.5, 14.0)


func _target_radius() -> float:
    return clampf(minf(size.x / 1200.0, size.y / 580.0) * 15.0, 9.0, 16.0)


func _draw() -> void:
    if size.x < 100.0 or size.y < 70.0:
        return
    draw_rect(Rect2(Vector2.ZERO, size), Color("051025"))
    _draw_stars()
    _draw_walls()
    for planet in _planet_data():
        _draw_planet(planet)
    for target in _targets:
        _draw_target(target)
    _draw_launcher()
    _draw_asteroid()
    if _success_flash > 0.1 and _target_cooldown > 0.0:
        var font_size: int = maxi(13, mini(28, roundi(size.y * 0.041)))
        var label: String = "ОТЛИЧНО!" if locale == "ru" else ("GREAT!" if locale == "en" else "✓")
        draw_string(ThemeDB.fallback_font, Vector2(size.x * 0.50 - 55.0, size.y * 0.14),
                label, HORIZONTAL_ALIGNMENT_LEFT, -1.0, font_size, Color("c5ffe1"))


func _draw_stars() -> void:
    for i in range(STARS):
        var x: float = fposmod(float(i * 617 + 43) * 0.713, 997.0) / 997.0
        var y: float = fposmod(float(i * 109 + 77) * 1.373, 937.0) / 937.0
        var twinkle: float = 0.45 + 0.27 * sin(_pulse * 1.35 + float(i))
        var radius: float = 0.55 + float(i % 4) * 0.33
        draw_circle(Vector2(x * size.x, y * size.y), radius,
                Color(0.67, 0.82, 1.0, 0.23 + twinkle * 0.45))
    draw_circle(Vector2(size.x * 0.62, size.y * 0.31), size.y * 0.39, Color("25306c", 0.13))
    draw_circle(Vector2(size.x * 0.28, size.y * 0.67), size.y * 0.31, Color("197b8a", 0.10))


func _draw_walls() -> void:
    var r: Rect2 = _play_rect()
    var line_color: Color = Color("55c8f0", 0.43)
    # Draw solid boundaries in segments separated by actual basket openings.
    var half: float = _pocket_halfwidth()
    for side in ["top", "bottom", "left", "right"]:
        var lo: float = r.position.x if side in ["top", "bottom"] else r.position.y
        var hi: float = r.end.x if side in ["top", "bottom"] else r.end.y
        var cuts: Array[float] = []
        for spec in _pocket_specs():
            if str(spec["side"]) == side:
                var center: Vector2 = _pocket_center(spec)
                cuts.append(center.x if side in ["top", "bottom"] else center.y)
        cuts.sort()
        var previous: float = lo
        for at in cuts:
            _wall_segment(side, previous, at - half, r, line_color)
            previous = at + half
        _wall_segment(side, previous, hi, r, line_color)
        for at in cuts:
            var mouth: Vector2 = Vector2(at, r.position.y if side == "top" else r.end.y) if side in ["top", "bottom"] else Vector2(r.position.x if side == "left" else r.end.x, at)
            _draw_pocket(mouth, side, half)


func _wall_segment(side: String, a: float, b: float, bounds: Rect2, tint: Color) -> void:
    if b <= a:
        return
    if side == "top" or side == "bottom":
        var y: float = bounds.position.y if side == "top" else bounds.end.y
        draw_line(Vector2(a, y), Vector2(b, y), tint, 3.0, true)
    else:
        var x: float = bounds.position.x if side == "left" else bounds.end.x
        draw_line(Vector2(x, a), Vector2(x, b), tint, 3.0, true)


func _draw_pocket(center: Vector2, side: String, half: float) -> void:
    # Visible dark receptacle, glowing lips around the hole.
    var vert: bool = side in ["left", "right"]
    var dark: Rect2 = Rect2(center - (Vector2(11.0, half) if vert else Vector2(half, 11.0)),
            Vector2(22.0, half * 2.0) if vert else Vector2(half * 2.0, 22.0))
    draw_rect(dark, Color(0.005, 0.015, 0.045, 0.92), true)
    var accent: Color = Color("f4b35b", 0.90)
    if vert:
        draw_arc(center, half, -PI * 0.48, PI * 0.48, 24, accent, 3.0, true)
        draw_circle(center + Vector2(4.0 if side == "left" else -4.0, 0.0), maxf(2.0, half * 0.18), Color("ffc66b", 0.62))
    else:
        draw_arc(center, half, 0.02, PI - 0.02, 24, accent, 3.0, true)
        draw_circle(center + Vector2(0.0, 4.0 if side == "top" else -4.0), maxf(2.0, half * 0.18), Color("ffc66b", 0.62))

func _draw_planet(planet: Dictionary) -> void:
    var center: Vector2 = planet["center"] as Vector2
    var radius: float = float(planet["radius"])
    draw_circle(center, radius * 1.65, Color("7dabff", 0.046))
    draw_circle(center, radius * 1.25, Color("86cffa", 0.073))
    var image: Texture2D = planet["texture"] as Texture2D
    if image != null:
        draw_texture_rect(image, Rect2(center - Vector2.ONE * radius, Vector2.ONE * radius * 2.0), false)
    else:
        draw_circle(center, radius, Color("74b8e9"))
    draw_arc(center, radius + _asteroid_radius() + 11.0, 0.0, TAU, 70, Color("8ddaff", 0.18), 1.25, true)


func _draw_target(target: Dictionary) -> void:
    var center: Vector2 = target["pos"] as Vector2
    var r: float = _target_radius()
    var idx: int = int(target["idx"])
    if bool(target["taken"]):
        draw_circle(center, r * 0.7, Color(PALETTE[idx], 0.12))
        return
    var c: Color = PALETTE[idx]
    var ring: float = r * (1.16 + 0.12 * sin(_pulse * 3.0 + float(idx)))
    draw_circle(center, r * 0.68, Color(c, 0.30))
    draw_arc(center, ring, 0.0, TAU, 48, c, 2.5, true)
    draw_circle(center, r * 0.29, c.lightened(0.27))
    for j in range(4):
        var a: float = float(j) * TAU / 4.0 + PI * 0.25
        draw_circle(center + Vector2.RIGHT.rotated(a) * r * 0.83, maxf(1.0, r * 0.11), Color.WHITE)


func _draw_launcher() -> void:
    var anchor: Vector2 = _launch_anchor()
    var scale_unit: float = maxf(0.55, minf(size.x / 1250.0, size.y / 650.0))
    var compressed: float = _power if _power_pull else 0.10
    var base: Vector2 = anchor - Vector2(45.0, 0.0) * scale_unit
    var front: Vector2 = anchor - Vector2(12.0, 0.0) * scale_unit
    draw_line(base + Vector2(0, -25) * scale_unit, base + Vector2(0, 25) * scale_unit, Color("5aa7cc"), 5.0 * scale_unit)
    draw_line(base + Vector2(0, -18) * scale_unit, front + Vector2(0, -18) * scale_unit, Color("99e9ff"), 4.0 * scale_unit)
    draw_line(base + Vector2(0, 18) * scale_unit, front + Vector2(0, 18) * scale_unit, Color("99e9ff"), 4.0 * scale_unit)
    var coils: int = 7
    var length: float = (42.0 - compressed * 21.0) * scale_unit
    var springs: PackedVector2Array = PackedVector2Array()
    for idx in range(coils * 2 + 1):
        springs.append(base + Vector2(float(idx) / float(coils * 2) * length,
                (-10.0 if idx % 2 == 0 else 10.0) * scale_unit))
    draw_polyline(springs, Color("ffd98e"), 3.2 * scale_unit, true)
    var direction: Vector2 = Vector2.RIGHT.rotated(_angle)
    if not _shot_active:
        var tip: Vector2 = anchor + direction * (100.0 + _power * 64.0) * scale_unit
        draw_line(anchor, tip, Color("8eeeff", 0.80), 4.0 * scale_unit, true)
        draw_line(tip, tip - direction.rotated(0.43) * 18.0 * scale_unit, Color("efffff"), 3.0 * scale_unit, true)
        draw_line(tip, tip - direction.rotated(-0.43) * 18.0 * scale_unit, Color("efffff"), 3.0 * scale_unit, true)
        draw_arc(anchor, 23.0 * scale_unit, 0.0, TAU, 36, Color("69cdf8", 0.50), 2.0, true)


func _draw_asteroid() -> void:
    if _round_over or (not _shot_active and not _ready_for_launch):
        return
    var r: float = _asteroid_radius()
    var center: Vector2 = _asteroid if _shot_active else _launch_anchor()
    if _shot_active and _trail.size() > 1:
        for idx in range(1, _trail.size()):
            var weight: float = float(idx) / float(_trail.size())
            draw_line(_trail[idx - 1], _trail[idx], Color(0.45, 0.84, 1.0, weight * 0.55), 1.2 + weight * 3.0, true)
    draw_circle(center, r * 1.7, Color("ffc37a", 0.15))
    if _asteroid_texture != null:
        draw_texture_rect(_asteroid_texture, Rect2(center - Vector2.ONE * r, Vector2.ONE * (r * 2.0)), false)
    else:
        draw_circle(center, r, Color("c3ac91"))
