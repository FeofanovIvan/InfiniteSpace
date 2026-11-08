extends Node2D
## Visual-only feeding effect for EXISTING Room v8 feeder.
## Particle emission is driven by actual _fill decrease in CareObjectFX.gd.
## This is not a bowl, feeder, or second generator.

const SERVING_PELLETS: float = 72.0
const PELLETS_PER_SPARK: float = 2.2
const MAX_VISIBLE: int = 24
const EPS: float = 0.00001

var _particles: Array[Dictionary] = []
var _previous_fill: float = -1.0
var _pending_pellets: float = 0.0
var _feeding: bool = false
var _source: Vector2 = Vector2.ZERO
var _body: Vector2 = Vector2.ZERO
var _body_scale: float = 0.35
var _clock: float = 0.0
var _seed_index: int = 0

func sample(feeding_now: bool, actual_fill: float, source_point: Vector2, body_point: Vector2, body_scale: float) -> void:
    _source = source_point
    _body = body_point
    _body_scale = maxf(0.05, body_scale)
    var fill: float = clampf(actual_fill, 0.0, 1.0)
    if not feeding_now:
        _previous_fill = -1.0
        _pending_pellets = 0.0
        _feeding = false
        return
    if not _feeding or _previous_fill < 0.0:
        _previous_fill = fill
        _feeding = true
        return
    # This counter moves ONLY when the existing feeder loses pellets.
    # No independent consumption timer or new supply is created here.
    var eaten_fraction: float = maxf(0.0, _previous_fill - fill)
    _pending_pellets += eaten_fraction * SERVING_PELLETS
    _previous_fill = fill
    var spawned: int = 0
    while _pending_pellets >= PELLETS_PER_SPARK and spawned < 5 and _particles.size() < MAX_VISIBLE:
        _pending_pellets -= PELLETS_PER_SPARK
        _make_particle()
        spawned += 1
    queue_redraw()

func _make_particle() -> void:
    var idx: float = float(_seed_index)
    _seed_index += 1
    var angle: float = idx * 2.39996323
    var sideways: float = sin(idx * 2.81) * 13.0 * _body_scale / 0.35
    var start: Vector2 = _source + Vector2(sideways, -2.0 + cos(idx * 1.9) * 2.5)
    var radius: float = (9.0 + float(_seed_index % 4) * 3.8) * _body_scale / 0.35
    var internal_offset: Vector2 = Vector2(cos(angle), sin(angle)) * radius
    _particles.append({
        "age": 0.0,
        "life": 0.95 + 0.15 * float(_seed_index % 4),
        "start": start,
        "internal_offset": internal_offset,
        "angle": angle,
        "radius": 2.0 + float(_seed_index % 3) * 0.45
    })

func _process(delta: float) -> void:
    _clock += delta
    if _particles.is_empty():
        return
    var alive: Array[Dictionary] = []
    for p in _particles:
        p["age"] = float(p["age"]) + delta
        if float(p["age"]) < float(p["life"]):
            alive.append(p)
    _particles = alive
    queue_redraw()

func _draw() -> void:
    if _particles.is_empty():
        return
    for p in _particles:
        var t: float = clampf(float(p["age"]) / float(p["life"]), 0.0, 1.0)
        var start: Vector2 = p["start"]
        var internal: Vector2 = p["internal_offset"]
        var angle: float = float(p["angle"])
        var point: Vector2
        var opacity: float
        var outer: float
        if t < 0.42:
            # Pickup from the REAL bowl into the lower translucent body.
            var travel: float = clampf(t / 0.42, 0.0, 1.0)
            var smooth: float = travel * travel * (3.0 - 2.0 * travel)
            var entry: Vector2 = _body + internal * 1.4
            var control: Vector2 = start.lerp(entry, 0.5) + Vector2(sin(angle) * 11.0, -16.0)
            var inv: float = 1.0 - smooth
            point = inv * inv * start + 2.0 * inv * smooth * control + smooth * smooth * entry
            opacity = 0.9 - travel * 0.30
            outer = 1.0
        else:
            # The kibble is now IN Bubble. It spirals, diffuses and vanishes.
            var dissolve: float = clampf((t - 0.42) / 0.58, 0.0, 1.0)
            var orbit: float = angle + dissolve * 4.0
            var pull: float = pow(1.0 - dissolve, 1.25)
            var radius: float = internal.length() * pull
            point = _body + Vector2(cos(orbit), sin(orbit)) * radius
            opacity = 0.55 * pow(1.0 - dissolve, 1.6)
            outer = 1.0 + dissolve * 1.3
        var r: float = float(p["radius"]) * outer
        if opacity > EPS:
            draw_circle(point, r * 3.2, Color(1.0, 0.74, 0.34, opacity * 0.085))
            draw_circle(point, r * 1.45, Color(1.0, 0.66, 0.24, opacity * 0.20))
            draw_circle(point, r * 0.84, Color(1.0, 0.87, 0.52, opacity * 0.67))
            draw_circle(point + Vector2(-r * 0.2, -r * 0.2), r * 0.35, Color(0.90, 1.0, 1.0, opacity * 0.80))

func stop_immediately() -> void:
    _feeding = false
    _previous_fill = -1.0
    _pending_pellets = 0.0
    _particles.clear()
    queue_redraw()
