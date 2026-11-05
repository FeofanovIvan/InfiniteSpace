extends Node2D
class_name MikaCosmoBall
## One animated sprite; solid-world bounce or floating air-world hover.
signal ready_to_fetch

@export var airborne: bool = false
var state: String = "waiting"
var from_point: Vector2 = Vector2.ZERO
var destination: Vector2 = Vector2.ZERO
var time: float = 0.0
var spin: float = 0.0
var _announced: bool = false
var sprite: Sprite2D

func _ready() -> void:
    sprite = Sprite2D.new()
    sprite.texture = preload("res://bubble/assets/interaction/cosmo_ball.png")
    sprite.scale = Vector2.ONE * 0.19
    add_child(sprite)
    queue_redraw()

func reset_at(point: Vector2, air_mode: bool) -> void:
    airborne = air_mode
    position = point
    state = "waiting"
    time = 0.0
    spin = 0.0
    _announced = false
    visible = true
    sprite.scale = Vector2.ONE * 0.19

func launch_to(point: Vector2) -> void:
    from_point = position
    destination = point
    state = "flight"
    time = 0.0
    _announced = false

func set_carried(point: Vector2) -> void:
    state = "carried"
    position = point
    sprite.scale = Vector2.ONE * 0.155

func _process(delta: float) -> void:
    var dt: float = minf(delta, 0.05)
    spin += dt
    sprite.rotation = spin * (3.4 if state in ["flight", "bounce"] else 1.4)
    match state:
        "flight":
            time += dt
            var t: float = minf(time / 0.92, 1.0)
            var arc: float = 4.0 * t * (1.0 - t)
            position = from_point.lerp(destination, t) + Vector2(25.0 * sin(t*TAU*2.0) * t, -180.0*arc)
            sprite.scale = Vector2.ONE * (0.19 + 0.014 * sin(t*PI))
            if t >= 1.0:
                time = 0.0
                state = "hover" if airborne else "bounce"
        "bounce":
            time += dt
            var decay: float = exp(-2.95 * time)
            var height: float = abs(sin(time * 10.2)) * 110.0 * decay
            position = destination + Vector2(sin(time*5.7)*10.0*decay, -height)
            if time > 1.55:
                position = destination
                state = "resting"
                _announce()
        "hover", "hover_ready":
            time += dt
            # No floor collision; small independent curves while suspended.
            position = destination + Vector2(17.0 * sin(time*1.5) + 4.0*sin(time*3.9), 14.0*sin(time*2.2))
            if time >= 0.7 and state == "hover":
                state = "hover_ready"
                _announce()
        "resting":
            sprite.rotation = lerp_angle(sprite.rotation, 0.0, 0.08)
        "carried":
            sprite.scale = Vector2.ONE * (0.15 + 0.003*sin(time*2.4))
            time += dt

func _announce() -> void:
    if _announced:
        return
    _announced = true
    ready_to_fetch.emit()
