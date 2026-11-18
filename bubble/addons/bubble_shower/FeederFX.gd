extends Node2D
class_name MikaBubbleFeederFX
## A finite portion of kibble from the dispenser to the violet bowl.
## Physical chute ~ (834,325), bowl OPENING x802-870 y338-351.
## No pellets are drawn through the transparent upper reservoir.

signal feeding_started
signal feeding_finished

@export var autoplay_once: bool = true
@export_range(1.0, 12.0, 0.25) var fill_duration: float = 4.0
@export_range(0.3, 2.0, 0.05) var food_scale: float = 1.0
@export var allow_switch_click: bool = true

const SWITCH_RECT := Rect2(817.0, 296.0, 35.0, 29.0)
const DISPENSER_EXIT := Vector2(834.0, 327.0)
const BOWL_CENTER := Vector2(834.0, 345.0)
const BOWL_OPENING_RX := 30.0
const BOWL_OPENING_RY := 4.1

var _elapsed: float = 0.0
var _progress: float = 0.0
var _feeding: bool = false

func _ready() -> void:
    if autoplay_once:
        start_feeding()
    else:
        queue_redraw()

func start_feeding() -> void:
    # For this preview, each new feeding action starts with an empty bowl.
    # In gameplay, call only when food is needed.
    _elapsed = 0.0
    _progress = 0.0
    _feeding = true
    set_process(true)
    queue_redraw()
    feeding_started.emit()

func stop_feeding() -> void:
    _feeding = false
    set_process(false)
    queue_redraw()

func clear_bowl() -> void:
    _feeding = false
    _elapsed = 0.0
    _progress = 0.0
    set_process(false)
    queue_redraw()

func is_feeding() -> bool:
    return _feeding

func get_fill_level() -> float:
    return _progress

func _process(delta: float) -> void:
    if not _feeding:
        set_process(false)
        return
    _elapsed += delta
    var duration: float = maxf(0.1, fill_duration)
    _progress = clampf(_elapsed / duration, 0.0, 1.0)
    queue_redraw()
    if _progress >= 1.0:
        _feeding = false
        set_process(false)
        feeding_finished.emit()

func _unhandled_input(event: InputEvent) -> void:
    if not allow_switch_click:
        return
    var pos := Vector2.ZERO
    var hit := false
    if event is InputEventMouseButton:
        hit = event.pressed and event.button_index == MOUSE_BUTTON_LEFT
        pos = event.position
    elif event is InputEventScreenTouch:
        hit = event.pressed
        pos = event.position
    if hit:
        var local_pos: Vector2 = get_global_transform_with_canvas().affine_inverse() * pos
        if SWITCH_RECT.has_point(local_pos):
            start_feeding()
            get_viewport().set_input_as_handled()

func _unhandled_key_input(event: InputEvent) -> void:
    if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_F:
        start_feeding()
        get_viewport().set_input_as_handled()

func _draw() -> void:
    if _progress > 0.002:
        _draw_kibble_in_bowl()
    if _feeding and _progress < 0.99:
        _draw_falling_kibble()

func _draw_kibble_in_bowl() -> void:
    var amount: float = _progress
    # Only the dark INSIDE of the dish is covered: no overlap with purple front.
    var rx: float = lerpf(4.0, BOWL_OPENING_RX, amount)
    var ry: float = lerpf(0.9, BOWL_OPENING_RY, amount)
    var cy: float = lerpf(347.6, BOWL_CENTER.y - 1.1, amount)
    var points := PackedVector2Array()
    for i in range(49):
        var a: float = TAU * float(i) / 48.0
        points.append(Vector2(BOWL_CENTER.x + cos(a) * rx, cy + sin(a) * ry))
    draw_colored_polygon(points, Color(0.35, 0.20, 0.10, 0.95))

    # Stable, scattered round pellets that gradually appear as the fill level rises.
    for i in range(125):
        var fi: float = float(i)
        var rnd_x: float = fposmod(sin(fi * 12.9898 + 0.61) * 43758.5453, 1.0)
        var rnd_y: float = fposmod(sin(fi * 78.233 + 5.17) * 25837.167, 1.0)
        var theta: float = rnd_x * TAU
        var radius: float = sqrt(rnd_y) * 0.89
        var xx: float = BOWL_CENTER.x + cos(theta) * rx * radius
        var yy: float = cy + sin(theta) * ry * radius
        var size: float = (1.5 + float(i % 4) * 0.21) * food_scale
        # Strictly keep each ball inside visible ellipse; never on rim or front emblem.
        var safe_rx: float = maxf(0.2, rx - size)
        var safe_ry: float = maxf(0.2, ry - size * 0.80)
        if pow((xx - BOWL_CENTER.x) / safe_rx, 2.0) + pow((yy - cy) / safe_ry, 2.0) <= 1.0:
            _draw_pellet(Vector2(xx, yy), size, 0.87)

func _draw_falling_kibble() -> void:
    # Pellets emerge from the little black chute below the green knob.
    var flow_fade: float = minf(1.0, _elapsed * 5.0)
    var span: float = 11.5
    for i in range(11):
        var fi: float = float(i)
        var phase: float = fposmod(_elapsed * (2.5 + float(i % 3) * 0.24) + fi * 0.13, 1.0)
        var xx: float = DISPENSER_EXIT.x + sin(fi * 4.2 + _elapsed * 2.3) * 3.2
        var yy: float = DISPENSER_EXIT.y + phase * span
        var size: float = (1.45 + float(i % 3) * 0.26) * food_scale
        _draw_pellet(Vector2(xx, yy), size, flow_fade * 0.91)
    # Tiny bounce confined to the surface of the opening.
    for i in range(5):
        var fi: float = float(i)
        var p: float = fposmod(_elapsed * 1.8 + fi * 0.27, 1.0)
        var xx: float = BOWL_CENTER.x + sin(fi * 2.3) * 11.0 * p
        var yy: float = 342.6 - sin(p * PI) * 2.0
        _draw_pellet(Vector2(xx, yy), (1.2 - p * 0.35) * food_scale, (1.0 - p) * 0.65 * flow_fade)

func _draw_pellet(pos: Vector2, radius: float, alpha: float) -> void:
    var base := Color(0.61, 0.34, 0.13, alpha)
    var shadow := Color(0.32, 0.16, 0.07, alpha * 0.8)
    var light := Color(0.84, 0.51, 0.21, alpha * 0.68)
    draw_circle(pos + Vector2(0.28, 0.42), radius, shadow, true)
    draw_circle(pos, radius, base, true)
    draw_circle(pos + Vector2(-radius * 0.35, -radius * 0.35), maxf(radius * 0.34, 0.45), light, true)
