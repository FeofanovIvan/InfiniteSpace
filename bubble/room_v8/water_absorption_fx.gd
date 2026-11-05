extends Node2D
## Visual-only drinking effect.  The existing drinker fountain draws all water.
## This layer simply moves a few cyan droplets from that same fountain into
## Bubble's translucent body, where they swirl and dissolve.
## No second water source, bowl, or texture is instantiated.

const EMISSION_INTERVAL: float = 0.115
const MAX_DROPLETS: int = 28
var _droplets: Array[Dictionary] = []
var _emission_clock: float = 0.0
var _sample_source: Vector2 = Vector2.ZERO
var _sample_body: Vector2 = Vector2.ZERO
var _size_factor: float = 1.0
var _is_drinking: bool = false
var _serial: int = 0

func sample(drinking: bool, delta: float, fountain_point: Vector2, body_point: Vector2, world_scale: float) -> void:
    _sample_source = fountain_point
    _sample_body = body_point
    _size_factor = clampf(world_scale / 0.35, 0.5, 1.75)
    _is_drinking = drinking
    if not drinking:
        _emission_clock = 0.0
        return
    _emission_clock += clampf(delta, 0.0, 0.08)
    while _emission_clock >= EMISSION_INTERVAL and _droplets.size() < MAX_DROPLETS:
        _emission_clock -= EMISSION_INTERVAL
        _spawn_droplet()
    queue_redraw()

func _spawn_droplet() -> void:
    var index: float = float(_serial)
    _serial += 1
    _droplets.append({
        "age": 0.0,
        "duration": 0.84 + float(_serial % 4) * 0.11,
        "from": _sample_source + Vector2(sin(index * 2.38) * 7.0, cos(index * 1.97) * 4.0),
        "target": _sample_body + Vector2(sin(index * 2.72) * 12.0, cos(index * 1.87) * 10.0),
        "seed": index,
        "radius": (2.1 + float(_serial % 3) * 0.55) * _size_factor
    })

func _process(delta: float) -> void:
    if _droplets.is_empty():
        return
    var kept: Array[Dictionary] = []
    for drop in _droplets:
        drop["age"] = float(drop["age"]) + minf(delta, 0.08)
        if float(drop["age"]) < float(drop["duration"]):
            kept.append(drop)
    _droplets = kept
    queue_redraw()

func _draw() -> void:
    for drop in _droplets:
        var t: float = clampf(float(drop["age"]) / float(drop["duration"]), 0.0, 1.0)
        var start: Vector2 = drop["from"]
        var finish: Vector2 = drop["target"]
        var seed: float = float(drop["seed"])
        var point: Vector2
        var alpha: float
        if t <= 0.46:
            var u: float = clampf(t / 0.46, 0.0, 1.0)
            var smooth: float = u * u * (3.0 - 2.0 * u)
            var ctrl: Vector2 = start.lerp(finish, 0.54) + Vector2(7.0 * sin(seed), -13.0)
            var inv: float = 1.0 - smooth
            point = inv * inv * start + 2.0 * inv * smooth * ctrl + smooth * smooth * finish
            alpha = (0.56 + 0.20 * smooth) * minf(u * 8.0, 1.0)
        else:
            var u2: float = clampf((t - 0.46) / 0.54, 0.0, 1.0)
            var phase: float = seed * 2.2 + u2 * 5.3
            var orbit_radius: float = 12.0 * pow(1.0 - u2, 1.25) * _size_factor
            point = finish + Vector2(cos(phase), sin(phase)) * orbit_radius
            alpha = 0.72 * pow(1.0 - u2, 1.6)
        if alpha < 0.006:
            continue
        var radius: float = float(drop["radius"]) * (1.0 + 0.36 * t)
        draw_circle(point, radius * 3.1, Color(0.32, 0.92, 1.0, alpha * 0.08))
        draw_circle(point, radius * 1.5, Color(0.28, 0.82, 1.0, alpha * 0.22))
        draw_circle(point, radius, Color(0.73, 0.98, 1.0, alpha * 0.72))
        draw_circle(point + Vector2(-0.55, -0.65), radius * 0.30, Color(1, 1, 1, alpha * 0.86))

func stop_immediately() -> void:
    _is_drinking = false
    _emission_clock = 0.0
    _droplets.clear()
    queue_redraw()

func stop_emitting() -> void:
    _is_drinking = false
    _emission_clock = 0.0
