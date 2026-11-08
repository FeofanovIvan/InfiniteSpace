extends Control
## Clear six-pentagon maze; touch only highlighted adjacent nodes to build route.
signal node_selected(id: int)

var nodes: PackedVector2Array = PackedVector2Array()
var edges: Array[Dictionary] = []
var cells: Array[PackedInt32Array] = []
var entrances: Array[int] = []
var exits: Array[int] = []
var start: int = -1
var goal: int = -1
var route: Array[int] = []
var next_options: Array[int] = []
var seed_value: int = 1

func _ready() -> void:
    mouse_filter = Control.MOUSE_FILTER_STOP
    resized.connect(queue_redraw)

func configure(data: Dictionary) -> void:
    nodes = data.get("nodes",PackedVector2Array())
    edges.clear()
    for item in data.get("edges",[]):
        if item is Dictionary:
            edges.append(item)
    cells.clear()
    for ring in data.get("cells",[]):
        cells.append(ring)
    entrances.clear()
    exits.clear()
    for id in data.get("entrances",[]):entrances.append(int(id))
    for id in data.get("exits",[]):exits.append(int(id))
    start = int(data.get("start",0))
    goal = int(data.get("goal",0))
    seed_value = int(data.get("seed",1))
    route = [start]
    _update_options()
    queue_redraw()

func set_route(values: Array[int]) -> void:
    route = values.duplicate()
    _update_options()
    queue_redraw()

func _update_options() -> void:
    next_options.clear()
    if route.is_empty() or route[-1] == goal:
        return
    for neighbor in neighbors(route[-1]):
        if not route.has(neighbor):
            next_options.append(neighbor)

func neighbors(index: int) -> Array[int]:
    var result: Array[int] = []
    for link in edges:
        var a: int = int(link["a"])
        var b: int = int(link["b"])
        if a == index:
            result.append(b)
        elif b == index:
            result.append(a)
    return result

func point_for(index: int) -> Vector2:
    if index < 0 or index >= nodes.size():
        return Vector2.ZERO
    return nodes[index] * size

func _gui_input(event: InputEvent) -> void:
    var p: Vector2 = Vector2.ZERO
    if event is InputEventMouseButton:
        if event.button_index != MOUSE_BUTTON_LEFT or not event.pressed:
            return
        p = event.position
    elif event is InputEventScreenTouch:
        if not event.pressed:
            return
        p = event.position
    else:
        return
    var pick_id: int = -1
    var pick_dist: float = clampf(size.y*0.068,19.0,42.0)
    for id in range(nodes.size()):
        if not next_options.has(id) and not route.has(id):
            continue
        var dist: float = p.distance_to(point_for(id))
        if dist < pick_dist:
            pick_dist = dist
            pick_id = id
    if pick_id >= 0:
        node_selected.emit(pick_id)
        accept_event()

func _draw() -> void:
    if size.x < 30.0 or size.y < 30.0:
        return
    draw_rect(Rect2(Vector2.ZERO,size),Color("#07182d"))
    var rng: RandomNumberGenerator = RandomNumberGenerator.new()
    rng.seed = seed_value
    for i in range(62):
        var p: Vector2 = Vector2(rng.randf(),rng.randf())*size
        draw_circle(p,rng.randf_range(1.0,2.7),Color(0.43,0.78,0.85,0.15))
    # Cell structure remains distinct from corridors and the selected route.
    for ci in range(cells.size()):
        var ring: PackedInt32Array = cells[ci]
        var polygon: PackedVector2Array = PackedVector2Array()
        for id in ring:
            polygon.append(point_for(id))
        draw_colored_polygon(polygon,Color(0.15,0.39,0.45,0.22))
        polygon.append(polygon[0])
        draw_polyline(polygon,Color(0.48,0.74,0.67,0.20),maxf(2.0,size.y*0.014),true)
    var w: float = clampf(size.y*0.014,2.5,8.0)
    for item in edges:
        var a: Vector2 = point_for(int(item["a"]))
        var b: Vector2 = point_for(int(item["b"]))
        var tip: bool = str(item.get("kind","")) == "tip"
        draw_line(a,b,Color(0.06,0.28,0.35,0.80),w*3.0,true)
        draw_line(a,b,Color(0.55,0.77,0.70,0.28 if tip else 0.68),w*(0.68 if tip else 1.0),true)
    # Build mode: every selected edge becomes a broad blue line.
    for i in range(route.size()-1):
        var a: Vector2 = point_for(route[i])
        var b: Vector2 = point_for(route[i+1])
        draw_line(a,b,Color(0.03,0.56,1.0,0.31),w*3.4,true)
        draw_line(a,b,Color("#31c7ff"),w*1.5,true)
    var radius: float = clampf(size.y*0.017,4.0,12.0)
    for id in range(nodes.size()):
        var p: Vector2 = point_for(id)
        if next_options.has(id):
            draw_circle(p,radius*2.0,Color(0.22,0.96,0.77,0.19))
            draw_circle(p,radius*1.16,Color("#80ffd5"))
        elif route.has(id):
            draw_circle(p,radius*1.05,Color("#c5f7ff"))
        elif str(_edge_kind_for_node(id)) == "tip":
            draw_circle(p,radius*0.52,Color(0.69,0.84,0.81,0.53))
        else:
            draw_circle(p,radius*0.70,Color(0.57,0.78,0.75,0.77))
    for id in entrances:
        var p: Vector2 = point_for(id)
        draw_circle(p,radius*1.45,Color(0.25,0.91,0.53,0.25))
        draw_arc(p,radius*1.1,0,TAU,26,Color("#48d99b") if id == start else Color("#39705f"),2.6,true)
    for id in exits:
        var p: Vector2 = point_for(id)
        draw_circle(p,radius*1.65,Color(1.0,0.72,0.23,0.31 if id == goal else 0.09))
        draw_arc(p,radius*1.2,0,TAU,26,Color("#ffdb72") if id == goal else Color("#76684c"),3.2,true)
    if route.size()>0:
        var current: Vector2 = point_for(route[-1])
        draw_arc(current,radius*1.72,0,TAU,30,Color("#bdf3ff"),3.0,true)
    draw_arc(point_for(start),radius*2.05,0,TAU,30,Color("#55ed91"),3.5,true)
    draw_arc(point_for(goal),radius*2.12,0,TAU,30,Color("#ffe27a"),3.8,true)

func _edge_kind_for_node(id: int) -> String:
    for edge in edges:
        if int(edge["a"]) == id or int(edge["b"]) == id:
            if str(edge.get("kind","")) == "tip":
                return "tip"
    return "normal"
