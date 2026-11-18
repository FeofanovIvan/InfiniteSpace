extends Node2D
class_name MikaShowerPlay
## Water shower with dynamic dirt masks, true brush-contact progress, and foam.
signal cleaning_progress(ratio: float)
signal cleaning_completed

var running: bool = false
var stage_center: Vector2 = Vector2(960.0, 520.0)
var age: float = 0.0
var stains: Array[Dictionary] = []
var completed: bool = false

func start_at(center: Vector2) -> void:
    stage_center = center
    age = 0.0
    completed = false
    running = true
    stains.clear()
    # Intentionally avoid eyes and mouth. Spots cover main membrane + satellite bubbles.
    var offsets: Array[Vector2] = [
        Vector2(-119,-56),Vector2(-76,-89),Vector2(-40,-72), Vector2(41,-86),
        Vector2(117,-56),Vector2(-104,27),Vector2(104,24), Vector2(-56,80),
        Vector2(61,75), Vector2(-102,89),Vector2(107,86),Vector2(13,-114),
        Vector2(-63,100),Vector2(78,-17),Vector2(-14,103),Vector2(99,-4)
    ]
    for i in range(offsets.size()):
        stains.append({"p":stage_center + offsets[i], "dirty":1.0, "radius": 16.0 + float((i*7)%12)})
    cleaning_progress.emit(0.0)
    queue_redraw()

func end_shower() -> void:
    running = false
    queue_redraw()

func scrub(global_tip: Vector2, travel: float) -> float:
    if not running or completed or travel < 1.2:
        return get_cleanliness()
    for spot in stains:
        var dist: float = global_tip.distance_to(spot["p"])
        if dist < float(spot["radius"]) + 27.0:
            var weight: float = 1.0 - dist / (float(spot["radius"]) + 27.0)
            spot["dirty"] = maxf(0.0, float(spot["dirty"]) - minf(travel, 35.0)*0.012 * weight)
    var p: float = get_cleanliness()
    cleaning_progress.emit(p)
    if p >= 0.93:
        completed = true
        end_shower()
        cleaning_completed.emit()
    queue_redraw()
    return p

func get_cleanliness() -> float:
    var dirty: float = 0.0
    for spot in stains:
        dirty += float(spot["dirty"])
    return 1.0 - dirty / maxf(1.0,float(stains.size()))

func _process(delta: float) -> void:
    if running:
        age += delta
        queue_redraw()

func _draw() -> void:
    if not running:
        return
    var c: Vector2 = stage_center
    # Metal shower head above Bubble; drawn above existing game background.
    var head: Vector2 = c + Vector2(0,-320)
    draw_line(head+Vector2(-90,-27),head+Vector2(0,-27),Color(0.37,0.66,0.86),13,true)
    draw_line(head+Vector2(-90,-27),head+Vector2(-90,-58),Color(0.37,0.66,0.86),12,true)
    draw_arc(head,66.0,PI,TAU,24,Color(0.71,0.92,1.0),10,true)
    draw_line(head+Vector2(-68,0),head+Vector2(68,0),Color(0.64,0.85,1.0),8,true)
    for i in range(29):
        var xx: float = (float(i)-14.0)*6.3
        var fall: float = fposmod(age*(310.0 + float(i%5)*17.0) + float(i*57),420.0)
        var sway: float = 7.0*sin(age*3.0+float(i)*1.4)
        var top: Vector2 = head+Vector2(xx+sway,13+fall)
        draw_line(top,top+Vector2(1.5,16),Color(0.43,0.88,1.0,0.53),2.5,true)
    # Soft foamy base around lower lobes.
    for i in range(19):
        var x: float = c.x-160.0+float(i)*17.0
        var y: float = c.y+133.0+7.0*sin(age*2.8+float(i))
        draw_circle(Vector2(x,y), 14.0+float(i%4)*3.0, Color(0.79,0.96,1.0,0.52))
        draw_arc(Vector2(x-3,y-4),9,-2.4,-0.5,12,Color(1,1,1,0.6),1.6,true)
    # Localized washable dirt; color opacity responds to real sponge movement.
    for stain in stains:
        var a: float = float(stain["dirty"])
        if a <= 0.002: continue
        var p: Vector2 = stain["p"]
        var r: float = float(stain["radius"])
        draw_circle(p,r,Color(0.35,0.34,0.48,0.28*a))
        for k in range(5):
            var q: Vector2 = p+Vector2(sin(float(k)*2.4)*r*.65,cos(float(k)*2.6)*r*.5)
            draw_circle(q,4.0+float(k%3)*1.8,Color(0.41,0.32,0.43,0.38*a))
