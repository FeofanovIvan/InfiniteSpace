extends "res://learning/src/features/tilt_maze/programmatic_maze_board.gd"
## MIKA Roll the Ball v2 — a gigantic, friendly magnetic-space playground.
## RENDERING ONLY. Ring layout, gaps, collision/hits_wall and generation are inherited.

const INK := Color("#090d2b")
const INDIGO := Color("#25235b")
const VIOLET := Color("#6354c9")
const AQUA := Color("#65edff")
const PINK := Color("#ff8fe9")
const HONEY := Color("#ffd77b")

var _cosmic_time: float = 0.0
var _paint_clock: float = 0.0


func _ready() -> void:
    super._ready()
    set_process(true)


func _process(delta: float) -> void:
    _cosmic_time += delta
    _paint_clock += delta
    if _paint_clock >= 0.055:
        _paint_clock = 0.0
        queue_redraw()


func _draw() -> void:
    _paint_planetarium()
    _paint_light_paths()
    _paint_outer_safety_ring()
    for i in range(rings.size()):
        var ring: Array = rings[i]
        var r: float = float(ring[0])
        var gap: float = float(ring[1])
        var opening: float = float(ring[2])
        _paint_rail_arc(r, gap + opening * 0.5, gap + TAU - opening * 0.5, i)
    for i in range(radial_walls.size()):
        var segment: Array = radial_walls[i]
        var a: float = float(segment[0])
        var inner_r: float = float(segment[1])
        var outer_r: float = float(segment[2])
        var axis: Vector2 = Vector2(cos(a), sin(a))
        _paint_bridge(CENTER + axis * inner_r, CENTER + axis * outer_r, i)
    _paint_core()
    _paint_wonder_sparks()


func _paint_planetarium() -> void:
    # Large toy-planet chassis with a lavender halo and indigo ocean.
    draw_circle(CENTER + Vector2(0, 10), 491.0, Color(0.12, 0.03, 0.32, 0.37))
    draw_circle(CENTER, 486.0, Color("#5b46b5"))
    draw_circle(CENTER, 480.0, Color("#a185ec"))
    draw_circle(CENTER, 474.0, Color("#22244e"))
    for i in range(27):
        var f: float = float(i) / 26.0
        var radius: float = 471.0 - float(i) * 12.0
        var tone: Color = Color("#132650").lerp(Color("#35336c"), 0.5 * (1.0 - f))
        draw_circle(CENTER, radius, tone)
    draw_circle(CENTER + Vector2(-166, -183), 184.0, Color(0.42, 0.55, 0.94, 0.035))
    draw_circle(CENTER + Vector2(201, 210), 154.0, Color(0.81, 0.35, 0.88, 0.035))
    for i in range(80):
        var a: float = float(i) * 2.3999632
        var radial: float = sqrt(float((i * 37 + 29) % 103) / 103.0) * 444.0
        var p: Vector2 = CENTER + Vector2(cos(a), sin(a)) * radial
        var brightness: float = 0.23 + 0.12 * sin(_cosmic_time * 1.3 + float(i))
        draw_circle(p, 1.4 if i % 4 else 2.4, Color(0.74, 0.91, 1.0, brightness))
    # Wide magnetic guide fields; purely decorative, never obstacles.
    for i in range(5):
        var r: float = 431.0 - float(i) * 72.0
        draw_arc(CENTER, r, 0.0, TAU, 110, Color(0.43, 0.65, 1.0, 0.07), 1.7, true)


func _paint_light_paths() -> void:
    # The visible empty passages remain broad, dark and easy to follow.
    for i in range(5):
        var r: float = 422.0 - float(i) * 83.0
        if r < 84.0:
            continue
        var start: float = _cosmic_time * (0.08 if i % 2 == 0 else -0.055) + float(i)
        draw_arc(CENTER, r, start, start + 0.56, 26, Color(0.26, 0.83, 1.0, 0.13), 7.0, true)
        draw_arc(CENTER, r, start + PI, start + PI + 0.45, 25, Color(1.0, 0.55, 0.90, 0.09), 6.0, true)


func _paint_outer_safety_ring() -> void:
    # Respect the ORIGINAL physics: the outer wall is still at radius 472.
    _paint_rail_arc(OUTER_RADIUS,
        outer_gap_center + outer_gap_size * 0.5,
        outer_gap_center + TAU - outer_gap_size * 0.5, -1)
    for i in range(32):
        var a: float = TAU * float(i) / 32.0
        var p: Vector2 = CENTER + Vector2(cos(a), sin(a)) * 483.0
        draw_circle(p, 2.3, HONEY if i % 4 == 0 else Color(0.73, 0.76, 1.0, 0.72))


func _paint_rail_arc(r: float, angle_start: float, angle_end: float, rail_index: int) -> void:
    var points := PackedVector2Array()
    var shadows := PackedVector2Array()
    var bevels := PackedVector2Array()
    var count: int = maxi(24, int((angle_end - angle_start) * r / 9.0))
    for i in range(count + 1):
        var a: float = lerpf(angle_start, angle_end, float(i) / float(count))
        var p: Vector2 = CENTER + Vector2(cos(a), sin(a)) * r
        points.append(p)
        shadows.append(p + Vector2(0, 6))
        bevels.append(p - Vector2(0, 6))
    var main: Color = AQUA if rail_index % 2 == 0 else PINK
    var highlight: Color = Color("#f2fcff") if rail_index % 2 == 0 else Color("#ffe8ff")
    # Six layers make these rails look like rounded, illuminated 3D toys.
    draw_polyline(shadows, Color(0.025, 0.02, 0.12, 0.58), WALL_WIDTH + 13.0, true)
    draw_polyline(points, Color(main.r, main.g, main.b, 0.19), WALL_WIDTH + 12.0, true)
    draw_polyline(points, Color("#20214f"), WALL_WIDTH + 6.0, true)
    draw_polyline(points, main.darkened(0.24), WALL_WIDTH + 0.0, true)
    draw_polyline(bevels, Color(highlight.r, highlight.g, highlight.b, 0.42), 7.0, true)
    draw_polyline(points, Color(1.0, 1.0, 1.0, 0.12), 3.0, true)
    _paint_cap(points[0], main)
    _paint_cap(points[points.size() - 1], main)
    if rail_index >= 0 and angle_end - angle_start > 0.6:
        var mid: float = (angle_start + angle_end) * 0.5
        var gem_pos: Vector2 = CENTER + Vector2(cos(mid), sin(mid)) * r
        _paint_rail_gem(gem_pos, main)


func _paint_bridge(a: Vector2, b: Vector2, bridge_index: int) -> void:
    var main: Color = PINK if bridge_index % 2 == 0 else AQUA
    draw_line(a + Vector2(0, 6), b + Vector2(0, 6), Color(0.04, 0.02, 0.13, 0.55), WALL_WIDTH + 13.0, true)
    draw_line(a, b, Color(main.r, main.g, main.b, 0.18), WALL_WIDTH + 12.0, true)
    draw_line(a, b, Color("#252653"), WALL_WIDTH + 6.0, true)
    draw_line(a, b, main.darkened(0.22), WALL_WIDTH, true)
    draw_line(a - Vector2(0, 6), b - Vector2(0, 6), Color(1, 1, 1, 0.42), 6.0, true)
    _paint_cap(a, main)
    _paint_cap(b, main)


func _paint_cap(p: Vector2, main: Color) -> void:
    draw_circle(p + Vector2(0, 6), 24.0, Color(0.03, 0.02, 0.12, 0.60))
    draw_circle(p, 21.0, Color("#20214a"))
    draw_circle(p, 18.0, main.darkened(0.18))
    draw_circle(p + Vector2(-4, -5), 8.0, Color(1.0, 1.0, 1.0, 0.38))


func _paint_rail_gem(p: Vector2, color: Color) -> void:
    var gem := PackedVector2Array([
        p + Vector2(0, -11), p + Vector2(9, 0),
        p + Vector2(0, 11), p + Vector2(-9, 0)
    ])
    draw_colored_polygon(gem, Color("#232449"))
    draw_circle(p, 6.0, color.lightened(0.35))
    draw_circle(p - Vector2(2.0, 2.0), 2.0, Color.WHITE)


func _paint_core() -> void:
    # Friendly magnetic star-port: the physical goal remains at the exact centre.
    var throb: float = 0.5 + 0.5 * sin(_cosmic_time * 2.9)
    draw_circle(CENTER, 96.0 + 4.0 * throb, Color(0.19, 0.89, 0.99, 0.12))
    draw_circle(CENTER, 84.0, Color("#1f2050"))
    draw_circle(CENTER, 77.0, Color("#8c6bf1"))
    draw_circle(CENTER, 71.0, Color("#382975"))
    draw_circle(CENTER, 65.0, Color("#63d9f4"))
    draw_circle(CENTER, 57.0, Color("#d0f6ff"))
    draw_circle(CENTER + Vector2(-8, -10), 43.0, Color("#fbe0a0"))
    var star := PackedVector2Array()
    for i in range(16):
        var a: float = float(i) * PI / 8.0 + _cosmic_time * 0.08 - PI * 0.5
        var radius: float = 38.0 if i % 2 == 0 else 19.0
        star.append(CENTER + Vector2(cos(a), sin(a)) * radius)
    draw_colored_polygon(star, Color("#ffbd65"))
    draw_circle(CENTER, 13.0, Color("#fff4d1"))
    for j in range(4):
        var a: float = _cosmic_time * 0.8 + float(j) * TAU / 4.0
        var p: Vector2 = CENTER + Vector2(cos(a), sin(a)) * 88.0
        draw_circle(p, 4.0 + throb, AQUA if j % 2 == 0 else PINK)


func _paint_wonder_sparks() -> void:
    # Sparse, twinkling highlights make the maze feel large and wondrous.
    for i in range(11):
        var a: float = float(i) * 2.36 + _cosmic_time * 0.015
        var rad: float = 140.0 + float((i * 47) % 280)
        var p: Vector2 = CENTER + Vector2(cos(a), sin(a)) * rad
        var tw: float = 0.35 + 0.65 * (0.5 + 0.5 * sin(_cosmic_time * 2.4 + float(i) * 1.75))
        var c: Color = AQUA if i % 2 == 0 else HONEY
        draw_circle(p, 1.8 + tw * 2.2, Color(c.r, c.g, c.b, 0.32 + 0.38 * tw))
