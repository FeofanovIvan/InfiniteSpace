extends Control
## One undivided network. Point and future 1920x1080 art use the same map area.
var nodes: PackedVector2Array = PackedVector2Array()
var links: Array[Dictionary] = []
var entrances: Array[int] = []
var exits: Array[int] = []
var seed_value: int = 1
var visited_edges: Dictionary = {}

func _ready() -> void:
    mouse_filter = Control.MOUSE_FILTER_IGNORE
    resized.connect(queue_redraw)

func configure(data: Dictionary) -> void:
    nodes = data.get("nodes",PackedVector2Array())
    links.clear()
    for link in data.get("edges",[]):
        if link is Dictionary:
            links.append(link)
    entrances.clear()
    exits.clear()
    for i in data.get("entrances",[]):
        entrances.append(int(i))
    for i in data.get("exits",[]):
        exits.append(int(i))
    seed_value = int(data.get("seed",1))
    visited_edges.clear()
    queue_redraw()

func point_for(index: int) -> Vector2:
    if index < 0 or index >= nodes.size():
        return Vector2.ZERO
    return nodes[index] * size

func neighbors(index: int) -> Array[int]:
    var result: Array[int] = []
    for link in links:
        var a: int = int(link["a"])
        var b: int = int(link["b"])
        if a == index:
            result.append(b)
        elif b == index:
            result.append(a)
    return result

func link_index(a: int,b: int) -> int:
    for i in range(links.size()):
        var e: Dictionary = links[i]
        if (int(e["a"]) == a and int(e["b"]) == b) or (int(e["a"]) == b and int(e["b"]) == a):
            return i
    return -1

func edge_point(a: int,b: int,t: float) -> Vector2:
    var index: int = link_index(a,b)
    if index < 0:
        return point_for(a).lerp(point_for(b),clampf(t,0.0,1.0))
    var e: Dictionary = links[index]
    return _curve(e,t if int(e["a"]) == a else 1.0-t)

func _curve(e: Dictionary,t: float) -> Vector2:
    var a: Vector2 = point_for(int(e["a"]))
    var b: Vector2 = point_for(int(e["b"]))
    var delta: Vector2 = b-a
    var normal: Vector2 = Vector2(-delta.y,delta.x).normalized()
    var bend: float = float(e.get("bend",0.0))
    var grain: float = float(e.get("grain",0.0))
    return a.lerp(b,t)+normal*delta.length()*sin(PI*t)*(bend+0.013*sin(TAU*2.0*t+grain))

func _draw() -> void:
    var bounds := Rect2(Vector2.ZERO,size)
    draw_rect(bounds,Color("#061824"))
    if size.x < 5 or size.y < 5:
        return
    var rng := RandomNumberGenerator.new()
    rng.seed = seed_value+72341
    for i in range(100):
        var p := Vector2(rng.randf(),rng.randf())*size
        draw_circle(p,rng.randf_range(1.0,25.0)*size.y/500.0,Color(0.15,0.42,0.29,rng.randf_range(0.016,0.08)))
    # Decorative hyphae are visually distinct from the navigable cords.
    for i in range(230):
        var p := Vector2(rng.randf(),rng.randf())*size
        var angle: float = rng.randf_range(-PI,PI)
        var line_pts := PackedVector2Array([p])
        for k in range(4):
            angle += rng.randf_range(-0.55,0.55)
            p += Vector2.from_angle(angle)*rng.randf_range(5.0,17.0)*(size.y/500.0)
            line_pts.append(p)
        draw_polyline(line_pts,Color(0.39,0.75,0.59,0.09),0.75,true)
    var width: float = clampf(size.y*0.010,1.0,6.0)
    for e in links:
        var route := PackedVector2Array()
        for j in range(15):
            route.append(_curve(e,float(j)/14.0))
        var tip: bool = str(e.get("kind","normal")) == "tip"
        var w: float = width*(0.52 if tip else 1.0)
        draw_polyline(route,Color(0.12,0.75,0.59,0.10),w*7.0,true)
        draw_polyline(route,Color(0.30,0.82,0.63,0.32),w*3.0,true)
        draw_polyline(route,Color(0.67,0.95,0.75,0.83 if not tip else 0.57),w,true)
        draw_polyline(route,Color(0.95,1.0,0.90,0.68),maxf(0.6,w*0.22),true)
        if not tip:
            _filaments(e,width)
    # Small illuminated openings along the left and right boundary.
    for id in entrances:
        var p: Vector2 = point_for(id)
        draw_circle(p,width*2.2,Color(0.27,0.93,0.77,0.27))
        draw_circle(p,maxf(2.0,width*0.85),Color("#b2ffe0"))
    for id in exits:
        var p: Vector2 = point_for(id)
        draw_circle(p,width*2.2,Color(1.0,0.69,0.39,0.25))
        draw_circle(p,maxf(2.0,width*0.85),Color("#ffe8a3"))

func _filaments(e: Dictionary,width: float) -> void:
    var id: int = int(e["a"])*61+int(e["b"])*911+seed_value
    for k in range(3):
        var t: float = 0.17+float(k)*0.27
        var mid: Vector2 = _curve(e,t)
        var delta: Vector2 = _curve(e,minf(t+0.02,1.0))-mid
        var n: Vector2 = Vector2(-delta.y,delta.x).normalized()
        var signum: float = 1.0 if posmod(id+k,2)==0 else -1.0
        var reach: float = width*(2.0+float(posmod(id+k*3,6)))
        var tip: Vector2 = mid + (n+delta.normalized()*0.25)*signum*reach
        draw_line(mid,tip,Color(0.64,0.98,0.78,0.30),maxf(0.50,width*0.14),true)
