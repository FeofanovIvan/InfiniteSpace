extends Node2D
class_name MikaBubbleDrinkerFX
## Registered water highlights on the EXISTING pictured fountain.
## Icon is at y260-282; nozzle starts y290-294; basin is y337-347.
## Highlight MUST NOT originate from the upper water-drop icon.

signal drinker_toggled(is_on: bool)

@export var fountain_on: bool = true
@export_range(0.2, 2.0, 0.05) var flow_intensity: float = 1.0
@export_range(0.2, 2.0, 0.05) var ripple_intensity: float = 1.0
@export var allow_switch_click: bool = true

const SWITCH_RECT := Rect2(1043.0, 250.0, 46.0, 39.0)
const CENTER_X := 1067.0
const STREAM_TOP := 292.0
const STREAM_BOTTOM := 338.0
const WATER_SURFACE := Vector2(1067.0, 341.0)

var _time: float = 0.0
var _flow: float = 0.0
var _ripples: float = 0.0

func _ready() -> void:
    _flow = 1.0 if fountain_on else 0.0
    _ripples = _flow
    set_process(fountain_on)
    queue_redraw()

func set_fountain_on(enabled: bool) -> void:
    if fountain_on == enabled:
        return
    fountain_on = enabled
    set_process(true)
    drinker_toggled.emit(enabled)

func toggle_fountain() -> void:
    set_fountain_on(not fountain_on)

func _process(delta: float) -> void:
    _time += delta
    _flow = move_toward(_flow, 1.0 if fountain_on else 0.0, delta * 4.0)
    _ripples = move_toward(_ripples, 1.0 if fountain_on else 0.0, delta * 1.8)
    queue_redraw()
    if not fountain_on and _flow < 0.001 and _ripples < 0.001:
        set_process(false)

func _unhandled_input(event: InputEvent) -> void:
    if not allow_switch_click:
        return
    var screen_pos := Vector2.ZERO
    var hit := false
    if event is InputEventMouseButton:
        hit = event.pressed and event.button_index == MOUSE_BUTTON_LEFT
        screen_pos = event.position
    elif event is InputEventScreenTouch:
        hit = event.pressed
        screen_pos = event.position
    if hit:
        var local_pos: Vector2 = get_global_transform_with_canvas().affine_inverse() * screen_pos
        if SWITCH_RECT.has_point(local_pos):
            toggle_fountain()
            get_viewport().set_input_as_handled()

func _unhandled_key_input(event: InputEvent) -> void:
    if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_D:
        toggle_fountain()
        get_viewport().set_input_as_handled()

func _draw() -> void:
    if _flow > 0.001:
        _draw_water()
    if _ripples > 0.001:
        _draw_ripples()

func _draw_water() -> void:
    var strength: float = _flow * flow_intensity
    # Very subtle transparent water inside the center channel.
    var body := PackedVector2Array([
        Vector2(1062.0, STREAM_TOP), Vector2(1072.0, STREAM_TOP),
        Vector2(1075.0, STREAM_BOTTOM), Vector2(1059.0, STREAM_BOTTOM)
    ])
    draw_colored_polygon(body, Color(0.43, 0.95, 1.0, 0.04 * strength))
    for i in range(6):
        var fi: float = float(i)
        var x0: float = 1062.5 + fi * 1.8
        var pts := PackedVector2Array()
        for j in range(12):
            var pct: float = float(j) / 11.0
            var yy: float = lerpf(STREAM_TOP, STREAM_BOTTOM, pct)
            var drift: float = sin(_time * 5.4 + fi * 1.9 + pct * 6.0) * (0.12 + 0.4 * pct)
            pts.append(Vector2(x0 + drift, yy))
        draw_polyline(pts, Color(0.9, 1.0, 1.0, (0.11 + 0.03 * sin(fi * 2.3)) * strength), 1.15, true)
        var phase: float = fposmod(_time * (65.0 + fi * 1.2) + fi * 16.0, STREAM_BOTTOM - STREAM_TOP + 14.0)
        var y1: float = maxf(STREAM_TOP, STREAM_TOP + phase - 13.0)
        var y2: float = minf(STREAM_BOTTOM, STREAM_TOP + phase)
        if y2 > y1:
            draw_line(Vector2(x0, y1), Vector2(x0, y2), Color(0.96, 1.0, 1.0, 0.3 * strength), 0.8, true)

func _draw_ripples() -> void:
    var strength: float = _ripples * ripple_intensity
    # Concentric highlights stay on the upper water surface, not on the casing.
    for i in range(3):
        var phase: float = fposmod(_time * 0.6 + float(i) / 3.0, 1.0)
        var rx: float = 5.0 + phase * 25.0
        var ry: float = 1.3 + phase * 3.3
        var center := WATER_SURFACE + Vector2(0.0, 1.0)
        var pts := PackedVector2Array()
        for j in range(37):
            var angle: float = TAU * float(j) / 36.0
            pts.append(center + Vector2(cos(angle) * rx, sin(angle) * ry))
        draw_polyline(pts, Color(0.85, 1.0, 1.0, 0.18 * (1.0 - phase) * strength), 0.8, true)
    for i in range(7):
        var fi: float = float(i)
        var xx: float = WATER_SURFACE.x + sin(fi * 5.41) * 24.0
        var yy: float = WATER_SURFACE.y + sin(_time * 1.9 + fi * 2.1) * 2.5
        draw_circle(Vector2(xx, yy), 0.65, Color(0.95, 1.0, 1.0, (0.08 + 0.06 * sin(_time * 3.2 + fi)) * strength), true)
