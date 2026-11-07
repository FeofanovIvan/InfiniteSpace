extends Node2D
## Individual animation layer, aligned in ORIGINAL PNG pixel coordinates.
# MIKA_BUBBLE_CONTINUOUS_SHOWER_V8_3_9
## Its parent scene gives it exactly the same position/scale as the sprite.
## It can be replaced without altering background or navigation/collision.

var station_kind: String = "shower"
## Per-station anchor supplied from sprite-local interaction_zones.json.
# MIKA_ROOM_V8_2_FEED_FLIGHT
var activity_anchor_local: Vector2 = Vector2.ZERO
var mouth_contact_local: Vector2 = Vector2.ZERO

func set_action_anchors(activity_point: Vector2, contact_point: Vector2) -> void:
    activity_anchor_local = activity_point
    mouth_contact_local = contact_point

var active := false
var _time := 0.0
var _strength := 0.0
var _fill := 0.0
var _dispense_time := 0.0
var _feed_phase: String = "empty"
var _feed_time: float = 0.0
const FILL_SECONDS := 1.15
const EAT_SECONDS := 3.75
const CLEAR_SECONDS := 0.72

func perform_action() -> void:
    if station_kind == "feeder":
        # One finite serving, then visibly consume the food and empty the bowl.
        _fill = 0.0
        _feed_time = 0.0
        _feed_phase = "filling"
        active = true
    else:
        active = not active
    set_process(true)
    queue_redraw()

func stop_action() -> void:
    active = false
    if station_kind == "feeder":
        _feed_phase = "empty"
        _feed_time = 0.0
        _fill = 0.0
    set_process(true)

func _process(delta: float) -> void:
    _time += delta
    if station_kind == "feeder" and _feed_phase != "empty":
        _feed_time += delta
        if _feed_phase == "filling":
            _fill = clampf(_feed_time/FILL_SECONDS,0.0,1.0)
            if _feed_time >= FILL_SECONDS:
                _feed_phase = "eating"
                _feed_time = 0.0
        elif _feed_phase == "eating":
            # Food disappears one portion at a time, not all at once.
            _fill = 1.0-clampf(_feed_time/EAT_SECONDS,0.0,1.0)
            if _feed_time >= EAT_SECONDS:
                _feed_phase = "clearing"
                _feed_time = 0.0
        elif _feed_phase == "clearing":
            _fill = 0.0
            if _feed_time >= CLEAR_SECONDS:
                _feed_phase = "empty"
                active = false
    var target: float = 1.0 if active else 0.0
    _strength = move_toward(_strength, target, delta * (2.7 if active else 1.3))
    queue_redraw()

func _draw() -> void:
    match station_kind:
        "shower": _draw_shower()
        "grooming": _draw_grooming()
        "feeder": _draw_feeder()
        "drinker": _draw_drinker()
        "bed": _draw_bed()
    if _strength > 0.04 and station_kind != "shower":
        var a: float = 0.11 * _strength * (0.8 + 0.2 * sin(_time * 4.0))
        draw_arc(activity_anchor_local, 10.0, 0.0, TAU, 25, Color(0.85, 1.0, 1.0, a), 1.0, true)

func _draw_shower() -> void:
    # No water with action off; nozzle physically at approx (309, 264)
    var f: float = _strength
    var ambient: float = 0.20 + 0.08 * sin(_time * 2.0)
    draw_arc(Vector2(310.0, 267.0), 38.0, 0.15, PI - 0.15, 22, Color(0.49, 0.93, 1.0, ambient), 2.0, true)
    if f < 0.005:
        return
    var spray_top: float = 282.0
    var spray_bottom: float = 729.0
    var h: float = spray_bottom - spray_top
    for i in range(27):
        var fi: float = float(i)
        var spread: float = (fi - 13.0) * 6.0
        var sx: float = 309.0 + spread
        var pts := PackedVector2Array()
        for j in range(19):
            var t: float = float(j) / 18.0
            var y: float = lerpf(spray_top, spray_bottom, t)
            var wave: float = sin(t * 14.0 + _time * 4.5 + fi * 0.6) * (0.4 + t * 1.3)
            pts.append(Vector2(sx + wave + spread * t * 0.13 + 16.0 * t, y))
        draw_polyline(pts, Color(0.35, 0.88, 1.0, (0.20 + 0.08 * sin(fi * 2.1)) * f), 2.1, true)
        if i % 2 == 0:
            draw_polyline(pts, Color(0.85, 1.0, 1.0, 0.14 * f), 0.9, true)
        # Bright streaks moving down the continuous water ribbons.
        var phase: float = fposmod(_time * (200.0 + fi * 5.0) + fi * 57.0, h + 24.0)
        var ya: float = maxf(spray_top, spray_top + phase - 20.0)
        var yb: float = minf(spray_bottom, ya + 30.0)
        if yb > ya:
            var shift_a: float = 16.0 * clampf((ya - spray_top) / h, 0.0, 1.0)
            var shift_b: float = 16.0 * clampf((yb - spray_top) / h, 0.0, 1.0)
            draw_line(Vector2(sx + shift_a, ya), Vector2(sx + spread * 0.10 + shift_b, yb), Color(0.88, 1.0, 1.0, 0.38 * f), 1.4, true)
    # Foam is painted ON the original Bubble by the wash mask, not on a second tray.

func _draw_grooming() -> void:
    # Idle mirror sheen, active cleansing/moving brush glow and foam particles.
    var phase: float = fposmod(_time * 54.0, 400.0)
    var x: float = 90.0 + phase
    draw_line(Vector2(x, 96.0), Vector2(x - 42.0, 280.0), Color(0.91, 1.0, 1.0, 0.09), 8.0, true)
    var f: float = _strength
    if f < 0.005:
        return
    for i in range(30):
        var fi: float = float(i)
        var cycle: float = fposmod(_time * (0.5 + fi * 0.017) + fi * 0.19, 1.0)
        var x2: float = 200.0 + sin(fi * 5.9 + _time * 1.1) * 130.0
        var y2: float = 360.0 - cycle * 185.0
        var r: float = 2.4 + fi * 0.085
        draw_arc(Vector2(x2, y2), r, 0.0, TAU, 16, Color(0.87, 1.0, 1.0, f * (1.0 - cycle) * 0.5), 1.5, true)
    var shake: float = sin(_time * 11.0) * 5.0
    draw_line(Vector2(235.0 + shake, 334.0), Vector2(255.0 + shake, 310.0), Color(0.98, 0.80, 1.0, f * 0.6), 4.0, true)

func _draw_feeder() -> void:
    # The texture keeps the ORIGINAL crisp pellets visible behind the clear tank.
    # The purple bowl starts empty and gets ONLY separate moving kibble spheres.
    # No blurred texture or solid brown film is drawn on the glass or bowl.
    # The serving is depleted during chewing and ends entirely empty.
    var amount: float = clampf(_fill, 0.0, 1.0)
    var led_alpha: float = 0.12 + 0.12 * sin(_time * 2.0)
    draw_arc(Vector2(215.0, 237.0), 13.0, 0.0, TAU, 20, Color(0.48, 1.0, 0.96, led_alpha), 2.0, true)
    if amount > 0.005:
        # Deterministic staggered pebble rows build a mound inside the bowl rim.
        # Do not draw any opaque brown polygon over the art; no muddy "film".
        # The rim in the original PNG runs approx y=291..311, center x=215.
        # Draw bottom rows first and rise as the portion is dispensed.
        var pellets_per_row: Array[int] = [17, 16, 15, 13, 11]
        var total_pellets: int = 0
        for row_count in pellets_per_row:
            total_pellets += row_count
        var shown: int = clampi(int(floorf(amount * float(total_pellets))), 0, total_pellets)
        var drawn: int = 0
        for row in range(pellets_per_row.size()):
            var count: int = pellets_per_row[row]
            var max_span: float = 129.0 - float(row) * 11.0
            var step_x: float = max_span / float(maxi(1, count - 1))
            for col in range(count):
                if drawn >= shown:
                    break
                var jitter_x: float = sin(float(drawn) * 3.91) * 1.4
                var jitter_y: float = cos(float(drawn) * 2.71) * 0.55
                var xx: float = 214.0 - max_span * 0.5 + float(col) * step_x + jitter_x
                var yy: float = 307.5 - float(row) * 3.45 + jitter_y
                _kibble(Vector2(xx, yy), 3.35 + float(drawn % 3) * 0.25, 0.99)
                drawn += 1
    if _feed_phase != "filling":
        return
    # Kibble falls only from the outlet INTO this feeder's bowl.
    for i in range(15):
        var fi2: float = float(i)
        var progress: float = fposmod(_time * (1.4 + fi2 * 0.06) + fi2 * 0.173, 1.0)
        var xx2: float = 214.0 + sin(fi2 * 3.27 + _time * 6.0) * 7.0
        var yy2: float = 269.0 + 29.0 * progress
        _kibble(Vector2(xx2, yy2), 2.2 + float(i % 3) * 0.6, _strength)

func _kibble(p: Vector2, radius: float, alpha: float) -> void:
    draw_circle(p + Vector2(0.5, 0.5), radius, Color(0.34, 0.17, 0.07, 0.9 * alpha), true)
    draw_circle(p, radius * 0.89, Color(0.60, 0.34, 0.15, alpha), true)
    draw_circle(p + Vector2(-0.6, -0.8), maxf(0.6, radius * 0.4), Color(0.84, 0.54, 0.26, alpha * 0.65), true)

func _draw_drinker() -> void:
    # A permanent fountain. Drinking affects Bubble, NOT the water supply.
    var flow: float = 1.0
    for i in range(9):
        var fi: float = float(i)
        var sx: float = 180.0 + (fi - 4.0) * 4.5
        var pts := PackedVector2Array()
        for j in range(15):
            var t: float = float(j) / 14.0
            var y: float = lerpf(126.0, 270.0, t)
            var dx: float = sin(t * 8.0 + _time * 3.6 + fi) * (0.5 + 1.3 * t)
            pts.append(Vector2(sx + dx, y))
        draw_polyline(pts, Color(0.61, 0.98, 1.0, (0.13 + 0.035 * sin(fi * 2.0)) * flow), 2.6, true)
        var h: float = fposmod(_time * (100.0 + fi * 4.0) + fi * 19.0, 144.0)
        draw_line(Vector2(sx, 126.0 + h), Vector2(sx + 1.0, minf(270.0, 126.0 + h + 15.0)), Color(0.90, 1.0, 1.0, 0.34 * flow), 1.2, true)
    for i in range(3):
        var f: float = fposmod(_time * 0.76 + float(i) / 3.0, 1.0)
        _ellipse_arc(Vector2(180.0, 277.0), 19.0 + f * 95.0, 5.0 + f * 18.0, Color(0.76, 1.0, 1.0, (1.0 - f) * 0.25 * flow), 1.3)

func _draw_bed() -> void:
    # The pod softly breathes; when selected it displays drifting sleepy glow.
    var glow: float = 0.16 + 0.07 * sin(_time * 2.2)
    draw_arc(Vector2(309.0, 213.0), 175.0, PI * 1.04, TAU - 0.1, 45, Color(1.0, 0.70, 0.98, glow), 4.0, true)
    var f: float = _strength
    if f < 0.005:
        return
    for i in range(14):
        var fi: float = float(i)
        var rise: float = fposmod(_time * 27.0 + fi * 22.0, 150.0)
        var x: float = 225.0 + sin(fi * 4.1 + _time) * 115.0
        var y: float = 305.0 - rise
        draw_circle(Vector2(x, y), 3.0 + float(i % 4), Color(1.0, 0.84, 1.0, (1.0 - rise / 150.0) * f * 0.26), true)
    # Sleep z's intentionally simple, not baked into the bed texture.
    for i in range(3):
        var y2: float = 110.0 - fposmod(_time * 18.0 + float(i) * 38.0, 90.0)
        var x2: float = 355.0 + float(i) * 15.0
        draw_line(Vector2(x2, y2), Vector2(x2 + 10.0, y2), Color(0.90, 0.85, 1.0, f * 0.65), 2.0, true)
        draw_line(Vector2(x2 + 10.0, y2), Vector2(x2, y2 + 9.0), Color(0.90, 0.85, 1.0, f * 0.65), 2.0, true)
        draw_line(Vector2(x2, y2 + 9.0), Vector2(x2 + 10.0, y2 + 9.0), Color(0.90, 0.85, 1.0, f * 0.65), 2.0, true)

func _ellipse_arc(center: Vector2, rx: float, ry: float, color: Color, width: float) -> void:
    var points := PackedVector2Array()
    for i in range(37):
        var a: float = TAU * float(i) / 36.0
        points.append(center + Vector2(cos(a) * rx, sin(a) * ry))
    draw_polyline(points, color, width, true)
