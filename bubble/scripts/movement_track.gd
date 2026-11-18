extends Node2D
## Screen-space track decorations and character shadow.
var lane_left: float = 500.0
var lane_right: float = 1300.0
var floor_y: float = 640.0
var bubble_x: float = 500.0
var bubble_scale: float = 0.72
var progress: float = 0.0
var current_action: String = "walk_forward"

func refresh(left_edge: float, right_edge: float, y: float, x: float, s: float, p: float, action: String) -> void:
    lane_left = left_edge
    lane_right = right_edge
    floor_y = y
    bubble_x = x
    bubble_scale = s
    progress = p
    current_action = action
    queue_redraw()

func _draw() -> void:
    var baseline: float = floor_y + 42.0
    var tint := Color(0.38, 0.74, 0.97, 0.4)
    var steps: int = 26
    for i in range(steps):
        var t: float = float(i) / float(steps)
        var x0: float = lerpf(lane_left, lane_right, t)
        draw_line(Vector2(x0, baseline), Vector2(x0 + 12.0, baseline), tint, 2.0)
    draw_circle(Vector2(lane_left, baseline), 8.0, Color(0.33, 0.79, 0.90, 0.73))
    draw_circle(Vector2(lane_right, baseline), 8.0, Color(0.78, 0.61, 0.99, 0.73))
    # Four-layer soft shadow follows Bubble's actual position on screen.
    for i in range(10):
        var k: float = 1.0 - float(i) / 10.0
        _draw_ellipse(Vector2(bubble_x, floor_y + 2.0), 155.0 * bubble_scale * k, 27.0 * bubble_scale * k, Color(0.32, 0.83, 0.96, 0.025))
    _draw_ellipse(Vector2(bubble_x, floor_y + 2.0), 88.0 * bubble_scale, 10.0 * bubble_scale, Color(0.48, 0.93, 1.0, 0.06))
    var direction: float = -1.0 if current_action == "walk_backward" or current_action == "strafe_left" else 1.0
    var tip: Vector2 = Vector2(bubble_x + direction * (122.0 * bubble_scale), baseline)
    var orig: Vector2 = tip - Vector2(direction * 35.0, 0.0)
    draw_line(orig, tip, Color(0.57, 0.91, 0.99, 0.65), 3.0, true)
    draw_colored_polygon(PackedVector2Array([tip, tip - Vector2(direction * 11.0, -6.0), tip - Vector2(direction * 11.0, 6.0)]), Color(0.57, 0.91, 0.99, 0.65))

func _draw_ellipse(mid: Vector2, rx: float, ry: float, c: Color) -> void:
    var pts := PackedVector2Array()
    for i in range(40):
        var ang: float = TAU * float(i) / 40.0
        pts.append(mid + Vector2(cos(ang) * rx, sin(ang) * ry))
    draw_colored_polygon(pts, c)
