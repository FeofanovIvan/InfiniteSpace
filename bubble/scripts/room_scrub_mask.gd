extends Node2D
class_name MikaRoomScrubMask
## MIKA_BUBBLE_CONTINUOUS_SHOWER_V8_3_9
## Soap bubbles only: the existing Bubble gets foam drawn ON his body.
## No dirt spots, no platform under him, no extra Bubble body or scene.
## Coordinates live in BubbleAnchor local space, following that SAME actor.

signal progress_changed(value: float)
signal completed

const OFFSETS := [
    Vector2(-122, -241), Vector2(-95,-300), Vector2(-38,-327),
    Vector2(42,-323), Vector2(117,-267), Vector2(-125,-183),
    Vector2(124,-183), Vector2(-88,-151), Vector2(80,-147),
    Vector2(-41,-124), Vector2(45,-122), Vector2(2,-295)
]
const FOAM_PARTICLES_PER_POINT: int = 9
const COMPLETE_THRESHOLD: float = 0.90

var spots: Array[Dictionary] = []
var active: bool = false
var completed_once: bool = false
var _foam_clock: float = 0.0
var _foam_fade: float = 0.0

func start_scrubbing() -> void:
    active = true
    completed_once = false
    _foam_clock = 0.0
    _foam_fade = 0.0
    spots.clear()
    for i in range(OFFSETS.size()):
        spots.append({"position": OFFSETS[i], "clean": 0.0, "radius": 26.0 + float(i % 3) * 5.0})
    set_process(true)
    progress_changed.emit(0.0)
    queue_redraw()

func stop_scrubbing() -> void:
    active = false
    completed_once = false
    spots.clear()
    _foam_fade = 0.0
    set_process(false)
    queue_redraw()

func scrub_at(local_point: Vector2, travel: float) -> float:
    if not active or completed_once or travel < 1.5:
        return get_progress()
    var sum_clean: float = 0.0
    for spot in spots:
        var d: float = local_point.distance_to(spot["position"])
        var reach: float = float(spot["radius"]) + 43.0
        if d < reach:
            var weight: float = 1.0 - d / reach
            # Only sponge movement near Bubble's body advances washing.
            spot["clean"] = minf(1.0, float(spot["clean"]) + minf(travel, 42.0) * 0.025 * weight)
        sum_clean += float(spot["clean"])
    var progress: float = clampf(sum_clean / float(maxi(1, spots.size())), 0.0, 1.0)
    progress_changed.emit(progress)
    if progress >= COMPLETE_THRESHOLD and not completed_once:
        completed_once = true
        completed.emit()
    queue_redraw()
    return progress

func get_progress() -> float:
    if spots.is_empty():
        return 0.0
    var total: float = 0.0
    for spot in spots:
        total += float(spot["clean"])
    return clampf(total / float(spots.size()), 0.0, 1.0)

func _process(delta: float) -> void:
    if not active:
        return
    _foam_clock += delta
    _foam_fade = move_toward(_foam_fade, 1.0, delta * 0.72)
    queue_redraw()

func _draw() -> void:
    if not active or spots.is_empty():
        return
    # Individual light soap bubbles sit on the body's EXISTING projection;
    # there is intentionally NO opaque foam base, tray, dirt or second body.
    var strength: float = 0.82 * _foam_fade
    for i in range(spots.size()):
        var center: Vector2 = spots[i]["position"]
        var cleanliness: float = float(spots[i]["clean"])
        var group_alpha: float = strength * (0.50 + 0.44 * (1.0 - cleanliness))
        for j in range(FOAM_PARTICLES_PER_POINT):
            var seed: float = float(i * 11 + j)
            var angle: float = seed * 2.39996
            var orbit: float = 8.0 + float(j % 5) * 5.8
            var float_up: float = 3.5 * sin(_foam_clock * 1.7 + seed * 0.47)
            var p: Vector2 = center + Vector2(cos(angle) * orbit, sin(angle) * orbit - float_up)
            var r: float = (7.0 + float(j % 4) * 2.0) * (0.94 + 0.055 * sin(_foam_clock * 2.2 + seed))
            var opacity: float = group_alpha * (0.66 + 0.20 * sin(seed * 1.15 + _foam_clock))
            draw_circle(p, r, Color(0.90, 0.98, 1.0, opacity * 0.53), true)
            draw_arc(p, r * 0.92, PI * 1.03, PI * 1.83, 13, Color(1.0, 1.0, 1.0, opacity * 0.93), 1.7, true)
            if j % 3 == 0:
                draw_circle(p + Vector2(-r * 0.26, -r * 0.32), r * 0.18, Color(1.0, 1.0, 1.0, opacity * 0.71), true)
