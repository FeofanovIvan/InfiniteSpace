extends Node2D
class_name MikaRoomScrubMask
## Local-space cosmetic dirt mask for the Bubble inside the actual room.
## Points are expressed in BubbleAnchor's LOCAL units; child inherits walk and zoom.

signal progress_changed(value: float)
signal completed

var spots: Array[Dictionary] = []
var active: bool = false
var completed_once: bool = false
const OFFSETS := [
    Vector2(-122, -241), Vector2(-95,-300), Vector2(-38,-327),
    Vector2(42,-323), Vector2(117,-267), Vector2(-125,-183),
    Vector2(124,-183), Vector2(-88,-151), Vector2(80,-147),
    Vector2(-41,-124), Vector2(45,-122), Vector2(2,-295)
]

func start_scrubbing() -> void:
    active = true
    completed_once = false
    spots.clear()
    for i in range(OFFSETS.size()):
        spots.append({"position": OFFSETS[i], "dirt": 1.0, "radius": 20.0 + float(i % 3) * 3.0})
    progress_changed.emit(0.0)
    queue_redraw()

func stop_scrubbing() -> void:
    active = false
    spots.clear()
    queue_redraw()

func scrub_at(local_point: Vector2, travel: float) -> float:
    if not active or completed_once or travel < 1.5:
        return get_progress()
    var total = 0.0
    for spot in spots:
        var d: float = local_point.distance_to(spot["position"])
        var rad: float = float(spot["radius"])
        if d < rad + 39.0:
            var weight: float = 1.0 - d / (rad + 39.0)
            spot["dirt"] = maxf(0.0, float(spot["dirt"]) - minf(travel,45.0) * 0.025 * weight)
        total += float(spot["dirt"])
    var p: float = clampf(1.0 - total / float(spots.size()), 0.0, 1.0)
    progress_changed.emit(p)
    if p >= 0.90 and not completed_once:
        completed_once = true
        completed.emit()
    queue_redraw()
    return p

func get_progress() -> float:
    if spots.is_empty(): return 0.0
    var total = 0.0
    for spot in spots: total += float(spot["dirt"])
    return clampf(1.0 - total / float(spots.size()),0.0,1.0)

func _draw() -> void:
    if not active: return
    for spot in spots:
        var a: float = float(spot["dirt"])
        var p: Vector2 = spot["position"]
        var r: float = float(spot["radius"])
        draw_circle(p, r, Color(0.38,0.27,0.44,0.42 * a))
        for j in range(4):
            var off = Vector2(sin(float(j)*2.3),cos(float(j)*2.7))*r*0.5
            draw_circle(p+off, r*0.22, Color(0.34,0.28,0.44,0.5*a))
