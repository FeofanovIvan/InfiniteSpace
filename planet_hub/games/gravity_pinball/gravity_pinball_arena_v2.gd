extends Control
## Space pinball playfield. Planets bend an asteroid into near-orbits without
## physical planet impacts and with strictly conserved in-flight speed.
## Original flight joysticks trigger set_power_input and set_aim_input.

signal crystals_changed(count: int)

const PLANET_PATHS: Array[String] = [
    "res://assets/atlas/planets/m31_p01.png",
    "res://assets/atlas/planets/m31_p02.png",
    "res://assets/atlas/planets/m31_p03.png",
    "res://assets/atlas/planets/m31_p05.png"
]
const ASTEROID_PATH: String = "res://asteroid_assets/original/01_gray_cratered.png"
const SFX_PATH: String = "res://planet_hub/games/gravity_pinball/audio/"
const PALETTE: Array[Color] = [Color("8deaff"), Color("ffa963"), Color("b9a5ff"), Color("a6fcd5"), Color("ffe38b")]
const STARS: int = 145
const HIT_COUNT: int = 5
const SHOT_SECONDS: float = 19.0

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
    _rebuild_targets()
    _asteroid = _launch_anchor()
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
    var radius_unit: float = maxf(0.55, minf(field.size.x / 1180.0, field.size.y / 550.0))
    var layout: Array[Vector2] = [Vector2(0.36, 0.22), Vector2(0.57, 0.65), Vector2(0.77, 0.26), Vector2(0.86, 0.68)]
    var radii: Array[float] = [36.0, 49.0, 30.0, 37.0]
    var result: Array[Dictionary] = []
    for idx in range(layout.size()):
        result.append({
            "center": field.position + layout[idx] * field.size,
            "radius": radii[idx] * radius_unit,
            "texture": _planet_textures[idx] if idx < _planet_textures.size() else null,
            "index": idx
        })
    return result


func _rebuild_targets() -> void:
    # Fixed positions for readable targets. State resets every cleared set.
    _targets.clear()
    var field: Rect2 = _play_rect()
    var spots: Array[Vector2] = [Vector2(0.52, 0.13), Vector2(0.66, 0.40), Vector2(0.92, 0.40), Vector2(0.69, 0.87), Vector2(0.44, 0.78)]
    for idx in range(spots.size()):
        _targets.append({"pos": field.position + field.size * spots[idx], "taken": false, "idx": idx})


func _on_resized() -> void:
    if not _shot_active:
        _asteroid = _launch_anchor()
    _rebuild_targets()
    queue_redraw()


func set_aim_input(value: Vector2) -> void:
    # Joystick is momentary; angle remains where it was aimed on release.
    if value.length() > 0.10 and not _shot_active:
        _angle = clampf(value.y * 1.02, -1.02, 1.02)
        queue_redraw()


func set_power_input(value: Vector2) -> void:
    # The ORIGINAL flight joystick automatically sends ZERO upon release.
    # Pull its handle down to compress the spring; release to launch.
    if _shot_active or not _ready_for_launch:
        return
    if value.y > 0.10:
        _power_pull = true
        _power = clampf(value.y, 0.14, 1.0)
        queue_redraw()
    elif _power_pull and value.length() < 0.08:
        _power_pull = false
        _launch()
    # Moving the power handle upward does not trigger a shot.


func _launch() -> void:
    if _shot_active or not _ready_for_launch:
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
    if not key.pressed or key.echo:
        return
    if key.keycode == KEY_SPACE:
        _launch()
        get_viewport().set_input_as_handled()
    elif key.keycode == KEY_UP and not _shot_active:
        _angle = clampf(_angle - 0.12, -1.02, 1.02)
    elif key.keycode == KEY_DOWN and not _shot_active:
        _angle = clampf(_angle + 0.12, -1.02, 1.02)
    elif key.keycode == KEY_LEFT and not _shot_active:
        _power = clampf(_power - 0.09, 0.14, 1.0)
    elif key.keycode == KEY_RIGHT and not _shot_active:
        _power = clampf(_power + 0.09, 0.14, 1.0)
    queue_redraw()


func _process(delta: float) -> void:
    if size.x < 160.0 or size.y < 100.0:
        return
    _pulse += delta
    _success_flash = maxf(0.0, _success_flash - delta)
    if _target_cooldown > 0.0:
        _target_cooldown -= delta
        if _target_cooldown <= 0.0:
            _rebuild_targets()
    if _shot_active:
        var step: float = minf(delta, 0.055) / 4.0
        for _index in range(4):
            _advance_asteroid(step)
        _flight_time += delta
        if _flight_time >= SHOT_SECONDS:
            _shot_active = false
            _reload_timer = 0.75
    elif not _ready_for_launch:
        _reload_timer -= delta
        if _reload_timer <= 0.0:
            _ready_for_launch = true
            _asteroid = _launch_anchor()
            _trail.clear()
            _power_pull = false
            _play(_sfx_spring)
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
    if _asteroid.x < minimum.x or _asteroid.x > maximum.x:
        _asteroid.x = clampf(_asteroid.x, minimum.x, maximum.x)
        _velocity.x = -_velocity.x
    if _asteroid.y < minimum.y or _asteroid.y > maximum.y:
        _asteroid.y = clampf(_asteroid.y, minimum.y, maximum.y)
        _velocity.y = -_velocity.y
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
    var fill: Color = Color("42bde6", 0.20)
    var hi: Color = Color("87eaff", 0.34)
    draw_rect(Rect2(r.position.x, r.position.y, r.size.x, 3.0), fill)
    draw_rect(Rect2(r.position.x, r.end.y - 3.0, r.size.x, 3.0), fill)
    draw_rect(Rect2(r.position.x, r.position.y, 3.0, r.size.y), fill)
    draw_rect(Rect2(r.end.x - 3.0, r.position.y, 3.0, r.size.y), fill)
    draw_line(r.position + Vector2(8.0, 2.0), r.position + Vector2(r.size.x * 0.33, 2.0), hi, 2.0)


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
    # Small power gauge above the launcher, no separate game score.
    var gauge: Rect2 = Rect2(anchor + Vector2(-36, -56) * scale_unit, Vector2(103, 8) * scale_unit)
    draw_rect(gauge, Color("132c4b"))
    draw_rect(Rect2(gauge.position, Vector2(gauge.size.x * _power, gauge.size.y)), Color("ffc375"))


func _draw_asteroid() -> void:
    if not _shot_active and not _ready_for_launch:
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
