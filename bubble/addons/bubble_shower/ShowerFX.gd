extends Node2D
class_name MikaBubbleShowerFX
## Carefully registered overlay for the original 1672x941 Mika care room.
## Head underside ~ x359..420, y187-191; tray interior ~ x325..452, y377..402.
## Does not modify the artwork. Draw behind the character if one is added later.

signal shower_toggled(is_on: bool)

@export var shower_on: bool = false
@export_range(0.25, 2.0, 0.05) var water_intensity: float = 1.0
@export_range(0.25, 2.0, 0.05) var foam_intensity: float = 1.0
@export var allow_switch_click: bool = true

const SWITCH_RECT := Rect2(278.0, 228.0, 54.0, 61.0)
const STREAM_TOP := 190.0
const STREAM_BOTTOM := 380.0
const SHOWER_CENTER_X := 391.0
const FOAM_CENTER := Vector2(390.0, 391.0)

var _time: float = 0.0
var _water: float = 0.0
var _foam: float = 0.0

func _ready() -> void:
    _water = 1.0 if shower_on else 0.0
    _foam = 0.0
    set_process(shower_on)
    queue_redraw()

func set_shower_on(enabled: bool) -> void:
    if shower_on == enabled:
        return
    shower_on = enabled
    set_process(true)
    shower_toggled.emit(enabled)

func toggle_shower() -> void:
    set_shower_on(not shower_on)

func _process(delta: float) -> void:
    _time += delta
    _water = move_toward(_water, 1.0 if shower_on else 0.0, delta * 3.5)
    _foam = move_toward(_foam, 1.0 if shower_on else 0.0, delta * (0.55 if shower_on else 0.65))
    queue_redraw()
    if not shower_on and _water < 0.001 and _foam < 0.001:
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
            toggle_shower()
            get_viewport().set_input_as_handled()

func _unhandled_key_input(event: InputEvent) -> void:
    if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_SPACE:
        toggle_shower()
        get_viewport().set_input_as_handled()

func _draw() -> void:
    if _water > 0.001:
        _draw_curtain()
        _draw_splashes()
    if _foam > 0.001:
        _draw_foam()

func _draw_curtain() -> void:
    var strength: float = minf(1.5, _water * water_intensity)
    # Low-opacity, narrow body stays below the physical head and inside the cylinder.
    var area := PackedVector2Array([
        Vector2(361.0, 190.0), Vector2(418.0, 190.0),
        Vector2(428.0, 380.0), Vector2(351.0, 380.0)
    ])
    draw_colored_polygon(area, Color(0.25, 0.82, 1.0, 0.043 * strength))

    # 21 continuous thin streams. Shimmer travels DOWN them instead of blinking droplets.
    for i in range(21):
        var fi: float = float(i)
        var normalized: float = (fi - 10.0) / 10.0
        var x0: float = SHOWER_CENTER_X - 29.0 + fi * 2.9
        var points := PackedVector2Array()
        for j in range(18):
            var pct: float = float(j) / 17.0
            var yy: float = lerpf(STREAM_TOP, STREAM_BOTTOM, pct)
            var wobble: float = sin(_time * 4.9 + fi * 0.85 + pct * 12.0) * (0.16 + 0.76 * pct)
            var fan: float = normalized * pct * 5.0
            points.append(Vector2(x0 + wobble + fan, yy))
        var alpha: float = (0.11 + 0.045 * sin(fi * 2.4) * sin(fi * 2.4)) * strength
        draw_polyline(points, Color(0.31, 0.86, 1.0, alpha), 1.9, true)
        if i % 3 != 1:
            draw_polyline(points, Color(0.85, 1.0, 1.0, 0.15 * strength), 0.8, true)
        # Falling highlight perfectly co-registered with each stream.
        for k in range(2):
            var phase: float = fposmod(_time * (120.0 + fi * 1.2) + fi * 19.0 + float(k) * 95.0, STREAM_BOTTOM - STREAM_TOP + 28.0)
            var start_y: float = maxf(STREAM_TOP, STREAM_TOP + phase - 20.0)
            var end_y: float = minf(STREAM_BOTTOM, STREAM_TOP + phase)
            if end_y > start_y:
                var pct: float = (start_y - STREAM_TOP) / (STREAM_BOTTOM - STREAM_TOP)
                var highlight_x: float = x0 + normalized * pct * 5.0 + sin(_time * 4.9 + fi * 0.85 + pct * 12.0) * (0.16 + 0.76 * pct)
                draw_line(Vector2(highlight_x, start_y), Vector2(highlight_x + normalized * 0.5, end_y), Color(0.93, 1.0, 1.0, 0.27 * strength), 0.85, true)

func _draw_splashes() -> void:
    var strength: float = _water * water_intensity
    for i in range(16):
        var fi: float = float(i)
        var phase: float = fposmod(_time * 1.55 + fi * 0.31, 1.0)
        var dx: float = sin(fi * 2.4) * (6.0 + 32.0 * phase)
        var yy: float = 380.0 - sin(phase * PI) * 6.0 + cos(fi * 3.2)
        draw_circle(Vector2(SHOWER_CENTER_X + dx, yy), 0.6 + (1.0 - phase) * 1.15, Color(0.9, 1.0, 1.0, (1.0 - phase) * 0.28 * strength), true)
    for i in range(3):
        var p: float = fposmod(_time * 0.85 + float(i) / 3.0, 1.0)
        draw_arc(Vector2(SHOWER_CENTER_X, 383.0), 10.0 + p * 25.0, 0.11, PI - 0.11, 22, Color(0.83, 0.98, 1.0, (1.0 - p) * 0.22 * strength), 0.9, true)

func _draw_foam() -> void:
    var amount: float = minf(1.5, _foam * foam_intensity)
    var grow: float = 0.12 + 0.88 * _foam
    # Shallow pool of foam inside the tray only, with soft irregular edges.
    var outline := PackedVector2Array()
    for i in range(49):
        var a: float = TAU * float(i) / 48.0
        var rip: float = 1.0 + 0.07 * sin(a * 8.0 + _time * 0.9)
        outline.append(FOAM_CENTER + Vector2(cos(a) * 50.0 * grow * rip, sin(a) * 8.2 * grow * rip))
    draw_colored_polygon(outline, Color(0.65, 0.95, 1.0, 0.19 * amount))
    for i in range(45):
        var fi: float = float(i)
        var xx: float = FOAM_CENTER.x + (sin(fi * 19.3) * 0.65 + sin(fi * 8.9) * 0.35) * 45.0 * grow
        var yy: float = FOAM_CENTER.y + sin(fi * 12.7) * 5.0 * grow - absf(sin(_time * 0.6 + fi * 1.4)) * 1.2
        var r: float = (1.6 + float(i % 4) * 0.7) * grow
        draw_circle(Vector2(xx, yy), r, Color(0.91, 1.0, 1.0, 0.27 * amount), true)
        if i % 3 == 0:
            draw_arc(Vector2(xx, yy), r * 0.75, PI * 1.05, PI * 1.8, 10, Color(1.0, 1.0, 1.0, 0.35 * amount), 0.8, true)
