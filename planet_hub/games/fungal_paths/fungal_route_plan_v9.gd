extends Control
## FUNGAL_V9_1_ROUTE_DOTS: Adjacent-junction planner with animated preview, red route, pulsing guided second dot.
## Only adjacent graph nodes may follow; render along real curved art edges.
signal next_node_selected(node_id: String)
signal previous_node_removed

var board
var route: Array[String] = []
var next_hint: String = ""
var enabled: bool = true
var failed: bool = false
var _pulse: float = 0.0
var _last_press_ms: int = -1000
var _last_press_location: Vector2 = Vector2(-1000, -1000)

func _ready() -> void:
    mouse_filter = Control.MOUSE_FILTER_STOP
    focus_mode = Control.FOCUS_NONE

func refresh() -> void:
    queue_redraw()

func _process(delta: float) -> void:
    # A live pulsing hint only during the tutorial's second point.
    if enabled and route.size() == 2 and next_hint != "":
        _pulse += delta
        queue_redraw()

func _gui_input(event: InputEvent) -> void:
    if not enabled or board == null or route.is_empty():
        return
    var touch: bool = event is InputEventScreenTouch and (event as InputEventScreenTouch).pressed
    var click: bool = event is InputEventMouseButton and (event as InputEventMouseButton).pressed and (event as InputEventMouseButton).button_index == MOUSE_BUTTON_LEFT
    if not touch and not click:
        return
    var where: Vector2 = (event as InputEventScreenTouch).position if touch else (event as InputEventMouseButton).position
    # Ignore a duplicated synthetic mouse event following an Android touch.
    var now: int = Time.get_ticks_msec()
    if now - _last_press_ms < 220 and where.distance_to(_last_press_location) < 9.0:
        accept_event()
        return
    _last_press_ms = now
    _last_press_location = where
    var endpoint: String = route[-1]
    var candidates: Array[String] = board.neighbors_for(endpoint)
    var back_node: String = route[-2] if route.size() > 2 else ""
    var target: String = ""
    var nearest: float = INF
    for node_id in candidates:
        if route.has(node_id) and node_id != back_node:
            continue
        var dist: float = where.distance_to(board.point_for(node_id))
        if dist < nearest:
            nearest = dist
            target = node_id
    var radius: float = clampf(board.map_rect.size.y * 0.039, 19.0, 37.0)
    if target != "" and nearest <= radius:
        if target == back_node:
            previous_node_removed.emit()
        else:
            next_node_selected.emit(target)
        accept_event()

func _draw() -> void:
    if board == null or route.is_empty() or board.map_rect.size.x <= 10.0:
        return
    var line_width: float = clampf(board.map_rect.size.y * 0.0042, 1.9, 4.0)
    var dot_radius: float = clampf(board.map_rect.size.y * 0.0125, 5.0, 10.5)
    var pulse: float = 0.5 + 0.5 * sin(_pulse * 4.9)
    # All real connections are red-orange and follow the precise atlas splines.
    for index in range(1, route.size()):
        var segment: PackedVector2Array = board.edge_points(route[index - 1], route[index])
        if segment.size() < 2:
            continue
        draw_polyline(segment, Color(0.43, 0.035, 0.025, 0.64), line_width * 3.0, true)
        draw_polyline(segment, Color(1.0, 0.27, 0.14, 0.98), line_width, true)
    # On the first planning step preview a semi-transparent animated line to
    # the second point. The preview is NOT confirmed until the child taps it.
    var preview: bool = enabled and route.size() == 2 and next_hint != ""
    if preview:
        var hinted_edge: PackedVector2Array = board.edge_points(route[-1], next_hint)
        if hinted_edge.size() > 1:
            # Draw the hint gradually from the first dot, then leave it pulsing
            # at full length until the child confirms the highlighted second dot.
            var reveal: float = clampf(_pulse / 1.10, 0.0, 1.0)
            var total: float = board.path_length(hinted_edge)
            var visible: PackedVector2Array = PackedVector2Array()
            var count: int = maxi(2, roundi(30.0 * reveal))
            for i in range(count + 1):
                visible.append(board.point_at(hinted_edge, total * reveal * float(i) / float(count)))
            draw_polyline(visible, Color(1.0, 0.27, 0.10, 0.17 + 0.27 * pulse), line_width * 2.8, true)
            draw_polyline(visible, Color(1.0, 0.72, 0.25, 0.22 + 0.50 * pulse), line_width * 0.94, true)
    # Route dots are installed only at junctions; do not duplicate the entry dot.
    for index in range(1, route.size()):
        var pos: Vector2 = board.point_for(route[index])
        var radius: float = dot_radius * (1.30 if index == 1 else 1.0)
        draw_circle(pos, radius + 4.0, Color(0.10, 0.015, 0.045, 0.90), true)
        draw_circle(pos, radius, Color(1.0, 0.26, 0.12, 1.0), true)
        draw_arc(pos, radius + 3.5, 0.0, TAU, 30, Color(1.0, 0.79, 0.35, 0.96), 1.9, true)
    # Only neighbors of the current endpoint are selectable; impossible to
    # jump across intermediate junctions or skip a necessary turn.
    var endpoint: String = route[-1]
    for candidate in board.neighbors_for(endpoint):
        if route.has(candidate):
            continue
        var p: Vector2 = board.point_for(candidate)
        var guided: bool = preview and candidate == next_hint
        var r: float = dot_radius * (1.7 + 0.33 * pulse if guided else 1.35)
        draw_circle(p, r, Color(0.09, 0.02, 0.09, 0.79), true)
        draw_circle(p, dot_radius * (0.84 + 0.27 * pulse if guided else 0.71), Color(1.0, 0.85, 0.30, 0.90 + 0.10 * pulse) if guided else Color(1.0, 0.73, 0.51, 0.82), true)
        if guided:
            draw_arc(p, r + 2.0, 0.0, TAU, 32, Color(1.0, 0.91, 0.33, 0.62 + 0.38 * pulse), 2.7, true)
    if failed:
        var lost_at: Vector2 = board.point_for(endpoint)
        draw_arc(lost_at, dot_radius * 2.6, 0.0, TAU, 30, Color(1.0, 0.39, 0.20, 0.96), 2.8, true)
