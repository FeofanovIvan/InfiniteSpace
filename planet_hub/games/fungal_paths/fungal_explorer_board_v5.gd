extends Control
## Interactive five-sided cell board. Tiles rotate; tunnel links stay fixed.
signal tile_rotated(id: int)
signal tile_selected(id: int)

const FIELD := Color("#091a27")
const PIPE := Color("#59ded0")
const OUTLINE := Color("#1b5360")
const CLOSED := Color("#52606a")
const PORTS: int = 5

var centers: Array[Vector2] = []
var links: Array[Dictionary] = []
var base_ports: Array[PackedInt32Array] = []
var rotations: PackedInt32Array = PackedInt32Array()
var traveled: Array[int] = []
var _tile_radius: float = 46.0
var selected_tile: int = 2

func _ready() -> void:
    mouse_filter = Control.MOUSE_FILTER_STOP
    resized.connect(_redraw_board)
    queue_redraw()

func _redraw_board() -> void:
    _tile_radius = clampf(minf(size.x*0.050,size.y*0.128),13.0,71.0)
    queue_redraw()

func configure(level: Dictionary) -> void:
    centers.clear()
    for p in level.get("centers",[]):
        centers.append(p)
    links = level.get("links",[]).duplicate(true)
    base_ports.clear()
    for p in level.get("ports",[]):
        base_ports.append(p)
    rotations = level.get("rotations",PackedInt32Array()).duplicate()
    traveled.clear()
    selected_tile = 2
    _redraw_board()

func point_for(id: int) -> Vector2:
    if id<0 or id>=centers.size():return Vector2.ZERO
    return Vector2(centers[id].x*size.x,centers[id].y*size.y)

func tile_radius() -> float:
    return _tile_radius

func _port_angle(port: int) -> float:
    return -PI*0.5+TAU*float(posmod(port,5))/5.0

func _port_point(tile: int, port: int) -> Vector2:
    return point_for(tile)+Vector2.RIGHT.rotated(_port_angle(port))*_tile_radius*0.807

func is_open(tile: int, port: int) -> bool:
    if tile<0 or tile>=base_ports.size():return false
    for raw in base_ports[tile]:
        if (int(raw)+int(rotations[tile]))%PORTS == port:
            return true
    return false

func active_neighbors(tile: int) -> Array[int]:
    var found: Array[int] = []
    for edge in links:
        var a:int=int(edge["a"])
        var b:int=int(edge["b"])
        if not (is_open(a,int(edge["pa"])) and is_open(b,int(edge["pb"]))):
            continue
        if a==tile:found.append(b)
        elif b==tile:found.append(a)
    return found

func connected_path(goal: int = 6) -> Array[int]:
    if centers.is_empty():return []
    var queue: Array[int] = [0]
    var previous: Dictionary = {0:-1}
    var index:int=0
    while index<queue.size():
        var current:int=queue[index]
        index+=1
        for neighbor in active_neighbors(current):
            if previous.has(neighbor):continue
            previous[neighbor]=current
            queue.append(neighbor)
    var target:int=goal if previous.has(goal) else queue[-1]
    var route: Array[int] = []
    while target>=0:
        route.push_front(target)
        target=int(previous[target])
    return route

func solved() -> bool:
    var route: Array[int] = connected_path()
    return route.size()>1 and route[-1]==6

func rotate_tile(tile:int, direction:int = 1) -> void:
    if tile<=0 or tile>=6:return
    rotations[tile]=posmod(int(rotations[tile])+direction,PORTS)
    traveled.clear()
    queue_redraw()
    tile_rotated.emit(tile)

func set_traveled(ids: Array[int]) -> void:
    traveled=ids.duplicate()
    queue_redraw()

func _gui_input(event: InputEvent) -> void:
    var click: bool = false
    var point: Vector2 = Vector2.ZERO
    if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
        click = true
        point = event.position
    elif event is InputEventScreenTouch and event.pressed:
        click = true
        point = event.position
    if not click: return
    for i in range(1,6):
        if point_for(i).distance_to(point) <= _tile_radius * 1.3:
            selected_tile = i
            queue_redraw()
            tile_selected.emit(i)
            accept_event()
            return

func set_selected(tile: int) -> void:
    if tile < 1 or tile > 5: return
    selected_tile = tile
    queue_redraw()
    tile_selected.emit(tile)

func is_edge_open(a: int,b: int) -> bool:
    for edge in links:
        var x: int = int(edge["a"])
        var y: int = int(edge["b"])
        if (x==a and y==b) or (x==b and y==a):
            return is_open(x,int(edge["pa"])) and is_open(y,int(edge["pb"]))
    return false

func path_from(start: int,finish: int) -> Array[int]:
    if start < 0 or start >= centers.size(): return []
    var queue: Array[int] = [start]
    var parents: Dictionary = {start:-1}
    var i: int = 0
    while i < queue.size():
        var at: int = queue[i]
        i += 1
        if at == finish: break
        for next in active_neighbors(at):
            if parents.has(next): continue
            parents[next] = at
            queue.append(next)
    if not parents.has(finish): return []
    var path: Array[int] = []
    var x: int = finish
    while x >= 0:
        path.push_front(x)
        x = int(parents[x])
    return path

func first_open_port(tile:int) -> int:
    if tile<0 or tile>=base_ports.size():return 0
    var p:PackedInt32Array=base_ports[tile]
    if p.is_empty():return 0
    return posmod(int(p[0])+int(rotations[tile]),5)

func internal_probe_point(tile:int,t:float) -> Vector2:
    # When every outer corridor is closed, the character still investigates
    # a small road entirely INSIDE its current pentagonal cell.
    var middle:Vector2=point_for(tile)
    var a:float=_port_angle(first_open_port(tile))
    var length:float=_tile_radius*0.52
    return middle+Vector2.RIGHT.rotated(a)*length*(0.10+0.90*absf(sin(t)))

func _draw() -> void:
    if size.x<100.0 or size.y<90.0:return
    draw_rect(Rect2(Vector2.ZERO,size),FIELD)
    # Minimal tissue strands are only decorative, never route edges.
    for i in range(33):
        var px:float=(float((i*173+43)%997)/997.0)*size.x
        var py:float=(float((i*251+77)%967)/967.0)*size.y
        draw_circle(Vector2(px,py),maxf(0.6,_tile_radius*0.032),Color(0.25,0.54,0.51,0.10))
    for edge in links:
        var a:int=int(edge["a"])
        var b:int=int(edge["b"])
        var pa:int=int(edge["pa"])
        var pb:int=int(edge["pb"])
        var p:Vector2=_port_point(a,pa)
        var q:Vector2=_port_point(b,pb)
        var active:bool=is_open(a,pa) and is_open(b,pb)
        draw_line(p,q,Color(0.12,0.24,0.31,0.88),_tile_radius*0.22+3.0,true)
        if active:
            draw_line(p,q,Color(0.20,0.72,0.67,0.45),_tile_radius*0.26+3.0,true)
            draw_line(p,q,PIPE,_tile_radius*0.13+1.0,true)
        else:
            draw_dashed_line(p,q,Color(0.34,0.49,0.50,0.60),maxf(1.5,_tile_radius*0.055),maxf(4.0,_tile_radius*0.15),true)
    for tile in range(centers.size()):
        _draw_tile(tile)
    for k in range(1,traveled.size()):
        draw_line(point_for(traveled[k-1]),point_for(traveled[k]),Color(0.72,0.98,1.0,0.68),_tile_radius*0.11,true)
    for id in [0,6]:
        var col:Color=Color("#79e39e") if id==0 else Color("#ffce72")
        draw_arc(point_for(id),_tile_radius*1.11,0,TAU,38,col,maxf(2.0,_tile_radius*0.070),true)

func _draw_tile(tile:int) -> void:
    var center:Vector2=point_for(tile)
    var corners:=PackedVector2Array()
    for i in range(5):
        var angle:float=-PI*0.5-PI/5.0+TAU*float(i)/5.0
        corners.append(center+Vector2.RIGHT.rotated(angle)*_tile_radius)
    var fill:Color=Color("#163443") if tile in [0,6] else Color("#193c43")
    if tile==selected_tile:
        fill=Color("#245b5c")
    draw_colored_polygon(corners,fill)
    for k in range(5):
        var border:Color=Color("#f7e487") if tile==selected_tile else OUTLINE
        var stroke:float=maxf(3.0,_tile_radius*0.115) if tile==selected_tile else maxf(1.5,_tile_radius*0.070)
        draw_line(corners[k],corners[(k+1)%5],border,stroke,true)
    for p in range(5):
        var target:Vector2=_port_point(tile,p)
        if is_open(tile,p):
            draw_line(center,target,Color(0.10,0.50,0.47,0.60),_tile_radius*0.28,true)
            draw_line(center,target,PIPE,_tile_radius*0.14,true)
            draw_circle(target,_tile_radius*0.065,Color("#b5ffff"))
        else:
            draw_circle(target,_tile_radius*0.045,CLOSED)
    draw_circle(center,_tile_radius*0.16,Color("#91daca"))
    if tile not in [0,6]:
        # Visible curved arrow: these pieces can be rotated by tapping.
        draw_arc(center,_tile_radius*0.34,PI*0.09,PI*1.40,13,Color(0.85,0.96,0.95,0.80),maxf(1.2,_tile_radius*0.045),true)
    elif tile==6:
        # Simple home: fully inside the goal cell.
        var home_fill:Color=Color("#ffd890")
        draw_rect(Rect2(center+Vector2(-_tile_radius*0.13,0.0),Vector2(_tile_radius*0.26,_tile_radius*0.23)),home_fill)
        var roof:=PackedVector2Array([center+Vector2(-_tile_radius*0.21,0.0),center+Vector2(0,-_tile_radius*0.22),center+Vector2(_tile_radius*0.21,0.0)])
        draw_colored_polygon(roof,home_fill)
